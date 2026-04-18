#!/bin/bash
# ============================================================================
# verify.sh
# Script de verificación previa al despliegue
# Valida la estructura, requisitos y configuración
# ============================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================================${NC}"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
    ERRORS=$((ERRORS + 1))
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
    WARNINGS=$((WARNINGS + 1))
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

# ============================================================================
# Check 1: Docker Installation
# ============================================================================
print_header "1. Verificando instalación de Docker"

if ! command -v docker &> /dev/null; then
    print_error "Docker no está instalado"
    echo "Descargar desde: https://www.docker.com/products/docker-desktop"
else
    DOCKER_VERSION=$(docker --version)
    print_success "Docker instalado: $DOCKER_VERSION"
fi

# ============================================================================
# Check 2: Docker Compose Installation
# ============================================================================
print_header "2. Verificando Docker Compose"

if ! command -v docker-compose &> /dev/null; then
    # Intentar con "docker compose" (v2)
    if docker compose version > /dev/null 2>&1; then
        print_success "Docker Compose v2 disponible"
        COMPOSE_CMD="docker compose"
    else
        print_error "Docker Compose no está instalado"
        echo "Requiere Docker Compose v1.27+ o Docker Desktop con Compose v2"
    fi
else
    COMPOSE_VERSION=$(docker-compose --version)
    print_success "Docker Compose instalado: $COMPOSE_VERSION"
    COMPOSE_CMD="docker-compose"
fi

# ============================================================================
# Check 3: Docker Daemon Status
# ============================================================================
print_header "3. Verificando daemon de Docker"

if ! docker ps > /dev/null 2>&1; then
    print_error "Docker daemon no está corriendo"
    echo "Iniciar Docker Desktop o ejecutar: sudo systemctl start docker"
else
    print_success "Docker daemon está corriendo"
fi

# ============================================================================
# Check 4: Architecture Compatibility
# ============================================================================
print_header "4. Verificando arquitectura"

ARCH=$(uname -m)
case "$ARCH" in
    x86_64|amd64)
        print_success "Arquitectura x86_64 (compatible)"
        ;;
    aarch64|arm64)
        print_success "Arquitectura ARM64 (compatible)"
        ;;
    *)
        print_warning "Arquitectura desconocida: $ARCH (verificar compatibilidad)"
        ;;
esac

# ============================================================================
# Check 5: File Structure
# ============================================================================
print_header "5. Verificando estructura de archivos"

declare -a FILES=(
    "README.md"
    "docker-compose.yml"
    "setup.sh"
    "scripts/init_federation.sql"
    "scripts/init_sample_db.sql"
    "data/file_clientes2.txt"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ] || [ -d "$file" ]; then
        print_success "Existe: $file"
    else
        print_error "Falta: $file"
    fi
done

# ============================================================================
# Check 6: Docker Compose Syntax
# ============================================================================
print_header "6. Validando sintaxis de docker-compose.yml"

if $COMPOSE_CMD config > /dev/null 2>&1; then
    print_success "docker-compose.yml es válido"
else
    print_error "docker-compose.yml tiene errores de sintaxis"
fi

# ============================================================================
# Check 7: Available Ports
# ============================================================================
print_header "7. Verificando puertos disponibles"

# Function to check port availability
check_port() {
    local port=$1
    local name=$2
    
    if ! nc -z localhost $port 2>/dev/null; then
        print_success "Puerto $port disponible ($name)"
    else
        print_error "Puerto $port está en uso ($name)"
    fi
}

# Try to check with netstat or lsof
if command -v nc &> /dev/null; then
    check_port 50000 "db2_federated"
    check_port 50001 "db2_remote"
elif command -v lsof &> /dev/null; then
    # macOS/Linux
    if ! lsof -i :50000 > /dev/null 2>&1; then
        print_success "Puerto 50000 disponible (db2_federated)"
    else
        print_warning "Puerto 50000 está en uso (db2_federated)"
    fi
    
    if ! lsof -i :50001 > /dev/null 2>&1; then
        print_success "Puerto 50001 disponible (db2_remote)"
    else
        print_warning "Puerto 50001 está en uso (db2_remote)"
    fi
elif command -v netstat &> /dev/null; then
    # Windows
    netstat -ano | grep -E ':50000|:50001' && print_warning "Algunos puertos pueden estar en uso"
    [ $? -ne 0 ] && print_success "Puertos 50000-50001 disponibles"
else
    print_info "No se pudo verificar puertos (instalar nc o lsof)"
fi

# ============================================================================
# Check 8: Docker Resources
# ============================================================================
print_header "8. Verificando recursos disponibles"

# Check available memory
if command -v free &> /dev/null; then
    MEM=$(free -g | awk '/^Mem:/ {print $2}')
    print_info "Memoria disponible: ${MEM}GB"
    if [ "$MEM" -lt 4 ]; then
        print_warning "Se recomienda mínimo 4GB de RAM (actualmente: ${MEM}GB)"
    else
        print_success "Memoria suficiente"
    fi
elif command -v vm_stat &> /dev/null; then
    # macOS
    MEM=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
    MEM_GB=$((MEM / 262144))
    print_info "Memoria disponible: ~${MEM_GB}GB"
fi

# ============================================================================
# Check 9: File Permissions
# ============================================================================
print_header "9. Verificando permisos de archivos"

if [ -x "setup.sh" ]; then
    print_success "setup.sh es ejecutable"
else
    print_warning "setup.sh no es ejecutable (ejecutar: chmod +x setup.sh)"
fi

if [ -w "data/" ]; then
    print_success "Directorio data/ es escribible"
else
    print_error "Directorio data/ no es escribible"
fi

if [ -w "scripts/" ]; then
    print_success "Directorio scripts/ es escribible"
else
    print_error "Directorio scripts/ no es escribible"
fi

# ============================================================================
# Check 10: Internet Connectivity
# ============================================================================
print_header "10. Verificando conectividad a Internet"

if curl -s --connect-timeout 5 https://docker.io > /dev/null; then
    print_success "Conectividad a Internet disponible"
else
    print_warning "No se pude acceder a docker.io (se necesitará para descargar imágenes)"
fi

# ============================================================================
# Final Summary
# ============================================================================
print_header "RESUMEN DE VERIFICACIÓN"

echo ""
echo "Errores encontrados: $ERRORS"
echo "Advertencias: $WARNINGS"
echo ""

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ Sistema listo para desplegar TASD-Federation${NC}"
    echo ""
    echo "Próximos pasos:"
    echo "  1. chmod +x setup.sh"
    echo "  2. docker-compose up -d"
    echo "  3. ./setup.sh"
    exit 0
else
    echo -e "${RED}✗ Se encontraron $ERRORS error(es) que deben ser corregidos${NC}"
    echo ""
    echo "Revisar los errores anteriores e intentar nuevamente"
    exit 1
fi
