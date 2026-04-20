-- ============================================================================
-- init_federation.sql
-- ============================================================================

-- ============================================================================
-- MÉTODO ANTIGUO: Flat Wrapper (Non-Relational) - DB2 versión anterior
-- Este método usaba un WRAPPER de tipo FILE para acceder a archivos planos
-- como tablas federadas mediante un NICKNAME.
-- ============================================================================
-- DROP WRAPPER FILE;
-- DROP SERVER FILESERVER;
-- DROP NICKNAME FILECLIENTES2;
--
-- CREATE WRAPPER FILE LIBRARY '/opt/ibm/db2/V11.5/lib64/libdb2java.so';
--
-- CREATE SERVER FILESERVER
--   WRAPPER FILE
--   OPTIONS (
--     DBNAME '/var/db2/files'
--   );
--
-- CREATE NICKNAME FILECLIENTES2 FOR FILESERVER."file_clientes2.txt";
-- ============================================================================

CONNECT TO BASETASD

DROP NICKNAME db2Ldept;
DROP NICKNAME db2Lemp;
DROP NICKNAME db2Lproj;
DROP TABLE FILECLIENTES2; 
DROP USER MAPPING FOR DB2INST1 SERVER DB2SERVERLOCAL;
DROP SERVER DB2SERVERLOCAL;
DROP WRAPPER DRDA;

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

CREATE NICKNAME db2Ldept FOR DB2SERVERLOCAL.DB2INST1.DEPARTMENT;
CREATE NICKNAME db2Lemp   FOR DB2SERVERLOCAL.DB2INST1.EMPLOYEE;
CREATE NICKNAME db2Lproj  FOR DB2SERVERLOCAL.DB2INST1.PROJECT;

-- Definición de tabla con datos cargados desde archivo
CREATE TABLE FILECLIENTES2 (
    CODCLI INTEGER NOT NULL,
    NAMECLI VARCHAR(100),
    DEUDACLI INTEGER
);

LOAD FROM '/var/db2/files/file_clientes2.txt' OF DEL INSERT INTO FILECLIENTES2;

COMMIT;
TERMINATE;
