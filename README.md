# TASD-Federation - Docker Microservices Architecture

Migración del laboratorio de base de datos de **UTN.BA - Tecnologías Aplicadas a Soluciones de Datos** desde una VM de Windows 7 con DB2 v10.5 a una arquitectura de microservicios con Docker.

## 🎯 Objetivos

- ✅ Eliminar dependencia de VMware
- ✅ Compatibilidad con arquitecturas ARM (Mac M1/M2/M3) y x86 (Windows/Linux)
- ✅ Configuración de federación DB2 entre nodos
- ✅ Integración de Non-Relational Wrappers (FLATWRAPPER)
- ✅ Entorno reproducible y escalable

## 📋 Requisitos Previos

### Software Requerido

- **Docker**: v20.10 o superior
- **Docker Compose**: v2.0 o superior
- **Docker Desktop** (para Mac/Windows)

### Instalación

#### macOS (M1/M2/M3 - ARM)
```bash
# Descargar Docker Desktop para Mac (Apple Silicon)
brew install docker
# O descargarlo desde https://www.docker.com/products/docker-desktop

# Verificar instalación
docker --version
docker-compose --version
```

#### Windows (x86)
```powershell
# Descargar Docker Desktop para Windows
# https://www.docker.com/products/docker-desktop

# Verificar instalación
docker --version
docker-compose --version
```

#### Linux (x86)
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install docker.io docker-compose-plugin

# Verificar instalación
docker --version
docker-compose --version
```

## 🏗️ Arquitectura General

```
┌─────────────────────────────────────────────────────────────┐
│                     Docker Network                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────────┐  ┌──────────────────────────┐ │
│  │   db2_federated (Nodo A) │  │   db2_remote (Nodo B)    │ │
│  ├──────────────────────────┤  ├──────────────────────────┤ │
│  │ DB2 v11.5                │  │ DB2 v11.5                │ │
│  │ Database: BASETASD       │  │ Database: SAMPLE         │ │
│  │ Puerto: 50000            │  │ Puerto: 50001 (ext)      │ │
│  │                          │  │        50000 (int)       │ │
│  │ • Wrapper DRDA   ◄──────────◄ • Tablas Públicas        │ │
│  │ • Wrapper FLAT           │  │ • DEPARTMENT             │ │
│  │ • Nicknames:             │  │ • EMPLOYEE               │ │
│  │   - db2Ldept             │  │ • PROJECT                │ │
│  │   - db2Lemp              │  │                          │ │
│  │   - db2Lproj             │  │                          │ │
│  │   - FILECLIENTES2        │  │ Volumen:                 │ │
│  │                          │  │ /var/db2/files/          │ │
│  │ Volúmenes:               │  │                          │ │
│  │ • db2_federated_data     │  │ • db2_remote_data        │ │
│  │ • ./scripts (mount RO)   │  │ • ./scripts (mount RO)   │ │
│  │ • ./data (mount RO)      │  │ • ./data (mount RO)      │ │
│  └──────────────────────────┘  └──────────────────────────┘ │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## 📁 Estructura de Directorios

```
TASD-Federation/
├── docker-compose.yml          # Configuración de contenedores
├── setup.sh                     # Script de inicialización automática
├── README.md                    # Este archivo
├── scripts/
│   ├── init_federation.sql      # Script de federación DB2
│   └── init_sample_db.sql       # Script de inicialización SAMPLE
└── data/
    └── file_clientes2.txt       # Archivo CSV para FLATWRAPPER
```

## 🚀 Inicio Rápido

### 1. Clonar el Repositorio

```bash
git clone https://github.com/tu-usuario/TASD-Federation.git
cd TASD-Federation
```

### 2. Iniciar los Contenedores

```bash
# Iniciar ambos contenedores en background
docker-compose up -d

# Verificar estado de los contenedores
docker-compose ps
```

### 3. Ejecutar el Script de Setup (Automático)

```bash
# Hacer el script ejecutable (en macOS/Linux)
chmod +x setup.sh

# En macOS/Linux
./setup.sh

# En Windows (PowerShell)
bash setup.sh
```

Este script:
- ✅ Espera a que los contenedores estén listos
- ✅ Inicializa la base de datos SAMPLE con tablas y datos
- ✅ Configura la federación en BASETASD
- ✅ Crea nicknames para consultas remotas
- ✅ Verifica la configuración

### 4. Verificar la Instalación

```bash
# Ver logs de ambos contenedores
docker-compose logs -f

# Acceder al contenedor federador
docker exec -it db2_federated bash

# Dentro del contenedor
su - db2inst1
db2 connect to BASETASD

# Listar nicknames creados
db2 "SELECT TABNAME, REMOTE_NAME FROM SYSCAT.NICKTAB"
```

## 📝 Configuración de Federación Detallada

### Nodo Federador (db2_federated - BASETASD)

**Puerto de Acceso Remoto**: `50000` (localhost:50000)

**Componentes Configurados**:

1. **Wrapper DRDA**: Comunicación SQL entre instancias DB2
2. **Server DB2SERVERLOCAL**: Apunta al contenedor remoto `db2_remote`
3. **User Mapping**: Autenticación de usuario `db2inst1` en servidor remoto
4. **Nicknames**:
   - `db2Ldept` → DEPARTMENT (tabla remota)
   - `db2Lemp` → EMPLOYEE (tabla remota)
   - `db2Lproj` → PROJECT (tabla remota)
5. **FLATWRAPPER**: Acceso a archivo CSV
   - `FILECLIENTES2` → /var/db2/files/file_clientes2.txt

### Nodo Remoto (db2_remote - SAMPLE)

**Puerto de Acceso Remoto**: `50001` (localhost:50001)
**Puerto Interno**: `50000`

**Base de Datos**: SAMPLE (base oficial de IBM DB2)
- **32 tablas** con datos de ejemplo reales
- **Esquema organizacional**: DEPARTMENT, EMPLOYEE, PROJECT, etc.
- **Esquema XML**: PURCHASEORDER, CUSTOMER, CATALOG, etc.
- **Datos BLOB/CLOB**: Fotos y resumes de empleados
- **Relaciones complejas** y constraints

**Tablas principales utilizadas en federación**:

1. **DEPARTMENT** (14 filas)
   - DEPTNO (PK): Código de departamento
   - DEPTNAME: Nombre del departamento
   - MGRNO: Número del gerente
   - ADMRDEPT: Departamento administrativo

2. **EMPLOYEE** (32 filas)
   - EMPNO (PK): Número de empleado
   - FIRSTNME/LASTNAME: Nombre completo
   - WORKDEPT: Departamento asignado
   - HIREDATE: Fecha de contratación
   - SALARY/BONUS/COMM: Compensación

3. **PROJECT** (6 filas)
   - PROJNO (PK): Número de proyecto
   - PROJNAME: Nombre del proyecto
   - DEPTNO: Departamento responsable
   - PRSTDATE/PRENDATE: Fechas de proyecto

## 🔧 Comandos Comunes

### Consultas a través de Federación

```bash
# Acceder al contenedor federador
docker exec -it db2_federated bash
su - db2inst1
db2 connect to BASETASD

# Consultar datos del servidor remoto
db2 "SELECT * FROM db2Lemp"
db2 "SELECT d.DEPTNAME, COUNT(*) AS EMP_COUNT FROM db2Ldept d JOIN db2Lemp e ON d.DEPTNO = e.WORKDEPT GROUP BY d.DEPTNAME"

# Leer datos del archivo CSV
db2 "SELECT * FROM FILECLIENTES2 WHERE ESTADO = 'Activo'"
```

### Consultas en el Servidor Remoto

```bash
# Acceder al contenedor remoto
docker exec -it db2_remote bash
su - db2inst1
db2 connect to SAMPLE

# Ver datos locales
db2 "SELECT * FROM DB2INST1.DEPARTMENT"
db2 "SELECT EMPNO, FIRSTNME, LASTNAME, SALARY FROM DB2INST1.EMPLOYEE ORDER BY SALARY DESC"

# Ver estadísticas
db2 "SELECT TABNAME, CARD FROM SYSCAT.TABLES WHERE CREATOR='DB2INST1'"
```

### Administración de Contenedores

```bash
# Ver estado
docker-compose ps

# Ver logs
docker-compose logs -f db2_federated
docker-compose logs -f db2_remote

# Detener contenedores
docker-compose down

# Detener y eliminar volúmenes
docker-compose down -v

# Reiniciar
docker-compose restart

# Reconstruir desde cero
docker-compose down -v
docker-compose up -d
./setup.sh
```

## 🔐 Seguridad y Credenciales

### Credenciales por Defecto

- **Usuario**: `db2inst1`
- **Contraseña**: `db2inst1`

⚠️ **IMPORTANTE**: Cambiar las credenciales en producción

### Cambiar Credenciales

1. Editar `docker-compose.yml`:
```yaml
environment:
  DB2INST1_PASSWORD: "tu_nueva_contraseña"
```

2. Editar scripts SQL con nueva contraseña en:
   - `scripts/init_federation.sql` (línea de CREATE USER MAPPING)
   - `scripts/init_sample_db.sql` si es necesario

3. Reiniciar contenedores:
```bash
docker-compose down -v
docker-compose up -d
./setup.sh
```

## 🐛 Troubleshooting

### Los contenedores no inician

```bash
# Ver logs detallados
docker-compose logs

# Verificar recursos disponibles
docker system df

# Limpiar contenedores y volúmenes
docker-compose down -v
docker system prune -a
docker-compose up -d
```

### No puedo conectarme a la base de datos

```bash
# Verificar si el contenedor está corriendo
docker ps | grep db2

# Revisar logs
docker exec db2_federated db2diag.log | tail -50

# Probar conexión
docker exec db2_federated bash -c "su - db2inst1 -c 'db2 get db cfg'"
```

### Los nicknames no funcionan

```bash
# Verificar configuración de federación
docker exec -it db2_federated bash
su - db2inst1
db2 connect to BASETASD
db2 "SELECT * FROM SYSCAT.NICKTAB"
db2 "SELECT * FROM SYSCAT.SERVERS"

# Verificar conectividad entre contenedores
docker exec db2_federated ping db2_remote
```

### Permisos de volúmenes

```bash
# En macOS/Linux, asegurar permisos en directorio data
chmod 755 data/
chmod 757 scripts/
```

## 📊 Monitoreo y Métricas

### Ver Conexiones Activas

```bash
docker exec -it db2_federated bash -c "
  su - db2inst1 -c 'db2 connect to BASETASD; db2 get snapshot for applications on BASETASD'
"
```

### Ver Espacios de Almacenamiento

```bash
docker exec -it db2_federated bash -c "
  su - db2inst1 -c 'db2 connect to BASETASD; db2 list tablespaces show detail'
"
```

### Backup de Datos

```bash
# Backup del nodo federador
docker exec -i db2_federated bash -c "
  su - db2inst1 -c 'db2 connect to BASETASD; db2 backup db BASETASD to /dev/stdout' > basetasd_backup.bak
"

# Backup del nodo remoto
docker exec -i db2_remote bash -c "
  su - db2inst1 -c 'db2 connect to SAMPLE; db2 backup db SAMPLE to /dev/stdout' > sample_backup.bak
"
```

## 🌉 Puertos y Conectividad

| Servicio | Contenedor | Puerto Interno | Puerto Externo | Descripción |
|----------|-----------|-----------------|-----------------|---|
| db2_federated | db2_federated | 50000 | 50000 | Nodo federador (BASETASD) |
| db2_remote | db2_remote | 50000 | 50001 | Nodo remoto (SAMPLE) |

## 🔄 Ciclo de Vida

### Inicialización (First Run)

```bash
docker-compose up -d      # Iniciar contenedores
sleep 30                   # Esperar a que estén listos
./setup.sh                 # Ejecutar configuración
```

### Ejecución Normal

```bash
docker-compose up -d       # Reiniciar si fue detenido
# Sistema completamente operacional
```

### Apagado

```bash
docker-compose down        # Detener sin eliminar datos
# Los volúmenes se mantienen, datos persistentes
```

### Limpieza Total

```bash
docker-compose down -v     # Detener y eliminar volúmenes
# Todos los datos se pierden, vuelve al estado inicial
```

## 📚 Documentación de Referencia

### IBM DB2 LUW v11.5
- [DB2 Federated Database](https://www.ibm.com/docs/en/db2/11.5)

### Docker
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)

### Contenedor ibmcom/db2
- [IBM DB2 Docker Hub](https://hub.docker.com/r/ibmcom/db2)

## 🤝 Contribuciones

Para reportar issues o sugerencias:

1. Crear un issue en el repositorio
2. Incluir versión de Docker y SO
3. Adjuntar logs relevantes

## 📄 Licencia

Este proyecto es educativo. DB2 Community Edition tiene sus propias restricciones de licencia.

## 👨‍🎓 Autor

Laboratorio de Tecnologías Aplicadas a Soluciones de Datos (TASD)
Universidad Tecnológica Nacional - Facultad Regional Buenos Aires

---

**Última Actualización**: Abril 2026
**Versión**: 1.0.0
**Compatible con**: Windows, macOS, Linux | x86, ARM64