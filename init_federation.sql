-- ============================================================================
-- init_federation.sql
-- Script de Inicialización de Federación DB2 LUW v11.5
-- TASD-Federation Laboratory
-- ============================================================================

-- 1. Activar la base de datos para federación
UPDATE DB CFG FOR BASETASD USING FEDERATED YES;

-- 2. Crear el wrapper DRDA para comunicación entre DB2 (si no existe)
CREATE WRAPPER DRDA LIBRARY '/opt/ibm/db2/V11.5/lib64/libdb2drda.so';

-- 3. Crear el servidor remoto DB2SERVERLOCAL que apunta al contenedor remoto
CREATE SERVER DB2SERVERLOCAL
  TYPE DB2/LUW
  VERSION '11.5'
  WRAPPER DRDA
  AUTHORIZATION "db2inst1"
  PASSWORD "db2inst1"
  OPTIONS (
    DBNAME 'SAMPLE',
    HOST 'db2_remote',
    PORT '50000',
    TCP_NODELAY 'Y'
  );

-- 4. Crear usuario local mapeado para autenticación en servidor remoto
CREATE USER MAPPING FOR DB2INST1
  SERVER DB2SERVERLOCAL
  OPTIONS (
    REMOTE_AUTHID 'db2inst1',
    REMOTE_PASSWORD 'db2inst1'
  );

-- ============================================================================
-- NICKNAMES (Alias de tablas remotas del nodo SAMPLE)
-- ============================================================================

-- Crear nicknames para tablas estándar del nodo remoto SAMPLE
CREATE NICKNAME db2Ldept
  FOR DB2SERVERLOCAL.DB2INST1.DEPARTMENT;

CREATE NICKNAME db2Lemp
  FOR DB2SERVERLOCAL.DB2INST1.EMPLOYEE;

CREATE NICKNAME db2Lproj
  FOR DB2SERVERLOCAL.DB2INST1.PROJECT;

-- ============================================================================
-- FLATWRAPPER - Non-Relational Wrapper para archivos CSV
-- (Comentado porque la libreria libdb2flat.so no está en esta imagen)
-- ============================================================================

/*
-- Crear el wrapper FLAT para archivos de texto
CREATE WRAPPER FLAT LIBRARY 'libdb2flat.so';

-- Crear el servidor local para acceso a archivos
CREATE SERVER FLATSERVER
  TYPE FLAT
  WRAPPER FLAT;

-- Crear nickname para el archivo de clientes (CSV)
CREATE NICKNAME FILECLIENTES2
  FOR FLATSERVER.DB2INST1.FILE_CLIENTES2
  OPTIONS (
    FILENAME '/var/db2/files/file_clientes2.txt',
    DELIMITER ',',
    QUOTEDVALUE '"'
  );
*/

-- ============================================================================
-- Validar la configuración de federación
-- ============================================================================

-- Listar servidores federados configurados
SELECT * FROM SYSCAT.SERVERS;

-- Listar wrappers disponibles
SELECT * FROM SYSCAT.WRAPPERS;

-- Listar nicknames configurados
SELECT * FROM SYSCAT.NICKTAB;

-- Fin del script
COMMIT;
