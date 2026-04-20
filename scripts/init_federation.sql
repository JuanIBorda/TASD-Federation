-- ============================================================================
-- init_federation.sql
-- Script de creación de objetos de federación
-- ============================================================================

-- Limpieza preventiva
DROP NICKNAME db2Ldept;
DROP NICKNAME db2Lemp;
DROP NICKNAME db2Lproj;
DROP TABLE FILECLIENTES2; 
DROP USER MAPPING FOR DB2INST1 SERVER DB2SERVERLOCAL;
DROP SERVER DB2SERVERLOCAL;
DROP WRAPPER DRDA;

-- Configuración de Wrapper y Server
CREATE WRAPPER DRDA LIBRARY '/opt/ibm/db2/V11.5/lib64/libdb2drda.so';

CREATE SERVER DB2SERVERLOCAL
  TYPE DB2/LUW
  VERSION '11.5'
  WRAPPER DRDA
  AUTHORIZATION "db2inst1"
  PASSWORD "db2inst1"
  OPTIONS ( DBNAME 'SAMPLE', HOST 'db2_remote', PORT '50000' );

CREATE USER MAPPING FOR DB2INST1 SERVER DB2SERVERLOCAL
  OPTIONS ( REMOTE_AUTHID 'db2inst1', REMOTE_PASSWORD 'db2inst1' );

-- Nicknames para base SAMPLE remota
CREATE NICKNAME db2Ldept FOR DB2SERVERLOCAL.DB2INST1.DEPARTMENT;
CREATE NICKNAME db2Lemp   FOR DB2SERVERLOCAL.DB2INST1.EMPLOYEE;
CREATE NICKNAME db2Lproj  FOR DB2SERVERLOCAL.DB2INST1.PROJECT;

-- Tabla para archivo plano local
CREATE TABLE FILECLIENTES2 (
    CODCLI INTEGER NOT NULL,
    NAMECLI VARCHAR(100),
    DEUDACLI INTEGER
);

COMMIT;
TERMINATE;
