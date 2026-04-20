# TASD-Federation - Laboratorio de Federación de Datos (Docker)

Este laboratorio recrea el entorno de federación de datos para la materia **TASD (UTN.BA)** utilizando Docker. Sustituye la antigua VM de Windows con una arquitectura moderna de microservicios.

## 🚀 Inicio Rápido

### 1. Iniciar los Contenedores
```bash
docker-compose up -d
```

### 2. Ejecutar el Setup Automático
Este paso configura la base `SAMPLE`, la federación y carga los archivos locales.
```bash
# Windows
bash setup.sh

# macOS / Linux
chmod +x setup.sh
./setup.sh
```

---

## 🔍 ¿Cómo conectarse?

### Acceder al Nodo Federador (Nodo A)
Es el nodo que contiene la base `BASETASD` y desde donde se consultan los datos federados.
```bash
docker exec -it db2_federated bash
su - db2inst1
```

### Acceder al Nodo Remoto (Nodo B)
Es el que contiene la base de datos `SAMPLE` original.
```bash
docker exec -it db2_remote bash
su - db2inst1
```

---

## 🛠️ Comandos Útiles de Verificación

Una vez dentro de cualquier contenedor como usuario `db2inst1`, puedes usar:

### Verificar bases de datos visibles
Para ver si el nodo federador reconoce tanto la base local como la remota (catalogada):
```bash
db2 list database directory
```

### Conectarse a la base federada
```bash
db2 connect to BASETASD
```

### Listar Nicknames (Federación)
Para ver qué tablas remotas están disponibles como si fueran locales:
```bash
db2 "SELECT TABNAME, SERVERNAME FROM SYSCAT.NICKNAMES"
```

### Listar Tablas Locales
Incluyendo el archivo plano importado:
```bash
db2 list tables
```

---

## 📁 Estructura del Proyecto
- `docker-compose.yml`: Define los dos nodos DB2.
- `setup.sh`: Script unificado de inicialización.
- `scripts/init_federation.sql`: Script SQL que crea los Wrappers, Servers y Nicknames.
- `data/file_clientes2.txt`: Datos fuente para la tabla local `FILECLIENTES2`.

---
**Laboratorio de TASD (UTN.BA)**  
*Actualizado: Abril 2026*
