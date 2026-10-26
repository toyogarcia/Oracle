-- =====================================================================
-- 99_pruebas.sql
-- Ejecutar como: API_DEMO
-- Consultas de verificación.
-- =====================================================================

-- Cargar datos
EXEC cargar_posts;

-- Debe devolver 100 (más los posts creados vía API, si los hay)
SELECT COUNT(*) AS total FROM posts_api;

-- Primeros registros
SELECT id, user_id, titulo
FROM   posts_api
ORDER  BY id
FETCH FIRST 5 ROWS ONLY;

-- Posts creados por la API de administración (IDs >= 1000)
SELECT id, user_id, titulo
FROM   posts_api
WHERE  id >= 1000
ORDER  BY id;

-- Estado del job
SELECT job_name, enabled, state, next_run_date
FROM   user_scheduler_jobs;

-- Módulos ORDS publicados
SELECT name, uri_prefix, status
FROM   user_ords_modules;
