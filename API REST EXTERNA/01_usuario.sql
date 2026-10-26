-- =====================================================================
-- 01_usuario.sql
-- Ejecutar como: ADMIN
-- Crea el usuario del proyecto, concede privilegios y habilita ORDS.
-- Sustituye <TU_CLAVE> por una contraseña segura (no la subas a GitHub).
-- =====================================================================

CREATE USER api_demo IDENTIFIED BY "<TU_CLAVE>";

GRANT CREATE SESSION   TO api_demo;
GRANT CREATE TABLE     TO api_demo;
GRANT CREATE SEQUENCE  TO api_demo;
GRANT CREATE PROCEDURE TO api_demo;
GRANT CREATE JOB       TO api_demo;

ALTER USER api_demo QUOTA UNLIMITED ON data;

-- Necesarios para consumir la API desde PL/SQL
GRANT EXECUTE ON DBMS_CLOUD TO api_demo;
GRANT EXECUTE ON UTL_HTTP   TO api_demo;

-- Habilitar el esquema para REST: las URLs empezarán por /ords/demo/
-- El alias debe ser único por esquema. Si 'demo' ya está en uso, elige otro
-- (comprueba con: SELECT parsing_schema, pattern FROM dba_ords_schemas;)
BEGIN
  ORDS_ADMIN.ENABLE_SCHEMA(
    p_enabled             => TRUE,
    p_schema              => 'API_DEMO',
    p_url_mapping_type    => 'BASE_PATH',
    p_url_mapping_pattern => 'demo',
    p_auto_rest_auth      => TRUE);
  COMMIT;
END;
/

-- Permitir que la base de datos salga a internet (ACL)
-- Oracle bloquea las llamadas de red por defecto. Como usuario ADMIN, da permiso a tu esquema:
BEGIN
  DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
    host => 'jsonplaceholder.typicode.com',
    lower_port => 443,
    upper_port => 443,
    ace  => XS$ACE_TYPE(
              privilege_list => XS$NAME_LIST('http'),
              principal_name => 'api_demo',
              principal_type => XS_ACL.PTYPE_DB));
END;
/
