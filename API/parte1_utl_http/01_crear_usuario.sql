-- =====================================================================
-- SCRIPT 01 - CREAR EL USUARIO (ESQUEMA) DE LA DEMO
-- =====================================================================
-- EJECUTAR COMO : ADMIN  (Database Actions > SQL, o SQL Developer / SQLcl)
-- OBJETIVO      : Crear el usuario APIDEMO, que será el "dueño" de todo
--                 lo que construyamos (paquete PL/SQL, tabla, REST...).
-- CÓMO EJECUTAR : En Database Actions pulsa "Ejecutar script" (F5),
--                 NO "Ejecutar sentencia" (Ctrl+Enter), para lanzar todo.
-- =====================================================================

-- ---------------------------------------------------------------------
-- PASO 1.1 - Crear el usuario
-- ---------------------------------------------------------------------
-- IMPORTANTE: cambia la contraseña antes de ejecutar.
-- Reglas de Autonomous Database: 12-30 caracteres, con mayúscula,
-- minúscula y número, y sin comillas dobles ni el nombre del usuario.
CREATE USER apidemo IDENTIFIED BY "<TU_PASSWORD>"
  QUOTA UNLIMITED ON data;   -- DATA es el tablespace por defecto en ADB

-- ---------------------------------------------------------------------
-- PASO 1.2 - Dar permisos básicos (privilegios de sistema)
-- ---------------------------------------------------------------------
GRANT CREATE SESSION   TO apidemo;  -- poder conectarse
GRANT CREATE TABLE     TO apidemo;  -- crear tablas (parte 2)
GRANT CREATE VIEW      TO apidemo;  -- crear vistas
GRANT CREATE SEQUENCE  TO apidemo;  -- crear secuencias
GRANT CREATE PROCEDURE TO apidemo;  -- crear paquetes / procedimientos / funciones
GRANT CREATE TYPE      TO apidemo;  -- crear tipos PL/SQL de objeto

-- ---------------------------------------------------------------------
-- PASO 1.3 - Permiso para usar el paquete UTL_HTTP
-- ---------------------------------------------------------------------
-- UTL_HTTP es el paquete de Oracle para hacer peticiones HTTP/HTTPS
-- desde PL/SQL. En muchas bases ya es ejecutable por PUBLIC, pero lo
-- concedemos explícitamente para que quede documentado.
GRANT EXECUTE ON SYS.UTL_HTTP TO apidemo;

-- ---------------------------------------------------------------------
-- PASO 1.4 - Habilitar el esquema para entrar a Database Actions
-- ---------------------------------------------------------------------
-- Para conectarte como APIDEMO desde el navegador (Database Actions)
-- el esquema debe estar "habilitado para ORDS". Lo hacemos aquí con
-- ORDS_ADMIN (solo ADMIN puede) y en el SCRIPT 12 lo explicaremos
-- en detalle.
BEGIN
  ORDS_ADMIN.ENABLE_SCHEMA(
    p_enabled             => TRUE,
    p_schema              => 'APIDEMO',
    p_url_mapping_type    => 'BASE_PATH',
    p_url_mapping_pattern => 'apidemo',   -- aparecerá en la URL: /ords/apidemo/
    p_auto_rest_auth      => TRUE         -- TRUE = seguro por defecto
  );
  COMMIT;
END;
/

-- ---------------------------------------------------------------------
-- PASO 1.5 - Comprobar que el usuario existe
-- ---------------------------------------------------------------------
SELECT username, account_status, created
  FROM dba_users
 WHERE username = 'APIDEMO';
-- RESULTADO ESPERADO: 1 fila con ACCOUNT_STATUS = OPEN

-- ---------------------------------------------------------------------
-- PASO 1.6 - (Manual) Cómo conectarte como APIDEMO
-- ---------------------------------------------------------------------
-- Opción A (navegador): abre la URL de Database Actions de tu base de
--   datos, pero cambiando "admin" por "apidemo". Si la URL de ADMIN es
--     https://XXXX-MIBD.adb.REGION.oraclecloudapps.com/ords/admin/_sdw/?nav=worksheet
--   la de APIDEMO es
--     https://XXXX-MIBD.adb.REGION.oraclecloudapps.com/ords/apidemo/_sdw/?nav=worksheet
--   Inicia sesión con usuario APIDEMO y la contraseña del paso 1.1.
--   Consejo: usa una ventana de incógnito para no cerrar la sesión de ADMIN.
-- Opción B (SQL Developer / SQLcl): conexión normal con el wallet de ADB.
--
-- SIGUIENTE: SCRIPT 02 (como ADMIN).
