# TASD-Federation - Troubleshooting Guide

Guía completa de solución de problemas para la arquitectura de federación DB2.

## 🔍 Diagnóstico Rápido

### 1. Verificar Estado General

```bash
# Ver si los contenedores están corriendo
docker-compose ps

# Si ves EXITED o RESTARTING, hay un problema
# Ver logs para más detalles
docker-compose logs --tail=50
```

### 2. Verificar Conectividad de Red

```bash
# Probar que db2_federated puede ver db2_remote
docker exec db2_federated ping db2_remote

# Si falla, revisar la configuración de network en docker-compose.yml
```

### 3. Verificar Configuración de Federación

```bash
# Acceder al contenedor federador
docker exec -it db2_federated bash
su - db2inst1

# Conectar a la base de datos
db2 connect to BASETASD

# Verificar que FEDERATED está activo
db2 "GET DB CFG" | grep -i federated

# Listar servidores federados
db2 "SELECT SERVERNAME, SERVERTYPE, HOSTNAME FROM SYSCAT.SERVERS"

# Listar nicknames
db2 "SELECT TABNAME, REMOTE_NAME FROM SYSCAT.NICKTAB"

db2 connect reset
exit
```

---

## 🚨 Problemas Comunes

### ❌ Error: "Cannot connect to Docker daemon"

**Síntoma**: El comando `docker-compose` falla
```
Cannot connect to Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?
```

**Solución**:

**macOS**:
```bash
# Abrir Docker Desktop (busca en Applications)
# O ejecutar desde terminal
open -a Docker
```

**Windows**:
```powershell
# Abrir Docker Desktop
# O desde PowerShell
start "C:\Program Files\Docker\Docker\Docker Desktop.exe"
```

**Linux**:
```bash
# Iniciar el servicio Docker
sudo systemctl start docker
sudo systemctl enable docker

# Agregar usuario al grupo docker (sin sudo)
sudo usermod -aG docker $USER
newgrp docker
```

---

### ❌ Error: "Port is already allocated"

**Síntoma**: 
```
Error response from daemon: Ports are not available: listen tcp 0.0.0.0:50000: bind: address already in use
```

**Solución**:

1. **Opción 1: Cambiar el puerto en docker-compose.yml**
```yaml
ports:
  - "50002:50000"  # Cambiar 50000 a 50002
```

2. **Opción 2: Encontrar y matar el proceso que usa el puerto**
```bash
# macOS/Linux - Ver qué está usando puerto 50000
lsof -i :50000

# Ver el PID y matar el proceso
kill -9 <PID>

# Windows PowerShell
netstat -ano | findstr :50000
taskkill /PID <PID> /F
```

3. **Opción 3: Usar un puerto diferente**
```bash
# En docker-compose.yml cambiar:
ports:
  - "50010:50000"  # Puerto 50010 en host, 50000 en contenedor
```

---

### ❌ Error: "docker-compose: not found"

**Síntoma**: 
```
docker-compose: not found
```

**Solución**:

**Versión antigua de Docker**:
```bash
# Docker Compose v1 requiere instalación separada
# Actualizar a Docker Desktop actual (incluye Compose v2)

# O instalarlo manualmente
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

**Verificar instalación correcta**:
```bash
docker compose version  # Nota: v2 usa "docker compose", no "docker-compose"
# O
docker-compose --version  # v1
```

---

### ❌ Error: "License agreement"

**Síntoma**:
```
LICENSE: This image requires you to accept the IBM DB2 License agreement
```

**Solución**:

En `docker-compose.yml`, verificar que existe:
```yaml
environment:
  LICENSE: "accept"
```

Si no está:
```bash
docker-compose down -v
# Editar docker-compose.yml
# Agregar LICENSE: "accept"
docker-compose up -d
```

---

### ❌ Contenedor se reinicia continuamente (RESTARTING)

**Síntoma**: En `docker-compose ps` ves estado RESTARTING

**Solución**:

1. Ver logs detallados:
```bash
docker-compose logs -f db2_federated
docker-compose logs -f db2_remote
```

2. Problemas comunes:
   - **Memoria insuficiente**: Aumentar RAM disponible para Docker
   - **Contraseña incorrecta**: Verificar `DB2INST1_PASSWORD` en docker-compose.yml
   - **Volumen con permisos**: En Linux, ajustar permisos

3. Reintentar:
```bash
docker-compose down -v
docker-compose up -d
sleep 30
./setup.sh
```

---

### ❌ Error: "SQLSTATE=56098 SQLCODE=-30081"

**Síntoma**: "Communication function detect an error" al intentar contacter servidor remoto

**Solución**:

1. Verificar que el servidor remoto está corriendo:
```bash
docker-compose ps db2_remote
# Debe estar en estado "Up"
```

2. Verificar conectividad:
```bash
docker exec db2_federated ping db2_remote
```

3. Verificar la configuración del servidor en SYSCAT.SERVERS:
```bash
docker exec -it db2_federated bash
su - db2inst1
db2 connect to BASETASD
db2 "SELECT SERVERNAME, HOSTNAME, PORT FROM SYSCAT.SERVERS"
```

4. El hostname debe ser exactamente el nombre del contenedor: `db2_remote`

---

### ❌ Error: "Nickname does not exist"

**Síntoma**: `db2 "SELECT * FROM db2Lemp"` falla con "Table does not exist"

**Solución**:

1. Verificar que los nicknames fueron creados:
```bash
docker exec -it db2_federated bash
su - db2inst1
db2 connect to BASETASD
db2 "SELECT TABNAME, REMOTE_NAME FROM SYSCAT.NICKTAB"
db2 connect reset
```

2. Si no hay nicknames, ejecutar setup de nuevo:
```bash
./setup.sh  # o setup.bat
```

3. Si setup falla, verificar logs:
```bash
docker-compose logs db2_federated
```

---

### ❌ Error: "SQLSTATE=08001 SQLCODE=-1019"

**Síntoma**: "Unexpected end-of-file on Communication Channel" al conectar a servidor remoto

**Solución**:

1. Verificar que la base de datos remota existe y está activa:
```bash
docker exec -it db2_remote bash
su - db2inst1
db2 list active databases
```

2. Si no está activa, activarla:
```bash
db2 activate database SAMPLE
```

3. Volver al contenedor federador e intentar de nuevo:
```bash
docker exec -it db2_federated bash
su - db2inst1
db2 connect to BASETASD
db2 "SELECT * FROM db2Lemp FETCH FIRST 1 ROW ONLY"
```

---

### ❌ Error: "SQL1013N The database alias name or database name ... does not exist"

**Síntoma**: No se puede conectar a BASETASD o SAMPLE

**Solución**:

1. Verificar que existen los catálogos locales:
```bash
# En el contenedor db2_federated
docker exec -it db2_federated bash
su - db2inst1
db2 list database directory
# BASETASD debe aparecer en la lista
```

2. Si BASETASD no existe, reiniciar el contenedor:
```bash
docker-compose restart db2_federated
sleep 20
./setup.sh
```

---

### ❌ Performance lento / Queries tardando mucho

**Síntoma**: Las consultas a nicknames son muy lentas

**Solución**:

1. Verificar aplicación de predicados remotos:
```bash
docker exec -it db2_federated bash
su - db2inst1
db2 connect to BASETASD
db2 "SELECT * FROM db2Lemp WHERE SALARY > 50000"

# Ver el EXPLAIN PLAN
db2 explain plan for select * from db2Lemp where SALARY > 50000

# Verificar si se aplica el predicado remotamente
```

2. Aumentar resources:
```bash
# Editar docker-compose.yml y agregar limits
services:
  db2_federated:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G
```

3. Ejecutar estadísticas:
```bash
docker exec -i db2_remote bash -c "su - db2inst1 << 'EOF'
db2 connect to SAMPLE
db2 runstats on table DB2INST1.EMPLOYEE with distribution
db2 runstats on table DB2INST1.DEPARTMENT with distribution
db2 connect reset
EOF"
```

---

### ❌ Error: "SQL0805N Package not Found" con FLATWRAPPER

**Síntoma**: No se puede consultar FILECLIENTES2

**Solución**:

1. Verificar que el archivo existe en el contenedor:
```bash
docker exec db2_federated ls -l /var/db2/files/
# Debe mostrar file_clientes2.txt
```

2. Si no existe, copiar el archivo:
```bash
docker cp data/file_clientes2.txt db2_federated:/var/db2/files/
docker exec db2_federated chmod 644 /var/db2/files/file_clientes2.txt
```

3. Reintentar el setup:
```bash
./setup.sh
```

4. Si aún falla, verificar permisos:
```bash
docker exec -it db2_federated bash -c "su - db2inst1 -c 'db2 connect to BASETASD; db2 \"SELECT * FROM FILECLIENTES2 FETCH FIRST 1 ROW ONLY\"'"
```

---

## 🔧 Comandos de Depuración Avanzados

### Capturar traces de conexión
```bash
docker exec -it db2_federated bash
su - db2inst1
db2 connect to BASETASD
db2cli trace +d +a +w /tmp/cli_trace
# Ejecutar consulta que falla
# Ver logs
db2cli trace -a -d
```

### Revisar logs de sistema
```bash
docker exec db2_federated cat /var/db2inst1/sqllib/db2dump/db2diag.log | tail -100
```

### Ver configuración actual
```bash
docker exec -i db2_federated bash -c "su - db2inst1 << 'EOF'
db2 connect to BASETASD
db2 GET DB CFG
db2 GET DBM CFG
db2 connect reset
EOF"
```

### Validar integridad de catálogo
```bash
docker exec -i db2_federated bash -c "su - db2inst1 << 'EOF'
db2 connect to BASETASD
db2 SYSCK BASETASD
db2 connect reset
EOF"
```

---

## 📋 Checklist de Troubleshooting

Si algo no funciona, seguir este orden:

- [ ] 1. ¿Docker está corriendo? `docker ps`
- [ ] 2. ¿Los contenedores están Up? `docker-compose ps`
- [ ] 3. ¿Puedo acceder a bash? `docker exec -it db2_federated bash`
- [ ] 4. ¿Puedo conectar a la BD? `db2 connect to BASETASD`
- [ ] 5. ¿Existen los nicknames? `SELECT * FROM SYSCAT.NICKTAB`
- [ ] 6. ¿Puedo ping al servidor remoto? `docker exec db2_federated ping db2_remote`
- [ ] 7. ¿La BD remota existe? `docker exec -it db2_remote bash -c "db2 list active databases"`
- [ ] 8. Ver logs: `docker-compose logs --tail=100`
- [ ] 9. Limpiar y reintentar: `docker-compose down -v && docker-compose up -d && ./setup.sh`

---

## 📞 Obtener Ayuda

Si el problema persiste:

1. Recopilar información:
```bash
docker-compose logs > logs.txt 2>&1
docker-compose ps >> logs.txt 2>&1
docker inspect db2_federated >> logs.txt 2>&1
docker exec -i db2_federated bash -c "du -sh /var/db2inst1/sqllib/db2dump/" >> logs.txt 2>&1
```

2. Incluir logs en el issue de GitHub

3. Especificar:
   - Sistema operativo (macOS/Windows/Linux)
   - Arquitectura (Intel/ARM)
   - Version de Docker
   - Pasos que causaron el problema

---

**Última Actualización**: Abril 2026
**Para Soporte**: Ver README.md - Sección Contribuciones
