-- =====================================================================
-- SCRIPT 99 - LIMPIEZA: ELIMINAR TODO LO CREADO EN LA DEMO
-- =====================================================================
-- EJECUTAR COMO : ADMIN
-- CUIDADO       : Borra el usuario APIDEMO con TODOS sus objetos.
--                 Cierra antes cualquier sesión abierta como APIDEMO
--                 (Database Actions, SQL Developer...) o dará error.
-- =====================================================================

-- PASO 99.1 - Quitar el permiso de red (ACL)
BEGIN
  DBMS_NETWORK_ACL_ADMIN.REMOVE_HOST_ACE(
    host       => 'jsonplaceholder.typicode.com',
    lower_port => 443,
    upper_port => 443,
    ace        => xs$ace_type(privilege_list => xs$name_list('http'),
                              principal_name => 'APIDEMO',
                              principal_type => xs_acl.ptype_db));
  COMMIT;
END;
/

-- PASO 99.2 - Quitar la habilitación ORDS del esquema
BEGIN
  ORDS_ADMIN.ENABLE_SCHEMA(p_enabled => FALSE, p_schema => 'APIDEMO');
  COMMIT;
END;
/

-- PASO 99.3 - (Solo si hiciste el SCRIPT 03) borrar el wallet del directorio
-- BEGIN DBMS_CLOUD.DELETE_FILE(directory_name => 'DATA_PUMP_DIR', file_name => 'cwallet.sso'); END;
-- /

-- PASO 99.4 - Borrar el usuario y todo lo que contiene
DROP USER apidemo CASCADE;

-- PASO 99.5 - Comprobar
SELECT COUNT(*) AS usuarios_restantes FROM dba_users WHERE username = 'APIDEMO';
-- RESULTADO ESPERADO: 0
