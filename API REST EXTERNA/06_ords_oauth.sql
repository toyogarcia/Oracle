-- =====================================================================
-- 06_ords_oauth.sql
-- Ejecutar como: API_DEMO
-- Módulo de escritura protegido con OAuth2 (client credentials):
--   POST   /ords/demo/admin/posts/
--   PUT    /ords/demo/admin/posts/:id
--   DELETE /ords/demo/admin/posts/:id
-- =====================================================================

-- 1) Rol, privilegio y módulo con sus handlers
BEGIN
  ORDS.CREATE_ROLE(p_role_name => 'posts_writer');

  ORDS.CREATE_PRIVILEGE(
    p_name        => 'posts_write_priv',
    p_role_name   => 'posts_writer',
    p_label       => 'Escritura de posts',
    p_description => 'Permite crear, modificar y borrar posts');

  ORDS.CREATE_PRIVILEGE_MAPPING(
    p_privilege_name => 'posts_write_priv',
    p_pattern        => '/admin/posts/*');

  ORDS.DEFINE_MODULE(
    p_module_name => 'posts_admin',
    p_base_path   => '/admin/posts/',
    p_status      => 'PUBLISHED');

  -- POST: crear
  ORDS.DEFINE_TEMPLATE(p_module_name => 'posts_admin', p_pattern => '.');
  ORDS.DEFINE_HANDLER(
    p_module_name => 'posts_admin',
    p_pattern     => '.',
    p_method      => 'POST',
    p_source_type => ORDS.SOURCE_TYPE_PLSQL,
    p_source      => 'BEGIN
      :new_id := posts_seq.NEXTVAL;
      INSERT INTO posts_api (id, user_id, titulo, cuerpo)
      VALUES (:new_id, :user_id, :titulo, :cuerpo);
      :status_code := 201;
    END;');
  ORDS.DEFINE_PARAMETER(
    p_module_name        => 'posts_admin',
    p_pattern            => '.',
    p_method             => 'POST',
    p_name               => 'new_id',
    p_bind_variable_name => 'new_id',
    p_source_type        => 'RESPONSE',
    p_param_type         => 'INT',
    p_access_method      => 'OUT');

  -- PUT: modificar
  ORDS.DEFINE_TEMPLATE(p_module_name => 'posts_admin', p_pattern => ':id');
  ORDS.DEFINE_HANDLER(
    p_module_name => 'posts_admin',
    p_pattern     => ':id',
    p_method      => 'PUT',
    p_source_type => ORDS.SOURCE_TYPE_PLSQL,
    p_source      => 'BEGIN
      UPDATE posts_api
      SET    user_id = :user_id, titulo = :titulo, cuerpo = :cuerpo
      WHERE  id = :id;
      :status_code := CASE WHEN SQL%ROWCOUNT = 0 THEN 404 ELSE 200 END;
    END;');

  -- DELETE: borrar
  ORDS.DEFINE_HANDLER(
    p_module_name => 'posts_admin',
    p_pattern     => ':id',
    p_method      => 'DELETE',
    p_source_type => ORDS.SOURCE_TYPE_PLSQL,
    p_source      => 'BEGIN
      DELETE FROM posts_api WHERE id = :id;
      :status_code := CASE WHEN SQL%ROWCOUNT = 0 THEN 404 ELSE 204 END;
    END;');

  COMMIT;
END;
/

-- 2) Cliente OAuth2 (cambia el correo por uno tuyo)
BEGIN
  OAUTH.CREATE_CLIENT(
    p_name            => 'posts_cliente',
    p_grant_type      => 'client_credentials',
    p_owner           => 'API_DEMO',
    p_description     => 'Cliente para escritura de posts',
    p_support_email   => 'tu_correo@ejemplo.com',
    p_privilege_names => 'posts_write_priv');

  OAUTH.GRANT_CLIENT_ROLE(
    p_client_name => 'posts_cliente',
    p_role_name   => 'posts_writer');

  COMMIT;
END;
/

-- 3) Obtener credenciales. Guárdalas en un lugar seguro: NO las subas a GitHub
--    ni dejes esta salida en capturas del repositorio.
SELECT client_id, client_secret
FROM   user_ords_clients
WHERE  name = 'posts_cliente';
