# TASD-Federation - Technical Architecture

Documento de referencia técnica de la arquitectura de federación DB2 para el laboratorio TASD.

## 📐 Visión General

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Docker Host (cualquier OS)                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                      Docker Network (bridge)                 │  │
│  │                        db2_network                           │  │
│  │  ┌──────────────────────────┐  ┌──────────────────────────┐ │  │
│  │  │   db2_federated          │  │   db2_remote             │ │  │
│  │  │   (Nodo Federador)       │  │   (Nodo Remoto)          │ │  │
│  │  ├──────────────────────────┤  ├──────────────────────────┤ │  │
│  │  │                          │  │                          │ │  │
│  │  │ BASETASD (Base Datos)   │  │ SAMPLE (Base Datos)      │ │  │
│  │  │ Puerto: 50000 (interno) │  │ Puerto: 50000 (interno)  │ │  │
│  │  │ Puerto: 50000 (externo) │  │ Puerto: 50001 (externo)  │ │  │
│  │  │                          │  │                          │ │  │
│  │  │ • Wrapper DRDA     ◄─────────◄ • COUNTRY               │ │  │
│  │  │ • Wrapper FLAT           │  │ • DEPARTMENT            │ │  │
│  │  │ • Nicknames:             │  │ • EMPLOYEE              │ │  │
│  │  │   - db2Ldept             │  │ • PROJECT               │ │  │
│  │  │   - db2Lemp              │  │ • (más tablas posibles) │ │  │
│  │  │   - db2Lproj             │  │                          │ │  │
│  │  │ • FILECLIENTES2          │  │                          │ │  │
│  │  │   (CSV externo)          │  │ Schema: DB2INST1         │ │  │
│  │  │                          │  │ Índices creados          │ │  │
│  │  │ Schema: (catálogo)       │  │                          │ │  │
│  │  │                          │  │ Volumen:                 │ │  │
│  │  │ Volúmen:                 │  │ db2_remote_data          │ │  │
│  │  │ db2_federated_data       │  │ /var/db2/db2inst1/      │ │  │
│  │  │ /var/db2/db2inst1/       │  │                          │ │  │
│  │  │                          │  │                          │ │  │
│  │  └──────────────────────────┘  └──────────────────────────┘ │  │
│  │                      ▲                    ▲                  │  │
│  │                      │ (DRDA Protocol)    │ (TCP/50000)      │  │
│  │                      └────────────────────┘                  │  │
│  │                                                              │  │
│  │  Mount Points (read-only):                                  │  │
│  │  • ./scripts:/scripts                                        │  │
│  │  • ./data:/var/db2/files                                    │  │
│  │                                                              │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                    ▲                           ▲                    │
│                    │        Puerto            │ Puerto              │
│                    │ 50000 (Federador)       │ 50001 (Remoto)      │
│                    │                           │                    │
│  ┌─────────────────┴───────────┬───────────────┴──────────────────┐ │
│  │     Acceso Externo                                             │ │
│  │     (Cliente JDBC/ODBC/CLI)                                    │ │
│  │                                                                 │ │
│  └─────────────────────────────────────────────────────────────────┘ │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## 🔌 Componentes

### 1. Servicios Docker

#### db2_federated (Nodo Federador)

```yaml
Imagen: ibmcom/db2:11.5.9.0-x86_64
Contenedor: db2_federated
BD: BASETASD
Puerto Externo: 50000
Puerto Interno: 50000
Network: db2_network
Tipo: Federador DRDA
```

**Componentes de DB2**:
- **Catálogo de Sistema**: Gestiona nicknames y servidores federados
- **Wrapper DRDA**: Comunica con otras instancias DB2
- **Wrapper FLAT**: Lee archivos de texto delimitado
- **Query Engine Federado**: Ejecuta consultas distribuidas
- **Optimization Service Center**: Valida eficiencia de consultas

#### db2_remote (Nodo Remoto)

```yaml
Imagen: ibmcom/db2:11.5.9.0-x86_64
Contenedor: db2_remote
BD: SAMPLE
Puerto Externo: 50001
Puerto Interno: 50000
Network: db2_network
Tipo: Servidor de Datos
```

**Componentes de DB2**:
- **Buffer Pools**: Pool por defecto (IBMDEFAULTBP)
- **Tablespaces**: USERSPACE1, SYSCATSPACE, TEMPSPACE1
- **Gestor de Transacciones**: Soporte para transacciones distribuidas
- **Lock Manager**: Manejo de bloqueos distribuidos

### 2. Wrappers (Adaptadores Federados)

#### DRDA Wrapper

Propósito: Comunicación entre bases de datos DB2

**Flujo de Inicialización**:
```sql
1. CREATE WRAPPER DRDA
   └─> Registra el wrapper en el catálogo
       └─> Vincula funciones DRDA del sistema
           └─> Carga librerías de protocolo DRDA

2. CREATE SERVER DB2SERVERLOCAL
   └─> Configura parámetros de conexión
       ├─ DBNAME: 'SAMPLE'
       ├─ HOSTNAME: 'db2_remote' (resolución en docker network)
       ├─ PORT: '50000' (puerto interno del contenedor)
       ├─ PARAMETER: '1' (versión de protocolo)
       └─ TIMEOUT: '30' (segundos)

3. CREATE USER MAPPING
   └─> Mapea usuario local a credenciales remotas
       ├─ REMOTE_AUTHID: 'db2inst1'
       └─ REMOTE_PASSWORD: 'db2inst1'
```

**DRDA Protocol**:
- **DDM (Distributed Data Management)**: Protocolo de comunicación
- **Transport**: TCP/IP a puerto 50000 del contenedor remoto
- **Seguridad**: Usuario/contraseña en USER MAPPING
- **Codificación**: EBCDIC/ASCII conversion automático

#### FLAT Wrapper

Propósito: Acceso a archivos de texto delimitado (CSV)

**Configuración**:
```
Archivo: /var/db2/files/file_clientes2.txt
Record Separator: 0x0A (salto de línea)
Field Separator: , (coma)
Quote Character: " (comillas)
Encoding: UTF-8 (por defecto)
```

**Mapeo de Campos**:
```
CSV Columns:
  CLIENTEID, NOMBRE, APELLIDO, EMAIL, TELEFONO,
  CIUDAD, PROVINCIA, CODIGOPOSTAL, FECHAREGISTRO, ESTADO

Nickname FILECLIENTES2 columns:
  (Automáticamente inferidos del encabezado CSV)
```

### 3. Nicknames Federados

Definición: Alias que representan tablas remotas como si fueran locales

#### db2Ldept (DEPARTMENT)
```sql
Origen: DB2SERVERLOCAL.DB2INST1.DEPARTMENT
Tabla Local: db2Ldept
Esquema: Inferido de tabla remota
Usar en: SELECT * FROM db2Ldept
```

#### db2Lemp (EMPLOYEE)
```sql
Origen: DB2SERVERLOCAL.DB2INST1.EMPLOYEE
Tabla Local: db2Lemp
Esquema: Inferido de tabla remota
Usar en: SELECT * FROM db2Lemp
```

#### db2Lproj (PROJECT)
```sql
Origen: DB2SERVERLOCAL.DB2INST1.PROJECT
Tabla Local: db2Lproj
Esquema: Inferido de tabla remota
Usar en: SELECT * FROM db2Lproj
```

#### FILECLIENTES2 (CSV File)
```sql
Origen: /var/db2/files/file_clientes2.txt
Tipo: Archivo delimitado
Formato: CSV con header
Usar en: SELECT * FROM FILECLIENTES2 WHERE ESTADO = 'Activo'
```

### 4. Volúmenes Docker

#### db2_federated_data

```
Tipo: Named Volume
Ruta Interna: /var/db2/db2inst1/
Propietario: db2inst1 (UID 999)
Permisos: 700 (rwx------)
Contenido:
  ├── sqllib/     (Binarios y librerías de DB2)
  ├── db2dump/    (Logs de diagnóstico)
  ├── datadms/    (Data Management Services)
  ├── instances/  (Definición de instancias)
  └── BASETASD/   (Datafiles de BASETASD)
      ├── USERSPACE1
      ├── SYSCATSPACE
      └── TEMPSPACE1
Persistencia: Retenido después de docker-compose down
```

#### db2_remote_data

```
Tipo: Named Volume
Ruta Interna: /var/db2/db2inst1/
Propietario: db2inst1 (UID 999)
Permisos: 700 (rwx------)
Contenido: 
  ├── sqllib/     (Binarios y librerías de DB2)
  ├── db2dump/    (Logs de diagnóstico)
  ├── instances/  (Definición de instancias)
  └── SAMPLE/     (Datafiles de SAMPLE)
      ├── USERSPACE1
      ├── SYSCATSPACE
      └── TEMPSPACE1
Persistencia: Retenido después de docker-compose down
```

#### Mount de Scripts y Data

```
./scripts → /scripts (read-only)
  ├── init_federation.sql
  └── init_sample_db.sql

./data → /var/db2/files (read-only)
  └── file_clientes2.txt
```

### 5. Network Docker

#### db2_network (bridge)

```
Tipo: User-defined bridge
Driver: bridge (tipo estándar)
Subnet: 172.19.0.0/16 (por defecto)
Gateway: 172.19.0.1

Resolución de DNS:
  • db2_federated → 172.19.0.2 (típicamente)
  • db2_remote → 172.19.0.3 (típicamente)
  
Comunicación:
  • db2_federated ← port 50000 → db2_remote
  • Mismo protocolo DRDA que conexión remota
  • Latencia: < 1ms (same host)
```

## 🔄 Flujo de Operaciones

### Inicialización (Startup)

```
1. docker-compose up -d
   ├─> Crear red db2_network
   ├─> Descargar imagen ibmcom/db2:11.5.9.0-x86_64 (si no existe)
   ├─> Crear contenedores
   ├─> Montar volúmenes
   ├─> Iniciar procesos DB2
   └─> Esperar healthcheck

2. ./setup.sh
   ├─> Esperar 30s (contenedores listos)
   │
   ├─> En db2_remote:
   │   ├─> CREATE SCHEMA DB2INST1
   │   ├─> CREATE TABLE DEPARTMENT
   │   ├─> CREATE TABLE EMPLOYEE
   │   ├─> CREATE TABLE PROJECT
   │   ├─> INSERT datos de prueba
   │   └─> CREATE INDEXES
   │
   └─> En db2_federated:
       ├─> UPDATE DB2 CFG FEDERATED YES
       ├─> CREATE WRAPPER DRDA
       ├─> CREATE SERVER DB2SERVERLOCAL
       ├─> CREATE USER MAPPING
       ├─> CREATE WRAPPER FLAT
       ├─> CREATE SERVER FLATSERVER
       ├─> CREATE NICKNAME db2Ldept
       ├─> CREATE NICKNAME db2Lemp
       ├─> CREATE NICKNAME db2Lproj
       └─> CREATE NICKNAME FILECLIENTES2
```

### Consulta Federada (Query Execution)

```
Usuario ejecuta:
  db2 "SELECT * FROM db2Lemp WHERE SALARY > 50000"

1. Query Parser (db2_federated)
   └─> Analiza sintaxis SQL y nicknames

2. Catalog Lookup
   └─> Busca LEMP en SYSCAT.NICKTAB
       └─> Encuentra: Remote name = DB2INST1.EMPLOYEE
           Server = DB2SERVERLOCAL

3. Query Optimizer
   ├─> Estima costo local vs. remoto
   ├─> Determina pushdown de predicados
   └─> Genera plan de ejecución

4. Execution
   ├─> En db2_federated: Preparar conexión remota
   │   └─> Buscar USER MAPPING para db2inst1
   │       └─> Obtener REMOTE_AUTHID y REMOTE_PASSWORD
   │
   ├─> Conectar a db2_remote via DRDA
   │   └─> Enviar autenticación cifrada
   │
   ├─> Enviar SQL al servidor remoto
   │   └─> "SELECT * FROM DB2INST1.EMPLOYEE WHERE SALARY > 50000"
   │
   ├─> db2_remote ejecuta localmente
   │   ├─> Valida permisos
   │   ├─> Busca índices aplicables
   │   ├─> Ejecuta plan de acceso
   │   └─> Retorna conjunto de resultados
   │
   └─> db2_federated recibe y retorna al cliente

5. Conclusión
   └─> Resultados mostrados en CLI del cliente
```

### Acceso a FLATWRAPPER

```
Usuario ejecuta:
  db2 "SELECT * FROM FILECLIENTES2 WHERE ESTADO = 'Activo'"

1. Query Parser
   └─> Reconoce FILECLIENTES2 como nickname FLAT

2. Catalog Lookup
   ├─> Busca en SYSCAT.NICKTAB
   ├─> Identifica: FLAT Wrapper, FLATSERVER
   └─> Config: /var/db2/files/file_clientes2.txt

3. FLAT Wrapper
   ├─> Abre archivo file_clientes2.txt
   ├─> Lee header (primera línea)
   │   └─> Mapea columnas CSV a atributos
   │
   ├─> Lee líneas de datos
   │   ├─> Separa por ','
   │   ├─> Aplica predicados (ESTADO = 'Activo')
   │   └─> Construye registros
   │
   └─> Retorna conjunto filtrado

4. Resultados
   └─> mostrados en CLI
   
Nota: FLATWRAPPER es read-only para CSV
```

## 🔐 Seguridad

### Autenticación

1. **Nivel Contenedor**
   - Usuario: db2inst1 (no root)
   - Privilegios: Mínimos necesarios
   - Container Capabilities: Restringidas

2. **Nivel DB2**
   - Usuario: db2inst1
   - Contraseña: db2inst1 (cambiar en producción)
   - Almacenamiento: Hasheado en catálogo

3. **Nivel Federación**
   - LOCAL USER → REMOTE_AUTHID (en USER MAPPING)
   - Comunicación DRDA cifrable
   - Validación de certificados opcional

### Volúmenes

- Montados como read-only para scripts y data
- db2_federated_data y db2_remote_data: read-write
- Propietario: db2inst1 (no público)
- Permisos: 700 (acceso solo db2inst1)

### Network Isolation

- Docker network bridge: aislado de host
- Acceso solo via puertos expuestos (50000, 50001)
- Internal communication: sin internet
- DNS resolution: local (docker network)

## 📊 Esquemas y Datos

### SAMPLE Database (db2_remote)

**Tablas sin federación**:

```sql
DEPARTMENT
├── DEPTNO (CHAR 3) - PK
├── DEPTNAME (VARCHAR 36)
├── MGRNO (CHAR 6)
└── ADMRDEPT (CHAR 3)

EMPLOYEE
├── EMPNO (CHAR 6) - PK
├── FIRSTNME (VARCHAR 12)
├── MIDINIT (CHAR 1)
├── LASTNAME (VARCHAR 15)
├── WORKDEPT (CHAR 3) - FK a DEPARTMENT
├── PHONENO (CHAR 4)
├── HIREDATE (DATE)
├── JOB (CHAR 8)
├── EDLEVEL (SMALLINT)
├── SEX (CHAR 1)
├── BIRTHDATE (DATE)
├── SALARY (DECIMAL 9,2)
├── BONUS (DECIMAL 9,2)
└── COMM (DECIMAL 9,2)

PROJECT
├── PROJNO (CHAR 6) - PK
├── PROJNAME (VARCHAR 24)
├── DEPTNO (CHAR 3) - FK a DEPARTMENT
├── RESPEMP (CHAR 6) - FK a EMPLOYEE
├── PRSTDATE (DATE)
├── PRENDATE (DATE)
└── MAJPROJ (CHAR 6) - FK recursiva
```

### Archivos CSV

**file_clientes2.txt** (formato delimitado):
```
CLIENTEID,NOMBRE,APELLIDO,EMAIL,TELEFONO,CIUDAD,PROVINCIA,CODIGOPOSTAL,FECHAREGISTRO,ESTADO
C001,"Juan","García","juan.garcia@email.com","+54-11-2345-6789","Buenos Aires","CABA","1428","2022-03-15","Activo"
...
```

## 📈 Performance

### Parámetros de Optimización

**Buffer Pool** (IBMDEFAULTBP):
- Tamaño: Automático (basado en memoria disponible)
- Páginas: 4KB por defecto
- Read-ahead: Habilitado para tablas grandes

**Índices**:
- idx_emp_dept: En WORKDEPT (acelera joins)
- idx_proj_dept: En DEPTNO (acelera aggregates)

**Query Optimization**:
- Predicate Pushdown: WHERE clauses se ejecutan remotamente
- Join Order: db2_federated optimiza joins federados
- Statistics: RUNSTATS actualiza estimaciones de costo

### Consideraciones de Red

- DRDA usa protocolo binario comprimido
- Latencia intra-network: < 1ms
- Throughput: Limited solo por CPU/Disk
- Connection Pooling: Habilitado automáticamente

## 🛠️ Administración

### Monitoreo

```
Comandos útiles para verificar estado:

db2 list database directory
  └─> Ver bases de datos catalogadas

db2 list active databases
  └─> Ver bases actualmente conectadas

db2 get database cfg
  └─> Ver configuración (incluye FEDERATED)

db2 get snapshot for applications on BASETASD
  └─> Ver conexiones activas

SELECT * FROM SYSCAT.SERVERS
  └─> Ver servidores federados

SELECT * FROM SYSCAT.NICKTAB
  └─> Ver nicknames definidos

SELECT * FROM SYSCAT.WRAPPERS
  └─> Ver wrappers disponibles
```

### Backup y Recovery

```
Backup:
  db2 backup db BASETASD to <device>
  
Restore:
  db2 restore db BASETASD from <device>

Rollforward:
  db2 rollforward db BASETASD to end of logs
```

### Limpieza

```
Logs:
  docker exec db2_federated rm -f \
    /var/db2inst1/sqllib/db2dump/*

Caché de conexiones:
  db2 reset connection
```

## 🔄 Ciclo de Vida

| Fase | Estado | Acción |
|------|--------|--------|
| Inicialización | Parado | docker-compose up -d |
| Startup | Iniciando | Esperar healthcheck (30-60s) |
| Operación | Activo | Aceptar conexiones SQL |
| Mantenimiento | Parado | docker-compose down |
| Recuperación | Parado | docker-compose down -v + up + setup |

## 📚 Referencias Técnicas

### IBM DB2 LUW v11.5

- **Parametrosstemas soportados**: Linux, Windows, macOS (via Docker)
- **Edición**: Community Edition (sin restricciones de usuarios)
- **Protocolo**: DRDA (DB2 Remote Data Access)

### Requisitos de Hardware

| Componente | Mínimo | Recomendado |
|------------|--------|-------------|
| CPU | 2 cores | 4+ cores |
| RAM | 2GB | 4GB+ |
| Disk | 10GB | 50GB+ |
| Network | 100Mbps | 1Gbps |

### Compatibilidad

- **Arquitecturas**: x86_64, ARM64 (v11.5.9.0+)
- **Contenedores**: Docker v20.10+, Compose v2.0+
- **Redes**: Bridge (recomendado), Host (alternativa)

---

**Última Actualización**: Abril 2026
**Versión de Documento**: 1.0.0
**DB2 Version**: 11.5.9.0
