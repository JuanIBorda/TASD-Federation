# ============================================================================
# verify.ps1
# Script de verificación previa al despliegue (Windows PowerShell)
# Ejecutar: .\verify.ps1
# ============================================================================

$ErrorActionPreference = "Continue"

# Colores
$Colors = @{
    Success = [ConsoleColor]::Green
    Error   = [ConsoleColor]::Red
    Warning = [ConsoleColor]::Yellow
    Info    = [ConsoleColor]::Cyan
    Header  = [ConsoleColor]::Blue
}

$Errors = 0
$Warnings = 0

function Write-Header {
    param([string]$Text)
    Write-Host "================================================" -ForegroundColor $Colors.Header
    Write-Host $Text -ForegroundColor $Colors.Header
    Write-Host "================================================" -ForegroundColor $Colors.Header
}

function Write-Success {
    param([string]$Text)
    Write-Host "[✓] $Text" -ForegroundColor $Colors.Success
}

function Write-Error-Custom {
    param([string]$Text)
    Write-Host "[✗] $Text" -ForegroundColor $Colors.Error
    $script:Errors++
}

function Write-Warning-Custom {
    param([string]$Text)
    Write-Host "[!] $Text" -ForegroundColor $Colors.Warning
    $script:Warnings++
}

function Write-Info {
    param([string]$Text)
    Write-Host "[i] $Text" -ForegroundColor $Colors.Info
}

# ============================================================================
# Check 1: Docker Installation
# ============================================================================
Write-Header "1. Verificando instalación de Docker"

try {
    $dockerVersion = & docker --version
    Write-Success "Docker instalado: $dockerVersion"
} catch {
    Write-Error-Custom "Docker no está instalado"
    Write-Info "Descargar desde: https://www.docker.com/products/docker-desktop"
}

# ============================================================================
# Check 2: Docker Compose Installation
# ============================================================================
Write-Header "2. Verificando Docker Compose"

try {
    $composeVersion = & docker compose version 2>$null
    if ($?) {
        Write-Success "Docker Compose v2 disponible"
        $COMPOSE_CMD = "docker compose"
    } else {
        throw "Docker Compose v2 not found"
    }
} catch {
    try {
        $composeVersion = & docker-compose --version
        Write-Success "Docker Compose instalado: $composeVersion"
        $COMPOSE_CMD = "docker-compose"
    } catch {
        Write-Error-Custom "Docker Compose no está instalado"
        Write-Info "Requiere Docker Compose v1.27+ o Docker Desktop con Compose v2"
    }
}

# ============================================================================
# Check 3: Docker Daemon Status
# ============================================================================
Write-Header "3. Verificando daemon de Docker"

try {
    & docker ps > $null 2>&1
    if ($?) {
        Write-Success "Docker daemon está corriendo"
    } else {
        throw "Docker not running"
    }
} catch {
    Write-Error-Custom "Docker daemon no está corriendo"
    Write-Info "Abrir Docker Desktop desde el menú Inicio"
}

# ============================================================================
# Check 4: Architecture Compatibility
# ============================================================================
Write-Header "4. Verificando arquitectura"

$arch = [System.Environment]::Is64BitProcess ? "x86_64" : "x86"
if ($arch -eq "x86_64") {
    Write-Success "Arquitectura x86_64 (compatible)"
} else {
    Write-Warning-Custom "Arquitectura x86 (puede tener limitaciones)"
}

# ============================================================================
# Check 5: File Structure
# ============================================================================
Write-Header "5. Verificando estructura de archivos"

$files = @(
    "README.md",
    "docker-compose.yml",
    "setup.bat",
    "setup.sh",
    "scripts/init_federation.sql",
    "scripts/init_sample_db.sql",
    "data/file_clientes2.txt"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Success "Existe: $file"
    } else {
        Write-Error-Custom "Falta: $file"
    }
}

# ============================================================================
# Check 6: Docker Compose Syntax
# ============================================================================
Write-Header "6. Validando sintaxis de docker-compose.yml"

try {
    & $COMPOSE_CMD config > $null 2>&1
    if ($?) {
        Write-Success "docker-compose.yml es válido"
    } else {
        throw "Invalid compose file"
    }
} catch {
    Write-Error-Custom "docker-compose.yml tiene errores de sintaxis"
}

# ============================================================================
# Check 7: Available Ports
# ============================================================================
Write-Header "7. Verificando puertos disponibles"

function Test-Port {
    param([int]$Port, [string]$Name)
    
    try {
        $connection = New-Object System.Net.Sockets.TcpClient("127.0.0.1", $Port)
        $connection.Close()
        Write-Warning-Custom "Puerto $Port está en uso ($Name)"
    } catch {
        Write-Success "Puerto $Port disponible ($Name)"
    }
}

Test-Port 50000 "db2_federated"
Test-Port 50001 "db2_remote"

# ============================================================================
# Check 8: Docker Resources
# ============================================================================
Write-Header "8. Verificando recursos disponibles"

$computerInfo = Get-ComputerInfo
$totalMemory = $computerInfo.CsTotalPhysicalMemory / 1GB
$freeMemory = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB / 1024

Write-Info "Memoria total: $([math]::Round($totalMemory, 2)) GB"
Write-Info "Memoria libre: $([math]::Round($freeMemory, 2)) GB"

if ($totalMemory -lt 4) {
    Write-Warning-Custom "Se recomienda mínimo 4GB de RAM (actualmente: $([math]::Round($totalMemory, 2))GB)"
} else {
    Write-Success "Memoria suficiente"
}

# ============================================================================
# Check 9: File Permissions
# ============================================================================
Write-Header "9. Verificando permisos de archivos"

$dirs = @("data", "scripts")
foreach ($dir in $dirs) {
    if (Test-Path $dir) {
        try {
            $testFile = Join-Path $dir ".write-test"
            "test" > $testFile
            Remove-Item $testFile
            Write-Success "Directorio $dir es escribible"
        } catch {
            Write-Error-Custom "Directorio $dir no es escribible"
        }
    }
}

# ============================================================================
# Check 10: Internet Connectivity
# ============================================================================
Write-Header "10. Verificando conectividad a Internet"

try {
    $response = Invoke-WebRequest -Uri "https://docker.io" -TimeoutSec 5 -UseBasicParsing
    Write-Success "Conectividad a Internet disponible"
} catch {
    Write-Warning-Custom "No se puede acceder a docker.io (se necesitará para descargar imágenes)"
}

# ============================================================================
# Final Summary
# ============================================================================
Write-Header "RESUMEN DE VERIFICACIÓN"

Write-Host ""
Write-Host "Errores encontrados: $Errors" -ForegroundColor $(if ($Errors -eq 0) { $Colors.Success } else { $Colors.Error })
Write-Host "Advertencias: $Warnings" -ForegroundColor $(if ($Warnings -eq 0) { $Colors.Success } else { $Colors.Warning })
Write-Host ""

if ($Errors -eq 0) {
    Write-Host "✓ Sistema listo para desplegar TASD-Federation" -ForegroundColor $Colors.Success
    Write-Host ""
    Write-Host "Próximos pasos:" -ForegroundColor $Colors.Header
    Write-Host "  1. docker-compose up -d"
    Write-Host "  2. .\setup.bat"
} else {
    Write-Host "✗ Se encontraron $Errors error(es) que deben ser corregidos" -ForegroundColor $Colors.Error
    Write-Host ""
    Write-Host "Revisar los errores anteriores e intentar nuevamente" -ForegroundColor $Colors.Warning
    exit 1
}

Write-Host ""
