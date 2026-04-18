# TASD-Federation - Quick Start Guide

## 🚀 Inicio Rápido (5 minutos)

### Paso 1: Verificar instalación
```bash
docker --version
docker-compose --version
```

### Paso 2: Clonar y navegar
```bash
git clone https://github.com/tu-usuario/TASD-Federation.git
cd TASD-Federation
```

### Paso 3: Iniciar servicios
```bash
# macOS/Linux
docker-compose up -d
chmod +x setup.sh
./setup.sh

# Windows (PowerShell)
docker-compose up -d
.\setup.bat
```

### Paso 4: Verificar
```bash
docker-compose ps
docker exec -it db2_federated bash
su - db2inst1
db2 connect to BASETASD
db2 "SELECT * FROM db2Lemp"
```

---

## 📋 Referencia de Comandos

### Información General
```bash
# Estado de contenedores
docker-compose ps

# Ver logs en tiempo real
docker-compose logs -f

# Ver logs de un contenedor específico
docker-compose logs -f db2_federated

# Información de sistema
docker system df
```

### Acceso a Bases de Datos

#### Nodo Federador (BASETASD)
```bash
docker exec -it db2_federated bash
su - db2inst1
db2 connect to BASETASD

# Consultas
db2 "SELECT * FROM db2Lemp"
db2 "SELECT * FROM db2Ldept"
db2 "SELECT * FROM db2Lproj"
db2 "SELECT * FROM FILECLIENTES2"

db2 connect reset
exit
```

#### Nodo Remoto (SAMPLE)
```bash
docker exec -it db2_remote bash
su - db2inst1
db2 connect to SAMPLE

# Ver tablas
db2 "SELECT TABNAME FROM SYSCAT.TABLES WHERE CREATOR='DB2INST1'"

# Consultas
db2 "SELECT * FROM DB2INST1.EMPLOYEE"
db2 "SELECT * FROM DB2INST1.DEPARTMENT"

db2 connect reset
exit
```

### Administración

#### Detener Contenedores
```bash
docker-compose down
```

#### Detener y Eliminar Datos
```bash
docker-compose down -v
```

#### Reiniciar
```bash
docker-compose restart
```

#### Reconstruir desde Cero
```bash
docker-compose down -v
docker-compose up -d
./setup.sh  # o setup.bat en Windows
```

### Monitoreo y Diagnóstico

#### Ver Logs de DB2
```bash
docker exec db2_federated tail -50 /var/db2inst1/sqllib/db2dump/diag.log
```

#### Prueba de Conectividad entre Contenedores
```bash
docker exec db2_federated ping db2_remote
```

#### Ver Variables de Configuración
```bash
docker exec -it db2_federated bash
su - db2inst1
db2 connect to BASETASD
db2 "GET DB CFG" | grep -i federated
db2 connect reset
```

#### Listar Wrappers
```bash
docker exec -it db2_federated bash
su - db2inst1
db2 connect to BASETASD
db2 "SELECT WRAPNAME, WRAPTYPE FROM SYSCAT.WRAPPERS"
db2 connect reset
```

#### Listar Servidores Federados
```bash
docker exec -it db2_federated bash
su - db2inst1
db2 connect to BASETASD
db2 "SELECT SERVERNAME, SERVERTYPE, HOSTNAME FROM SYSCAT.SERVERS"
db2 connect reset
```

#### Listar Nicknames
```bash
docker exec -it db2_federated bash
su - db2inst1
db2 connect to BASETASD
db2 "SELECT TABNAME, REMOTE_NAME, SERVERNAME FROM SYSCAT.NICKTAB"
db2 connect reset
```

### Backup y Restore

#### Backup Federador
```bash
docker exec -i db2_federated bash -c "su - db2inst1 -c 'db2 connect to BASETASD; db2 backup db BASETASD to /dev/stdout'" > basetasd_backup.bak
```

#### Backup Remoto
```bash
docker exec -i db2_remote bash -c "su - db2inst1 -c 'db2 connect to SAMPLE; db2 backup db SAMPLE to /dev/stdout'" > sample_backup.bak
```

### Solución de Problemas

#### Contenedores no inician
```bash
# Ver logs detallados
docker-compose logs

# Limpiar e intentar de nuevo
docker system prune -a
docker-compose up -d
```

#### Error de conectividad
```bash
# Revisar estado de contenedores
docker ps

# Revisar logs
docker logs db2_federated
docker logs db2_remote

# Reiniciar
docker-compose restart
```

#### Nicknames no funcionan
```bash
# Verificar configuración
docker exec -it db2_federated bash
su - db2inst1
db2 connect to BASETASD
db2 "SELECT * FROM SYSCAT.NICKTAB"
db2 "SELECT * FROM SYSCAT.SERVERS"
db2 connect reset

# Verificar conectividad
docker exec db2_federated ping db2_remote
```

---

## 🔑 Credenciales Predeterminadas

| Campo | Valor |
|-------|-------|
| Usuario | `db2inst1` |
| Contraseña | `db2inst1` |

**⚠️ CAMBIAR EN PRODUCCIÓN**

---

## 🌐 Puertos de Acceso

| Nombre | Puerto Interno | Puerto Externo | Descripción |
|--------|-----------------|-----------------|---|
| db2_federated | 50000 | 50000 | Nodo Federador (BASETASD) |
| db2_remote | 50000 | 50001 | Nodo Remoto (SAMPLE) |

---

## 📊 Estructura de Datos

### Nodo Remoto (db2_remote - SAMPLE)

#### Tabla DEPARTMENT
- DEPTNO (PK): Código de departamento
- DEPTNAME: Nombre
- MGRNO: Gerente
- ADMRDEPT: Departamento administrativo

#### Tabla EMPLOYEE
- EMPNO (PK): Número de empleado
- FIRSTNME/LASTNAME: Nombre completo
- WORKDEPT: Departamento
- HIREDATE: Fecha de contratación
- SALARY: Salario

#### Tabla PROJECT
- PROJNO (PK): Número de proyecto
- PROJNAME: Nombre
- DEPTNO: Departamento responsable

### Nodo Federador (db2_federated - BASETASD)

#### Nicknames Federados
- `db2Ldept` → DEPARTMENT (remoto)
- `db2Lemp` → EMPLOYEE (remoto)
- `db2Lproj` → PROJECT (remoto)

#### Wrapper FLAT
- `FILECLIENTES2` → /var/db2/files/file_clientes2.txt

---

## 🔧 Notas Técnicas

### Compatibilidad
- ✅ macOS (Intel & Apple Silicon M1/M2/M3)
- ✅ Linux (x86/AMD64)
- ✅ Windows (x86 con WSL 2 o Docker Desktop)

### DB2 Version
- **Versión**: IBM DB2 LUW v11.5
- **Imagen Docker**: `ibmcom/db2:11.5.9.0-x86_64`

### Network
- **Driver**: bridge (db2_network)
- **Hostname Resolution**: hostname del contenedor
- **Puerto interno entre contenedores**: 50000

---

## 📚 Archivos Clave

| Archivo | Descripción |
|---------|---|
| `docker-compose.yml` | Configuración de contenedores |
| `setup.sh` | Script de inicialización (macOS/Linux) |
| `setup.bat` | Script de inicialización (Windows) |
| `scripts/init_federation.sql` | Federación DB2 |
| `scripts/init_sample_db.sql` | Tablas y datos remotos |
| `data/file_clientes2.txt` | Datos CSV para FLATWRAPPER |
| `README.md` | Documentación completa |

---

## 🆘 Soporte

Para reportar problemas:
1. Incluir salida de `docker-compose logs`
2. Incluir versión de Docker
3. Incluir árquitecura (x86 o ARM)
4. Describir pasos para reproducir

---

**Última Actualización**: Abril 2026
**Versión**: 1.0.0
