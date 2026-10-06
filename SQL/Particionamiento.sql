# GENERAL

# Mejora del rendimiento: Las consultas con cláusulas WHERE que incluyen la columna de partición solo leen las particiones necesarias y omiten el resto.
# Mantenimiento más fácil: Puedes hacer operaciones como limpieza de datos antiguos mediante Partition Drop (ALTER TABLE ventas DROP PARTITION p_2024;) en segundos, en lugar de borrar millones de filas con un DELETE.
# Disponibilidad: Si una partición falla o se corrompe, las demás particiones de la tabla siguen operativas.

# INDICES
#    LOCALES:
#       Ambito:     Limitado a su propia partición.
#       Ventaja:    Fácil mantenimiento. Si borras una partición, el índice de esa partición se va con ella sin afectar a los demás.
#       Desventaja: Las consultas que no usan la clave de partición deben escanear todos los sub-índices.
#    GLOBALES:
#       Ambito:     Cubre toda la tabla.
#       Ventaja:    Acceso ultra rápido mediante claves primarias únicas (ID), sin importar la partición.
#       Desventaja: Si se altera o elimina una partición de la tabla, el índice global se rompe (UNUSABLE) y debe reconstruirse.


####################################
# Particionamiento por Rango (Range)
####################################
# Divide los datos basándose en un rango de valores de una columna (muy común para fechas).

-- 1. Eliminar la tabla previa para limpiar el entorno
DROP TABLE facturas CASCADE CONSTRAINTS;

-- 2. Crear la tabla particionada por Rango (Fechas)
CREATE TABLE facturas (
    id_factura NUMBER,
    fecha_emision DATE,
    cliente_id NUMBER,
    total NUMBER(10,2)
)
PARTITION BY RANGE (fecha_emision) (
    PARTITION p_2024    VALUES LESS THAN (TO_DATE('2025-01-01', 'YYYY-MM-DD')), -- <- POCOS REGISTROS
    PARTITION p_2025    VALUES LESS THAN (TO_DATE('2026-01-01', 'YYYY-MM-DD')),
    PARTITION p_2026    VALUES LESS THAN (TO_DATE('2027-01-01', 'YYYY-MM-DD')),
    PARTITION p_futuro  VALUES LESS THAN (MAXVALUE)
);

-- 3. Crear los Índices (Local y Global)
CREATE INDEX idx_facturas_fecha_local ON facturas(fecha_emision) LOCAL;
CREATE INDEX idx_facturas_id_global ON facturas(id_factura) GLOBAL;

-- 4. Inserción Masiva Asimétrica (100.000 registros)
INSERT /*+ APPEND */ INTO facturas (id_factura, fecha_emision, cliente_id, total)
SELECT 
    LEVEL AS id_factura,
    CASE 
        -- Solo 1 de cada 1800 filas pertenecerá al año 2024 (aprox. 55 filas en total)
        WHEN MOD(LEVEL, 1800) = 0 THEN 
            TO_DATE('2024-01-01', 'YYYY-MM-DD') + DBMS_RANDOM.VALUE(0, 364)
        -- El resto se divide de forma equitativa entre 2025 y 2026
        WHEN MOD(LEVEL, 2) = 0 THEN 
            TO_DATE('2025-01-01', 'YYYY-MM-DD') + DBMS_RANDOM.VALUE(0, 364)
        ELSE 
            TO_DATE('2026-01-01', 'YYYY-MM-DD') + DBMS_RANDOM.VALUE(0, 278) -- Hasta la fecha actual de 2026
    END AS fecha_emision,
    TRUNC(DBMS_RANDOM.VALUE(100, 999)) AS cliente_id,
    ROUND(DBMS_RANDOM.VALUE(10, 5000), 2) AS total
FROM DUAL
CONNECT BY LEVEL <= 100000;

COMMIT;

-- 5. Generación Forzada de Estadísticas con granularidad completa (Crucial)
EXEC DBMS_STATS.GATHER_TABLE_STATS(OWNNAME => 'HR', TABNAME => 'FACTURAS', GRANULARITY => 'ALL', CASCADE => TRUE);

-- 6. Comprobamos las particiones de tabla e indice
SELECT partition_position, partition_name, num_rows, blocks, last_analyzed, high_value 
FROM user_tab_partitions 
WHERE table_name = 'FACTURAS';

SELECT index_name, partition_name, num_rows, blevel, last_analyzed
FROM user_ind_partitions
WHERE index_name = 'IDX_FACTURAS_FECHA_LOCAL';

-- 7. Comprobamos que va por particion en el explain plan
	
	-- Aunque el plan de ejecucion muestre un FULL, si Pstart y  Pstop muestran el numero de particion que corresponde esta funcionando correctamente.

	-- Particion 1
	EXPLAIN PLAN FOR
	SELECT * FROM facturas 
	WHERE fecha_emision >= TO_DATE('2024-05-01', 'YYYY-MM-DD')
	  AND fecha_emision <  TO_DATE('2024-06-01', 'YYYY-MM-DD');

	SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY); -- muestra Pstart 1 y Pstop 1 (coge la particion 1)

	-- particion 2
	EXPLAIN PLAN FOR
	SELECT * FROM facturas 
	WHERE fecha_emision >= TO_DATE('2025-05-09', 'YYYY-MM-DD')
	  AND fecha_emision <  TO_DATE('2025-06-09', 'YYYY-MM-DD');

	SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY); -- muestra Pstart 2 y Pstop 2 (coge la particion 2)

	-- particion 3
	EXPLAIN PLAN FOR
	SELECT * FROM facturas 
	WHERE fecha_emision >= TO_DATE('2026-05-09', 'YYYY-MM-DD')
	  AND fecha_emision <  TO_DATE('2026-06-09', 'YYYY-MM-DD');

	SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY); -- muestra Pstart 3 y Pstop 3 (coge la particion 3)

####################################
# Particionamiento por Lista (List)
####################################
# Agrupa los datos basándose en una lista explícita de valores discretos (por ejemplo, regiones o países).

-- 1. Crear Tabla y habilitar Row Movement
CREATE TABLE pedidos_region (
    id_pedido NUMBER,
    region VARCHAR2(20),
    estado VARCHAR2(20),
    monto NUMBER
)
PARTITION BY LIST (region) (
    PARTITION p_norte VALUES ('CANTABRIA', 'GALICIA', 'PAIS_VASCO'),
    PARTITION p_sur   VALUES ('ANDALUCIA', 'MURCIA'),
    PARTITION p_resto VALUES (DEFAULT)
);

ALTER TABLE pedidos_region ENABLE ROW MOVEMENT; -- Permite que un registro cambie de particion automaticamente si se cambia la clave

-- 2. Crear Índices
CREATE INDEX idx_pedidos_reg_local ON pedidos_region(region) LOCAL;
CREATE INDEX idx_pedidos_est_global ON pedidos_region(estado) GLOBAL;

-- 3. Inserción Masiva de 100.000 Registros
INSERT /*+ APPEND */ INTO pedidos_region (id_pedido, region, estado, monto)
SELECT 
    LEVEL AS id_pedido,
    -- Elige una región aleatoria de un listado que incluye valores de DEFAULT (ej: MADRID)
    DECODE(TRUNC(DBMS_RANDOM.VALUE(1, 7)), 
           1, 'CANTABRIA', 2, 'GALICIA', 3, 'PAIS_VASCO', 
           4, 'ANDALUCIA', 5, 'MURCIA', 6, 'MADRID') AS region,
    -- Elige un estado aleatorio
    DECODE(TRUNC(DBMS_RANDOM.VALUE(1, 4)), 1, 'ENTREGADO', 2, 'PENDIENTE', 3, 'PROCESANDO') AS estado,
    TRUNC(DBMS_RANDOM.VALUE(50, 10000)) AS monto
FROM DUAL
CONNECT BY LEVEL <= 100000;

COMMIT;

-- 4.Estadisticas
EXEC DBMS_STATS.GATHER_TABLE_STATS(ownname => 'HR',tabname => 'PEDIDOS_REGION', granularity  => 'ALL', cascade => TRUE, no_invalidate => FALSE)

SELECT partition_position, partition_name, num_rows, blocks, last_analyzed, high_value 
FROM user_tab_partitions 
WHERE table_name = 'PEDIDOS_REGION';

SELECT index_name, partition_name, num_rows, blevel, last_analyzed
FROM user_ind_partitions
WHERE index_name = 'IDX_PEDIDOS_REG_LOCAL';

-- 5.- Chequeamos que funciona el particionamiento

	-- Particion 1
	EXPLAIN PLAN FOR
	SELECT * FROM pedidos_region
	WHERE region = 'MURCIA'
	 
	SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

	-- particion 2
	EXPLAIN PLAN FOR
	SELECT * FROM pedidos_region
	WHERE region = 'GALICIA'

	SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

	-- particion 3
	EXPLAIN PLAN FOR
	SELECT * FROM pedidos_region
	WHERE region = 'MADRID'

	SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

####################################
# Particionamiento por Hash (Hash)
####################################
# Distribuye las filas de manera uniforme entre un número determinado de particiones usando una función hash interna. Es útil para evitar cuellos de botella en I/O.

-- 1. Crear Tabla
CREATE TABLE sesiones_web (
    id_sesion NUMBER,
    usuario_id NUMBER,
    ip_origen VARCHAR2(45),
    fecha_conexion TIMESTAMP
)
PARTITION BY HASH (id_sesion)
PARTITIONS 4;

-- 2. Crear Índices
CREATE INDEX idx_sesiones_usr_local ON sesiones_web(usuario_id) LOCAL;
CREATE INDEX idx_sesiones_hash_global ON sesiones_web(id_sesion) GLOBAL;

-- 3. Inserción Masiva de 100.000 Registros
INSERT /*+ APPEND */ INTO sesiones_web (id_sesion, usuario_id, ip_origen, fecha_conexion)
SELECT 
    LEVEL AS id_sesion,
    TRUNC(DBMS_RANDOM.VALUE(1, 5000)) AS usuario_id,
    -- Genera IPs ficticias aleatorias
    '192.168.' || TRUNC(DBMS_RANDOM.VALUE(1, 254)) || '.' || TRUNC(DBMS_RANDOM.VALUE(1, 254)) AS ip_origen,
    SYSTIMESTAMP - DBMS_RANDOM.VALUE(0, 30) AS fecha_conexion -- Conexiones de los últimos 30 días
FROM DUAL
CONNECT BY LEVEL <= 100000;

COMMIT;

-- 4. Estadisticas
EXEC DBMS_STATS.GATHER_TABLE_STATS(ownname => 'HR',tabname => 'SESIONES_WEB', granularity  => 'ALL', cascade => TRUE, no_invalidate => FALSE)

SELECT partition_position, partition_name, num_rows, blocks, last_analyzed, high_value 
FROM user_tab_partitions 
WHERE table_name = 'SESIONES_WEB';

SELECT index_name, partition_name, num_rows, blevel, last_analyzed
FROM user_ind_partitions
WHERE index_name = 'IDX_SESIONES_USR_LOCAL';

-- 5.Chequeamos explain plan
EXPLAIN PLAN FOR
SELECT * FROM sesiones_web
WHERE id_sesion = 8533
 
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);


#############################################
# Particionamiento por Intervalos (Interval)
#############################################
# Es una extensión del particionamiento por rango introducida en Oracle 11g. Oracle crea automáticamente nuevas particiones cuando se insertan datos que superan el rango existente.

-- 1. Crear Tabla
CREATE TABLE logs_sistema (
    id_log NUMBER,
    componente VARCHAR2(50),
    mensaje VARCHAR2(4000),
    fecha_registro DATE
)
PARTITION BY RANGE (fecha_registro)
INTERVAL (NUMTODSINTERVAL(1, 'DAY'))
(
    PARTITION p_base VALUES LESS THAN (TO_DATE('2026-10-01', 'YYYY-MM-DD'))
);

-- 2. Crear Índices
CREATE INDEX idx_logs_fecha_local ON logs_sistema(fecha_registro) LOCAL;
CREATE INDEX idx_logs_comp_global ON logs_sistema(componente) GLOBAL;

-- 3. Inserción Masiva de 100.000 Registros
INSERT /*+ APPEND */ INTO logs_sistema (id_log, componente, mensaje, fecha_registro)
SELECT 
    LEVEL AS id_log,
    DECODE(TRUNC(DBMS_RANDOM.VALUE(1, 4)), 1, 'DB', 2, 'WEB', 3, 'API') AS componente,
    'Mensaje de log automatizado número ' || LEVEL AS mensaje,
    -- Genera fechas aleatorias que se extienden desde antes de la partición base hasta meses después
    TO_DATE('2026-09-01', 'YYYY-MM-DD') + DBMS_RANDOM.VALUE(0, 90) AS fecha_registro
FROM DUAL
CONNECT BY LEVEL <= 100000;

COMMIT;

-- 4. Estadisticas
EXEC DBMS_STATS.GATHER_TABLE_STATS(ownname => 'HR',tabname => 'LOGS_SISTEMA', granularity  => 'ALL', cascade => TRUE, no_invalidate => FALSE)

SELECT partition_position, partition_name, num_rows, blocks, last_analyzed, high_value 
FROM user_tab_partitions 
WHERE table_name = 'LOGS_SISTEMA'
order by 1

SELECT index_name, partition_name, num_rows, blevel, last_analyzed
FROM user_ind_partitions
WHERE index_name = 'IDX_LOGS_FECHA_LOCAL';

-- 5. Explain plan chequear uso particiones

EXPLAIN PLAN FOR
SELECT * FROM logs_sistema
WHERE fecha_registro = TO_DATE('2026-11-08', 'YYYY-MM-DD')
 
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);










