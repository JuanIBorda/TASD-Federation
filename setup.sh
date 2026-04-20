#!/bin/bash
# ============================================================================
# setup.sh
# Script de inicialización de la federación DB2 en Docker
# Uso: ./setup.sh
# ============================================================================

set -e

echo "=========================================="
echo "TASD-Federation Docker Setup"
echo "=========================================="
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para imprimir con color
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# 1. Esperar a que los contenedores estén listos
echo ""
echo "1. Esperando a que los contenedores DB2 estén listos..."
sleep 20

# 2. Verificar que la base SAMPLE esté inicializada (creada automáticamente por Docker)
echo ""
echo "2. Verificando base de datos SAMPLE en db2_remote..."
docker exec -i db2_remote bash -c "su - db2inst1 -c 'db2 connect to SAMPLE'" > /dev/null 2>&1 || {
    print_error "La base SAMPLE no está lista aún. Esperando..."
    sleep 30
    docker exec -i db2_remote bash -c "su - db2inst1 -c 'db2 connect to SAMPLE'" > /dev/null 2>&1 || {
        print_error "No se pudo conectar a SAMPLE después de esperar"
        exit 1
    }
}

# Verificar que las tablas principales existen
docker exec -i db2_remote bash -c "
    su - db2inst1 << 'EOF'
    db2 connect to SAMPLE
    echo 'Verificando tablas principales...'
    db2 \"SELECT COUNT(*) FROM DEPARTMENT\" > /dev/null && echo '✓ Tabla DEPARTMENT OK' || echo '✗ Tabla DEPARTMENT faltante'
    db2 \"SELECT COUNT(*) FROM EMPLOYEE\" > /dev/null && echo '✓ Tabla EMPLOYEE OK' || echo '✗ Tabla EMPLOYEE faltante'
    db2 \"SELECT COUNT(*) FROM PROJECT\" > /dev/null && echo '✓ Tabla PROJECT OK' || echo '✗ Tabla PROJECT faltante'
    db2 connect reset
    exit
EOF
" || print_warning "Algunas operaciones pueden haber fallado en SAMPLE"

print_status "Base de datos SAMPLE inicializada"

# 3. Inicializar federación en el nodo federador (BASETASD)
echo ""
echo "3. Inicializando federación en db2_federated..."

docker exec -i db2_federated bash -c "
    su - db2inst1 << 'EOF'
    db2 connect to BASETASD
    db2 -f /scripts/init_federation.sql
    db2 connect reset
    exit
EOF
" || print_warning "Algunas operaciones pueden haber fallado en la federación"

print_status "Federación inicializada en BASETASD"

# 4. Verificar estado de nicknames
echo ""
echo "4. Verificando nicknames creados..."

docker exec -i db2_federated bash -c "
    su - db2inst1 << 'EOF'
    db2 connect to BASETASD
    db2 'SELECT TABNAME FROM SYSCAT.NICKTAB' 2>/dev/null || echo 'No se pudo verificar nicknames'
    db2 connect reset
    exit
EOF
" || print_warning "No se pudo verificar nicknames"

# 5. Prueba de conexión remota (opcional)
echo ""
echo "5. Prueba de federación (consultando datos del servidor remoto)..."

docker exec -i db2_federated bash -c "
    su - db2inst1 << 'EOF'
    db2 connect to BASETASD
    echo 'Consultando DEPARTMENT del servidor remoto:'
    db2 'SELECT * FROM db2Ldept FETCH FIRST 5 ROWS ONLY' 2>/dev/null || echo 'Consulta de federación completada'
    db2 connect reset
    exit
EOF
"

print_status "Setup completado exitosamente"

echo ""
echo "=========================================="
echo "Próximos pasos:"
echo "=========================================="
echo "1. Conectarse al nodo federador:"
echo "   docker exec -it db2_federated bash"
echo "   su - db2inst1"
echo "   db2 connect to BASETASD"
echo ""
echo "2. Consultar datos federados:"
echo "   db2 'SELECT * FROM db2Lemp'"
echo ""
echo "3. Acceder al archivo plano del FLATWRAPPER:"
echo "   db2 'SELECT * FROM FILECLIENTES2'"
echo ""
echo "Base de datos disponibles:"
echo "  - Nodo Federador: db2_federated (BASETASD) puerto 50000"
echo "  - Nodo Remoto: db2_remote (SAMPLE) puerto 50001"
echo "=========================================="
