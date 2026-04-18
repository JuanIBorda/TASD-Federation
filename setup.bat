@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

REM ============================================================================
REM setup.bat
REM Script de inicialización de la federación DB2 en Docker (Windows PowerShell)
REM Uso: setup.bat
REM ============================================================================

setlocal enabledelayedexpansion
color 0A

echo ==========================================
echo TASD-Federation Docker Setup (Windows)
echo ==========================================
echo.

REM 1. Esperar a que los contenedores estén listos
echo [PARTE 1] Esperando a que los contenedores DB2 estén listos...
timeout /t 30 /nobreak

REM 2. Inicializar el nodo remoto (SAMPLE) con tablas y datos
echo.
echo [PARTE 2] Inicializando base de datos SAMPLE en db2_remote...

docker exec -i db2_remote bash -c "su - db2inst1 << 'EOF'"
db2 connect to SAMPLE
db2 -f /scripts/init_sample_db.sql
db2 connect reset
exit
"EOF"

if !errorlevel! equ 0 (
    echo [OK] Base de datos SAMPLE inicializada
) else (
    echo [ADVERTENCIA] Algunas operaciones pueden haber fallado en SAMPLE
)

REM 3. Inicializar federación en el nodo federador (BASETASD)
echo.
echo [PARTE 3] Inicializando federación en db2_federated...

docker exec -i db2_federated bash -c "su - db2inst1 << 'EOF'"
db2 connect to BASETASD
db2 -f /scripts/init_federation.sql
db2 connect reset
exit
"EOF"

if !errorlevel! equ 0 (
    echo [OK] Federación inicializada en BASETASD
) else (
    echo [ADVERTENCIA] Algunas operaciones pueden haber fallado en la federación
)

REM 4. Verificar estado de nicknames
echo.
echo [PARTE 4] Verificando nicknames creados...

docker exec -i db2_federated bash -c "su - db2inst1 << 'EOF'"
db2 connect to BASETASD
db2 'SELECT TABNAME FROM SYSCAT.NICKTAB' 2^>nul ^|^| echo "No se pudo verificar nicknames"
db2 connect reset
exit
"EOF"

REM 5. Prueba de conexión remota (opcional)
echo.
echo [PARTE 5] Prueba de federación...

docker exec -i db2_federated bash -c "su - db2inst1 << 'EOF'"
db2 connect to BASETASD
echo "Consultando DEPARTMENT del servidor remoto:"
db2 "SELECT * FROM db2Ldept FETCH FIRST 5 ROWS ONLY" 2^>nul ^|^| echo "Consulta de federación completada"
db2 connect reset
exit
"EOF"

echo [OK] Setup completado exitosamente
echo.
echo ==========================================
echo Próximos pasos:
echo ==========================================
echo 1. Conectarse al nodo federador:
echo    docker exec -it db2_federated bash
echo    su - db2inst1
echo    db2 connect to BASETASD
echo.
echo 2. Consultar datos federados:
echo    db2 "SELECT * FROM db2Lemp"
echo.
echo 3. Acceder al archivo plano del FLATWRAPPER:
echo    db2 "SELECT * FROM FILECLIENTES2"
echo.
echo Base de datos disponibles:
echo   - Nodo Federador: db2_federated ^(BASETASD^) puerto 50000
echo   - Nodo Remoto: db2_remote ^(SAMPLE^) puerto 50001
echo ==========================================

endlocal
