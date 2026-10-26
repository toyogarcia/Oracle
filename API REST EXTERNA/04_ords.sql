-- =====================================================================
-- 04_ords.sql
-- Ejecutar como: API_DEMO
-- Módulo público de solo lectura:
--   GET /ords/demo/posts/       -> lista paginada
--   GET /ords/demo/posts/:id    -> un registro
-- =====================================================================

BEGIN
  ORDS.DEFINE_MODULE(
    p_module_name    => 'posts',
    p_base_path      => '/posts/',
    p_items_per_page => 25,
    p_status         => 'PUBLISHED');

  ORDS.DEFINE_TEMPLATE(p_module_name => 'posts', p_pattern => '.');
  ORDS.DEFINE_HANDLER(
    p_module_name => 'posts',
    p_pattern     => '.',
    p_method      => 'GET',
    p_source_type => ORDS.SOURCE_TYPE_COLLECTION_FEED,
    p_source      => 'SELECT id, user_id, titulo, cuerpo FROM posts_api ORDER BY id');

  ORDS.DEFINE_TEMPLATE(p_module_name => 'posts', p_pattern => ':id');
  ORDS.DEFINE_HANDLER(
    p_module_name => 'posts',
    p_pattern     => ':id',
    p_method      => 'GET',
    p_source_type => ORDS.SOURCE_TYPE_COLLECTION_ITEM,
    p_source      => 'SELECT id, user_id, titulo, cuerpo FROM posts_api WHERE id = :id');

  COMMIT;
END;
/
