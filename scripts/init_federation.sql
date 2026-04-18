-- ============================================================================
-- init_federation.sql
-- Script de Inicialización de Federación DB2 LUW v11.5
-- TASD-Federation Laboratory
-- ============================================================================

-- 1. Aktivicar la base de datos para federación
UPDATE DB CFG USING FEDERATED YES;

-- 2. Crear el wrapper DRDA para comunicación entre DB2
CREATE WRAPPER DRDA;

-- 3. Crear el servidor remoto DB2SERVER_LOCAL que apunta al contenedor remoto
-- Este comando se ejecuta en el nodo federador (db2_federated)
-- Comunicación con db2_remote (contenedor remoto en puerto 50000 dentro de la network)
CREATE SERVER DB2SERVERLOCAL
  TYPE DB2/LUW
  VERSION '11.5'
  WRAPPER DRDA
  OPTIONS (
    DBNAME 'SAMPLE',
    HOSTNAME 'db2_remote',
    PORT '50000',
    PARAMETER '1',
    TIMEOUT '30'
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
-- ============================================================================

-- Crear el wrapper FLAT para archivos de texto
CREATE WRAPPER FLAT;

-- Crear el servidor local para acceso a archivos
CREATE SERVER FLATSERVER
  TYPE FLAT
  WRAPPER FLAT;

-- Crear nickname para el archivo de clientes (CSV)
CREATE NICKNAME FILECLIENTES2
  FOR FLATSERVER.DB2INST1.'file_clientes2.txt'
  OPTIONS (
    REMOTE_SCHEMA '/var/db2/files',
    REMOTE_FILENAME 'file_clientes2.txt',
    RECORD_SEPARATOR '0x0A',
    FIELD_SEPARATOR ',',
    QUOTE_CHAR '"'
  );

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
