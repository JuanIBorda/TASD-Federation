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

# 3. Preparar archivo local en /tmp para External Table
echo "3. Preparando archivos locales para External Table..."
docker exec db2_federated bash -c "cp /var/db2/files/file_clientes2.txt /tmp/file_clientes2.txt && chown db2inst1:db2iadm1 /tmp/file_clientes2.txt && chmod 666 /tmp/file_clientes2.txt"

# 4. Configurar federación
echo "4. Configurando federación (Wrappers, Servers y External Tables)..."
docker exec -i db2_federated bash -c "
    su - db2inst1 << 'EOF'
    db2 update dbm cfg using federated YES > /dev/null
    
    # Catalogación del nodo remoto
    db2 uncatalog db SAMPLE > /dev/null 2>&1
    db2 uncatalog node NODO_REM > /dev/null 2>&1
    db2 catalog tcpip node NODO_REM remote db2_remote server 50000 > /dev/null
    db2 catalog db SAMPLE as SAMPLE at node NODO_REM > /dev/null
    
    # Creación de objetos
    db2 connect to BASETASD > /dev/null
    db2 -tf /scripts/init_federation.sql > /dev/null
    
    db2 connect reset > /dev/null
    exit
EOF
"

echo -e "\n${GREEN}==========================================${NC}"
echo -e "${GREEN} LABORATORIO LISTO PARA USAR${NC}"
echo -e "${GREEN}==========================================${NC}"
echo "FILECLIENTES2 es ahora de tipo 'X' (External Table)."
echo "Usa 'db2 connect to BASETASD' y luego 'db2 select * from FILECLIENTES2'."
echo "=========================================="
