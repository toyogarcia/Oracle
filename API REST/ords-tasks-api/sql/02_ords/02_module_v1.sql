--------------------------------------------------------------------------------
-- 02_module_v1.sql
-- Modulo REST a medida: tasks.v1  (base path /v1/)
-- Ejecutar como TASKS_DEV. Re-ejecutable: DEFINE_MODULE reemplaza el modulo.
--
-- Contrato:
--   GET    /v1/tasks/            Lista paginada. Filtro opcional ?status=TODO
--   POST   /v1/tasks/            Crea tarea. title obligatorio -> 201 | 400
--   GET    /v1/tasks/:id         Detalle de una tarea
--   PUT    /v1/tasks/:id         Actualizacion parcial -> 204 | 404 | 400
--   DELETE /v1/tasks/:id         Borra tarea -> 204 | 404
--
-- Notas de diseno:
--   * Los atributos del JSON llegan como binds implicitos (:title, :status...).
--   * due_date va en formato YYYY-MM-DD.
--   * En el PUT, un atributo ausente significa "no tocar" (NVL), por lo que
--     no se puede poner un campo a NULL desde la API (semantica tipo PATCH).
--   * status se valida a mano para devolver 400 en lugar de un error 555.
--------------------------------------------------------------------------------

BEGIN
  -- crea o reemplaza un módulo de servicios REST dentro de la base de datos.
  ORDS.DEFINE_MODULE(
    p_module_name    => 'tasks.v1',
    p_base_path      => '/v1/',
    p_items_per_page => 25,
    p_status         => 'PUBLISHED');

  ----------------------------------------------------------------
  -- Coleccion: /v1/tasks/
  ----------------------------------------------------------------
  -- define o crea una plantilla de recurso (resource template) de una URL dentro de un módulo de servicios RESTful en (ORDS)
  ORDS.DEFINE_TEMPLATE(
    p_module_name => 'tasks.v1',
    p_pattern     => 'tasks/');

	-- crear o reemplazar manejadores (handlers) de una petición HTTP asociada a una plantilla de recurso y a un módulo REST específico

  -- GET /v1/tasks/
  ORDS.DEFINE_HANDLER(
    p_module_name => 'tasks.v1',
    p_pattern     => 'tasks/',
    p_method      => 'GET',
    p_source_type => ORDS.source_type_collection_feed,
    p_source      => 'SELECT id, title, description, status, due_date, created_at
                        FROM tasks
                       WHERE (:status IS NULL OR status = :status)
                       ORDER BY id');

  -- POST /v1/tasks/
  ORDS.DEFINE_HANDLER(
    p_module_name => 'tasks.v1',
    p_pattern     => 'tasks/',
    p_method      => 'POST',
    p_source_type => ORDS.source_type_plsql,
    p_source      => q'[
BEGIN
  IF :title IS NULL
     OR (:status IS NOT NULL AND :status NOT IN ('TODO','DOING','DONE')) THEN
    :status_code := 400;
    RETURN;
  END IF;

  INSERT INTO tasks (title, description, status, due_date)
  VALUES (:title, :description, :status, TO_DATE(:due_date, 'YYYY-MM-DD'));

  :status_code := 201;
END;]');

  ----------------------------------------------------------------
  -- Elemento: /v1/tasks/:id
  ----------------------------------------------------------------
  ORDS.DEFINE_TEMPLATE(
    p_module_name => 'tasks.v1',
    p_pattern     => 'tasks/:id');

  -- GET /v1/tasks/:id
  ORDS.DEFINE_HANDLER(
    p_module_name => 'tasks.v1',
    p_pattern     => 'tasks/:id',
    p_method      => 'GET',
    p_source_type => ORDS.source_type_collection_item,
    p_source      => 'SELECT id, title, description, status, due_date, created_at
                        FROM tasks
                       WHERE id = :id');

  -- PUT /v1/tasks/:id
  ORDS.DEFINE_HANDLER(
    p_module_name => 'tasks.v1',
    p_pattern     => 'tasks/:id',
    p_method      => 'PUT',
    p_source_type => ORDS.source_type_plsql,
    p_source      => q'[
BEGIN
  IF :status IS NOT NULL AND :status NOT IN ('TODO','DOING','DONE') THEN
    :status_code := 400;
    RETURN;
  END IF;

  UPDATE tasks
     SET title       = NVL(:title, title),
         description = NVL(:description, description),
         status      = NVL(:status, status),
         due_date    = NVL(TO_DATE(:due_date, 'YYYY-MM-DD'), due_date)
   WHERE id = :id;

  :status_code := CASE WHEN SQL%ROWCOUNT = 0 THEN 404 ELSE 204 END;
END;]');

  -- DELETE /v1/tasks/:id
  ORDS.DEFINE_HANDLER(
    p_module_name => 'tasks.v1',
    p_pattern     => 'tasks/:id',
    p_method      => 'DELETE',
    p_source_type => ORDS.source_type_plsql,
    p_source      => q'[
BEGIN
  DELETE FROM tasks WHERE id = :id;
  :status_code := CASE WHEN SQL%ROWCOUNT = 0 THEN 404 ELSE 204 END;
END;]');

  COMMIT;
END;
/

-- Verificacion rapida de metodos, modulos y templates
SELECT m.name AS module, t.uri_template, h.method, h.source_type
  FROM user_ords_modules   m
  JOIN user_ords_templates t ON t.module_id   = m.id
  JOIN user_ords_handlers  h ON h.template_id = t.id
 WHERE m.name = 'tasks.v1'
 ORDER BY t.uri_template, h.method;