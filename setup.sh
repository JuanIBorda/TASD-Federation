#!/bin/bash
# ============================================================================
# setup.sh
# Script de inicialización del laboratorio de federación
# ============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo "TASD-Federation Setup"
echo "=========================================="

# 1. Esperar contenedores
echo "1. Validando estado de los contenedores..."
sleep 20

# 2. Inicializar SAMPLE en remoto
echo "2. Inicializando base de datos SAMPLE remota..."
docker exec -i db2_remote bash -c "su - db2inst1 -c 'db2sampl -force'" > /dev/null 2>&1 || echo -e "${YELLOW}[!]${NC} Aviso en db2sampl"

# 3. Configurar federación y carga de datos
echo "3. Configurando federación y cargando archivos locales..."
docker exec -i db2_federated bash -c "
    su - db2inst1 << 'EOF'
    db2 update dbm cfg using federated YES > /dev/null
    
    # Catalogación del nodo remoto
    db2 uncatalog db SAMPLE > /dev/null 2>&1
    db2 uncatalog node NODO_REM > /dev/null 2>&1
    db2 catalog tcpip node NODO_REM remote db2_remote server 50000 > /dev/null
    db2 catalog db SAMPLE as SAMPLE at node NODO_REM > /dev/null
    
    # Creación de objetos (Nicknames y tablas locales)
    db2 connect to BASETASD > /dev/null
    db2 -tf /scripts/init_federation.sql > /dev/null
    
    # Importación de los datos del CSV
    db2 connect to BASETASD > /dev/null
    db2 \"IMPORT FROM /var/db2/files/file_clientes2.txt OF DEL INSERT INTO FILECLIENTES2\" > /dev/null
    
    db2 connect reset > /dev/null
    exit
EOF
"

echo -e "\n${GREEN}==========================================${NC}"
echo -e "${GREEN} LABORATORIO LISTO PARA USAR${NC}"
echo -e "${GREEN}==========================================${NC}"
echo "Usa 'db2 list db directory' en db2_federated para ver las bases."
echo "Explora los Nicknames y la tabla FILECLIENTES2 en BASETASD."
echo "=========================================="
