-- =====================================================================
-- SCRIPT 14 - PROTEGER LA API CON OAUTH 2.0 (client_credentials)
-- =====================================================================
-- EJECUTAR COMO : APIDEMO
-- OBJETIVO      : Exigir un token de acceso para usar /productos/.
--
-- CÓMO FUNCIONA (en 3 conceptos):
--   ROL        : etiqueta de permisos ("rol_api_productos").
--   PRIVILEGIO : regla "para entrar en estas URLs hace falta el rol X".
--   CLIENTE    : "aplicación" (aquí, Postman) con client_id + client_secret
--                que intercambia sus credenciales por un token temporal.
-- =====================================================================

-- ---------------------------------------------------------------------
-- PASO 14.1 - Crear el rol
-- ---------------------------------------------------------------------
BEGIN
  ORDS.CREATE_ROLE(p_role_name => 'rol_api_productos');
  COMMIT;
END;
/

-- ---------------------------------------------------------------------
-- PASO 14.2 - Crear el privilegio y asociarlo a las URLs /productos/*
-- ---------------------------------------------------------------------
BEGIN
  ORDS.CREATE_PRIVILEGE(
    p_name        => 'priv_api_productos',
    p_role_name   => 'rol_api_productos',
    p_label       => 'Acceso API Productos',
    p_description => 'Permite usar el API REST de la tabla PRODUCTOS'
  );

  -- '/productos/*' = la colección y todo lo que cuelga de ella (/productos/1...)
  ORDS.CREATE_PRIVILEGE_MAPPING(
    p_privilege_name => 'priv_api_productos',
    p_pattern        => '/productos/*'
  );
  COMMIT;
END;
/

-- ---------------------------------------------------------------------
-- PASO 14.3 - Crear el cliente OAuth2 y darle el rol
-- ---------------------------------------------------------------------
BEGIN
  OAUTH.CREATE_CLIENT(
    p_name            => 'cliente_postman',
    p_grant_type      => 'client_credentials',   -- flujo máquina a máquina
    p_owner           => 'APIDEMO',
    p_description     => 'Cliente de prueba para Postman',
    p_support_email   => 'tu_correo@ejemplo.com', -- <-- cámbialo
    p_privilege_names => 'priv_api_productos'
  );

  OAUTH.GRANT_CLIENT_ROLE(
    p_client_name => 'cliente_postman',
    p_role_name   => 'rol_api_productos'
  );
  COMMIT;
END;
/

-- ---------------------------------------------------------------------
-- PASO 14.4 - Obtener client_id y client_secret
-- ---------------------------------------------------------------------
SELECT name, client_id, client_secret
  FROM user_ords_clients
 WHERE name = 'cliente_postman';
-- Copia CLIENT_ID y CLIENT_SECRET a las variables del entorno de Postman.
-- ¡NUNCA los subas a GitHub! Son equivalentes a una contraseña.

-- ---------------------------------------------------------------------
-- PASO 14.5 - PROBAR CON POSTMAN
-- ---------------------------------------------------------------------
--   Carpeta "2 - Con OAuth2 (script 14)":
--
--   a) "Obtener token"  -> POST {{ords_base}}/oauth/token
--        Authorization: Basic Auth (usuario = client_id, contraseña = client_secret)
--        Body x-www-form-urlencoded:  grant_type = client_credentials
--      Respuesta: {"access_token":"...","token_type":"bearer","expires_in":3600}
--      (El script de test de la petición guarda el token en la variable
--       access_token automáticamente.)
--
--   b) "GET lista (con token)"  -> 200
--   c) "POST crear (con token)" -> 201
--
--   Y para ver la protección: vuelve a lanzar los GET de la carpeta 1
--   (sin token). Ahora deben devolver 401 Unauthorized.
--
-- FIN DE LA PARTE 2.
