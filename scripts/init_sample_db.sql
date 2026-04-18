-- ============================================================================
-- init_sample_db.sql
-- Script de Inicialización de Tablas en el Nodo Remoto (SAMPLE)
-- Se ejecuta en el contenedor db2_remote
-- ============================================================================

-- Conectar a SAMPLE
CONNECT TO SAMPLE;

-- Crear esquema si no existe
CREATE SCHEMA DB2INST1;

-- ============================================================================
-- Crear tabla DEPARTMENT
-- ============================================================================
CREATE TABLE DB2INST1.DEPARTMENT (
    DEPTNO CHAR(3) PRIMARY KEY,
    DEPTNAME VARCHAR(36) NOT NULL,
    MGRNO CHAR(6),
    ADMRDEPT CHAR(3)
);

-- Insertar datos de ejemplo
INSERT INTO DB2INST1.DEPARTMENT VALUES ('A00', 'SPICER', 'E10001', 'A00');
INSERT INTO DB2INST1.DEPARTMENT VALUES ('B01', 'PLANNING', 'E20001', 'A00');
INSERT INTO DB2INST1.DEPARTMENT VALUES ('C01', 'INFORMATION CENTER', 'E30001', 'A00');

-- ============================================================================
-- Crear tabla EMPLOYEE
-- ============================================================================
CREATE TABLE DB2INST1.EMPLOYEE (
    EMPNO CHAR(6) PRIMARY KEY,
    FIRSTNME VARCHAR(12) NOT NULL,
    MIDINIT CHAR(1),
    LASTNAME VARCHAR(15) NOT NULL,
    WORKDEPT CHAR(3),
    PHONENO CHAR(4),
    HIREDATE DATE,
    JOB CHAR(8),
    EDLEVEL SMALLINT,
    SEX CHAR(1),
    BIRTHDATE DATE,
    SALARY DECIMAL(9,2),
    BONUS DECIMAL(9,2),
    COMM DECIMAL(9,2)
);

-- Insertar datos de ejemplo
INSERT INTO DB2INST1.EMPLOYEE VALUES (
    'E10001', 'JOHN', 'D', 'SMITH', 'A00', '1234', '2018-01-15', 'MANAGER', 18, 'M', '1965-05-20', 85000.00, 5000.00, 0.00
);
INSERT INTO DB2INST1.EMPLOYEE VALUES (
    'E10002', 'MARIA', 'A', 'GARCIA', 'A00', '5678', '2019-08-22', 'ANALYST', 17, 'F', '1972-03-10', 75000.00, 4000.00, 0.00
);
INSERT INTO DB2INST1.EMPLOYEE VALUES (
    'E20001', 'CARLOS', 'M', 'LOPEZ', 'B01', '9012', '2020-03-30', 'ENGINEER', 16, 'M', '1980-07-15', 70000.00, 3500.00, 0.00
);

-- ============================================================================
-- Crear tabla PROJECT
-- ============================================================================
CREATE TABLE DB2INST1.PROJECT (
    PROJNO CHAR(6) PRIMARY KEY,
    PROJNAME VARCHAR(24) NOT NULL,
    DEPTNO CHAR(3),
    RESPEMP CHAR(6),
    PRSTDATE DATE,
    PRENDATE DATE,
    MAJPROJ CHAR(6)
);

-- Insertar datos de ejemplo
INSERT INTO DB2INST1.PROJECT VALUES (
    'AD3100', 'AUTOMATION', 'A00', 'E10001', '2021-01-01', '2023-12-31', NULL
);
INSERT INTO DB2INST1.PROJECT VALUES (
    'IF1000', 'INFRASTRUCTURE', 'B01', 'E20001', '2020-06-15', '2024-06-15', NULL
);
INSERT INTO DB2INST1.PROJECT VALUES (
    'IF2000', 'DATA MIGRATION', 'B01', 'E20001', '2022-01-01', '2025-12-31', 'IF1000'
);

-- ============================================================================
-- Crear índices para mejor rendimiento
-- ============================================================================
CREATE INDEX IDX_EMP_DEPT ON DB2INST1.EMPLOYEE(WORKDEPT);
CREATE INDEX IDX_PROJ_DEPT ON DB2INST1.PROJECT(DEPTNO);

-- ============================================================================
-- COMMIT y validación
-- ============================================================================
COMMIT;

-- Validar datos en las tablas
SELECT 'DEPARTMENT' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM DB2INST1.DEPARTMENT
UNION ALL
SELECT 'EMPLOYEE', COUNT(*) FROM DB2INST1.EMPLOYEE
UNION ALL
SELECT 'PROJECT', COUNT(*) FROM DB2INST1.PROJECT;

-- Fin del script
