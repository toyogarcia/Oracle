-- =====================================================================
-- SCRIPT 02 - CONFIGURAR LA ACL (LISTA DE CONTROL DE ACCESO DE RED)
-- =====================================================================
-- EJECUTAR COMO : ADMIN
-- OBJETIVO      : Permitir que el usuario APIDEMO haga llamadas HTTPS
--                 al host de la API pública.
--
-- ¿QUÉ ES UNA ACL?
--   Por seguridad, Oracle BLOQUEA por defecto cualquier conexión de red
--   saliente desde PL/SQL. Una ACL es la "lista blanca" que indica:
--     - QUÉ usuario puede salir,
--     - A QUÉ host (y puerto),
--     - CON QUÉ privilegio (http, connect, resolve...).
--   Sin ACL, UTL_HTTP falla con:  ORA-24247: network access denied by ACL
--
-- API PÚBLICA USADA EN LA DEMO: JSONPlaceholder
--   https://jsonplaceholder.typicode.com  (gratuita, sin registro,
--   admite GET, POST, PUT y DELETE de forma "simulada").
-- =====================================================================

-- ---------------------------------------------------------------------
-- PASO 2.1 - Dar acceso a APIDEMO al host de la API (puerto 443 = HTTPS)
-- ---------------------------------------------------------------------
BEGIN
  DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
    host       => 'jsonplaceholder.typicode.com',
    lower_port => 443,
    upper_port => 443,
    ace        => xs$ace_type(
                    privilege_list => xs$name_list('http'),  -- 'http' cubre UTL_HTTP
                    principal_name => 'APIDEMO',             -- en MAYÚSCULAS
                    principal_type => xs_acl.ptype_db)       -- es un usuario de BD
  );
  COMMIT;
END;
/

-- ---------------------------------------------------------------------
-- PASO 2.2 - Verificar que la ACL quedó creada
-- ---------------------------------------------------------------------
COLUMN host      FORMAT A32
COLUMN principal FORMAT A12
COLUMN privilege FORMAT A10
SELECT host, lower_port, upper_port, principal, privilege, grant_type
  FROM dba_host_aces
 WHERE principal = 'APIDEMO';
-- RESULTADO ESPERADO: 1 fila con host jsonplaceholder.typicode.com,
-- puertos 443-443, privilegio HTTP y GRANT_TYPE = GRANT.

-- ---------------------------------------------------------------------
-- NOTAS
-- ---------------------------------------------------------------------
-- * Si mañana quieres consumir otra API (p. ej. api.ejemplo.com),
--   repite el PASO 2.1 cambiando el valor de HOST.
-- * Para HTTP sin cifrar usarías el puerto 80 (no recomendado).
-- * Para QUITAR el permiso, mira el script 99_limpieza.sql.
--
-- SIGUIENTE: SCRIPT 03 (wallet; es opcional en Autonomous Database).
