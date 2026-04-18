# TASD-Federation - File Index & Navigation

Referencia completa de todos los archivos del proyecto TASD-Federation.

## 📁 Estructura de Archivos

```
TASD-Federation/
│
├── 📄 README.md                    ← EMPEZAR AQUÍ
│                                      Documentación principal, guía de instalación,
│                                      requisitos previos, arquitectura general
│
├── 🚀 QUICK_START.md               ← Guía rápida (5 minutos)
│                                      Comando básicos, referencia rápida
│
├── 🏗️ ARCHITECTURE.md               ← Referencia técnica detallada
│                                      Diagramas, componentes, flujos de datos
│
├── 🐛 TROUBLESHOOTING.md           ← Solución de problemas
│                                      Errores comunes y soluciones
│
├── 🔧 docker-compose.yml            ← Configuración de contenedores
│                                      Dos servicios DB2, volúmenes, networks
│
├── 📋 Makefile                      ← Comandos abreviados
│                                      make up, make down, make logs, etc.
│
├── 🔐 .env.example                  ← Variables de entorno (plantilla)
│                                      Copiar a .env y modificar según sea necesario
│
├── 📝 .gitignore                    ← Archivos ignorados por Git
│                                      Volúmenes, backups, logs
│
├── 🚫 .dockerignore                 ← Archivos ignorados en build Docker
│                                      Optimización de tamaño de imagen
│
│
├── 🔹 setup.sh                      ← Script Setup (macOS/Linux)
│                                      Inicializa federación DB2 automáticamente
│                                      Chmod: chmod +x setup.sh
│
├── 🔹 setup.bat                     ← Script Setup (Windows PowerShell)
│                                      Inicializa federación DB2 en Windows
│
├── ✅ verify.sh                     ← Verificación previa (bash)
│                                      Valida requisitos, estructura, puertos
│
├── ✅ verify.ps1                    ← Verificación previa (PowerShell)
│                                      Versión Windows del verificador
│
│
├── 📂 scripts/
│   ├── init_federation.sql          ← Script SQL: Federación
│   │                                   Wrappers DRDA, FLAT
│   │                                   Servidores, Nicknames
│   │
│   └── init_sample_db.sql           ← Script SQL: Base remota
│                                       Tablas: DEPARTMENT, EMPLOYEE, PROJECT
│                                       Datos de prueba, índices
│
└── 📂 data/
    └── file_clientes2.txt           ← Archivo CSV
                                        Datos para FLATWRAPPER
                                        15 clientes de prueba
```

## 🎯 Punto de Entrada Recomendado

### Por Rol/Situación:

**👤 Administrador/DevOps**
```
1. Leer: README.md (sección Requisitos)
2. Ejecutar: ./verify.sh (o verify.ps1)
3. Ejecutar: docker-compose up -d
4. Ejecutar: ./setup.sh (o setup.bat)
5. Referencia: QUICK_START.md
```

**👨‍💻 Desarrollador que quiere conectarse**
```
1. Leer: QUICK_START.md
2. Usar: docker exec -it db2_federated bash
3. Referencia SQL: ARCHITECTURE.md (SQL examples)
4. Problemas: TROUBLESHOOTING.md
```

**🔍 Investigador/Estudiante**
```
1. Leer: README.md (completo)
2. Explorar: ARCHITECTURE.md (concepto)
3. Practica: QUICK_START.md (comandos)
4. Detalles: scripts/*.sql (implementación)
```

**🛠️ Troubleshooting**
```
1. Leer: TROUBLESHOOTING.md (checklist)
2. Ejecutar: ./verify.sh
3. Ver logs: docker-compose logs -f
4. Ejecutar: docker-compose logs
```

## 📖 Archivos de Documentación

### README.md
- **Objeto**: Documentación principal del proyecto
- **Audiencia**: Todos
- **Contenido**:
  - Descripción del proyecto
  - Requisitos de software
  - Instalación en cada SO
  - Arquitectura general
  - Inicio rápido
  - Comandos comunes
  - Troubleshooting básico
  - Puertos y conectividad
  - Backup/restore
- **Lectura estimada**: 30 minutos

### QUICK_START.md
- **Objeto**: Referencia rápida de comandos
- **Audiencia**: Usuarios ya familiarizados
- **Contenido**:
  - Paso a paso 5 minutos
  - Comandos frecuentes
  - Referencia de puertos
  - Tablas de datos
  - FAQ rápida
- **Lectura estimada**: 10 minutos

### ARCHITECTURE.md
- **Objeto**: Referencia técnica profunda
- **Audiencia**: Administradores, arquitectos
- **Contenido**:
  - Diagramas detallados
  - Componentes de DB2
  - Wrappers y nicknames
  - Volúmenes y networks
  - Flujos de datos
  - Seguridad
  - Performance
- **Lectura estimada**: 45 minutos

### TROUBLESHOOTING.md
- **Objeto**: Solución de problemas
- **Audiencia**: Todos (cuando hay errores)
- **Contenido**:
  - Diagnóstico rápido
  - Errores comunes
  - Soluciones paso-a-paso
  - Comandos de depuración
  - Checklist de troubleshooting
- **Lectura estimada**: Variable (según problema)

## ⚙️ Archivos de Configuración

### docker-compose.yml
```yaml
Contenido:
  • db2_federated (servicio BASETASD)
  • db2_remote (servicio SAMPLE)
  • Volúmenes (db2_federated_data, db2_remote_data)
  • Network (db2_network)
  • Mounts (scripts/, data/)
  • Variables de entorno
  • Health checks
```

**Editar si**:
- Cambiar puertos
- Modificar credenciales
- Ajustar recursos
- Cambiar imagen DB2

**No editar si**: Solo quieres usar el laboratorio

### Makefile
```makefile
Objetivos principales:
  make help        - Ver todos los comandos
  make up          - Iniciar contenedores
  make down        - Detener contenedores
  make clean       - Eliminar volúmenes
  make setup       - Ejecutar setup
  make logs        - Ver logs
  make test        - Pruebas de conectividad
  make backup-fed  - Backup del federador
  make backup-rem  - Backup del remoto
```

**Usar si**: Prefieres comandos cortos en lugar de escribir comandos largos

**Alternativa**: `docker-compose` directamente

### .env.example
```bash
Contiene:
  • DB2INST1_PASSWORD
  • DB2_WORKLOAD
  • FEDERATED_* variables
  • COMPOSE_* variables
  • LOG_LEVEL
  • BACKUP_* variables
```

**Usar si**: Necesitas configurar variables de entorno personalizadas

**Cómo usar**:
```bash
cp .env.example .env
# Editar .env con tus valores
docker-compose up -d  # Usa variables de .env
```

### .gitignore
```
Archivos ignorados:
  • *.bak, *.log
  • Volúmenes (db2_*_data/)
  • .env (no commitear)
  • IDE files (.vscode, .idea)
  • Python/Node (venv, node_modules)
```

### .dockerignore
```
Archivos no incluidos en build:
  • CI/CD files
  • IDE files
  • Node/Python venv
  • Documentación
  • Logs previos
```

## 🔧 Archivos Ejecutables

### setup.sh
```bash
✅ Funciona en: macOS, Linux
❌ No funciona en: Windows (usar setup.bat o WSL)
    
Qué hace:
  1. Espera a que contenedores estén listos
  2. Inicializa SAMPLE db con tablas
  3. Configura federación en BASETASD
  4. Crea nicknames
  5. Verifica setup exitoso
  
Prerequisitos:
  • docker-compose up -d (ejecutado primero)
  • chmod +x setup.sh (hacer ejecutable)

Uso:
  ./setup.sh
```

### setup.bat
```batch
✅ Funciona en: Windows PowerShell
    
Qué hace:
  • Mismas operaciones que setup.sh
  • Adaptadas a sintaxis batch
  
Prerequisitos:
  • docker-compose up -d
  • PowerShell (incluido en Windows)
  
Uso:
  .\setup.bat
```

### verify.sh
```bash
✅ Funciona en: macOS, Linux
    
Qué verifica:
  1. Docker instalado
  2. Docker Compose instalado
  3. Docker daemon corriendo
  4. Arquitectura compatible
  5. Archivos de proyecto
  6. Sintaxis docker-compose.yml
  7. Puertos disponibles
  8. Recursos disponibles
  9. Permisos de archivos
  10. Conectividad a Internet

Uso:
  chmod +x verify.sh
  ./verify.sh
```

### verify.ps1
```powershell
✅ Funciona en: Windows PowerShell
    
Qué verifica:
  • Mismas verificaciones que verify.sh
  • Adaptadas a PowerShell
  
Prerequisitos:
  • PowerShell 3.0+
  
Uso:
  .\verify.ps1
```

## 📄 Archivos de Datos/Scripts

### scripts/init_federation.sql
```sql
Contenido:
  1. Active FEDERATED YES
  2. CREATE WRAPPER DRDA
  3. CREATE SERVER DB2SERVERLOCAL
  4. CREATE USER MAPPING
  5. CREATE WRAPPER FLAT
  6. CREATE NICKNAME db2Ldept
  7. CREATE NICKNAME db2Lemp
  8. CREATE NICKNAME db2Lproj
  9. CREATE NICKNAME FILECLIENTES2
  10. Validar con SELECT de SYSCAT

Ejecutado por:
  • ./setup.sh (automáticamente)
  • Manualmente con: db2 -f scripts/init_federation.sql
```

### scripts/init_sample_db.sql
```sql
Contenido:
  1. CREATE SCHEMA DB2INST1
  2. CREATE TABLE DEPARTMENT (3 columnas)
  3. CREATE TABLE EMPLOYEE (14 columnas)
  4. CREATE TABLE PROJECT (7 columnas)
  5. INSERT datos de prueba (~3 filas c/tabla)
  6. CREATE INDEXes para performance
  7. Validar con SELECT COUNT

Ejecutado por:
  • ./setup.sh (automáticamente)
  • Manualmente con: db2 -f scripts/init_sample_db.sql
```

### data/file_clientes2.txt
```csv
Formato: Delimitado por comas
Header: CLIENTEID,NOMBRE,APELLIDO,...,ESTADO
Filas: 15 clientes de prueba
Campos: 10 (ID, nombre, contacto, ubicación, dates, estado)
Encoding: UTF-8

Usado por:
  • FLATWRAPPER (lee como tabla)
  • Consultas: SELECT * FROM FILECLIENTES2
```

## 📊 Matriz de Uso Rápido

| Tarea | Comando | Archivo Ref |
|-------|---------|------------|
| Verificar requisitos | `./verify.sh` | verify.sh |
| Iniciar sistema | `docker-compose up -d` | docker-compose.yml |
| Configurar federación | `./setup.sh` | setup.sh |
| Ver estado | `docker-compose ps` | QUICK_START.md |
| Ver logs | `docker-compose logs -f` | QUICK_START.md |
| Conectar a DB | `docker exec -it db2_federated bash` | QUICK_START.md |
| Hacer backup | `make backup-fed` | Makefile |
| Limpiar todo | `docker-compose down -v` | README.md |
| Resolver error | Ver TROUBLESHOOTING.md | TROUBLESHOOTING.md |
| Entender arquitectura | Ver ARCHITECTURE.md | ARCHITECTURE.md |

## 🔍 Búsqueda por Tema

### Network & Conectividad
- Referencia: README.md § Puertos y Conectividad
- Técnica: ARCHITECTURE.md § 5. Network Docker
- Troubleshoot: TROUBLESHOOTING.md § Error -30081

### Federación & Wrappers
- Teoría: ARCHITECTURE.md § 2. Wrappers
- Implementación: scripts/init_federation.sql
- Comandos: QUICK_START.md § Acceso a Bases de Datos

### Seguridad
- Credenciales: README.md § Seguridad y Credenciales
- Técnica: ARCHITECTURE.md § Seguridad
- Cambiar: README.md § Cambiar Credenciales

### Performance
- Optimización: ARCHITECTURE.md § Performance
- Monitoreo: QUICK_START.md § Monitoreo y Métricas  
- Troubleshoot: TROUBLESHOOTING.md § Performance lento

### Backups
- Política: README.md § Monitoreo y Métricas
- Comandos: Makefile (make backup-fed, make backup-rem)
- Referencia: QUICK_START.md § Backup de Datos

## 📋 Checklist para Nuevos Usuarios

- [ ] Leer README.md (completo)
- [ ] Ejecutar verify.sh/verify.ps1
- [ ] Ejecutar docker-compose up -d
- [ ] Ejecutar setup.sh/setup.bat
- [ ] Verificar con docker-compose ps
- [ ] Conectar con docker exec -it db2_federated bash
- [ ] Ejecutar una consulta: db2 "SELECT * FROM db2Lemp"
- [ ] Marcar Makefile como referencia rápida
- [ ] Guarda QUICK_START.md como bookmark
- [ ] Guarda TROUBLESHOOTING.md para referencia

## 🚀 Workflow Completo

```
1º Instalación
   └─> Leer README.md
   └─> Ejecutar verify.sh
   └─> Ejecutar docker-compose up -d
   └─> Ejecutar setup.sh

2º Uso Diario
   └─> Referencia: Makefile o QUICK_START.md
   └─> Conectar: docker exec -it db2_federated bash

3º Solución de Problemas
   └─> Referencia: TROUBLESHOOTING.md
   └─> Ejecutar: verify.sh
   └─> Ver: docker-compose logs

4º Profundizar
   └─> Teoría: ARCHITECTURE.md
   └─> Implementación: scripts/*.sql
```

---

**Última Actualización**: Abril 2026
**Versión**: 1.0.0
**Tamaño Total**: ~200KB de documentación + ~500MB datos DB2
