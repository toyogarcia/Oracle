-- =====================================================================
-- 05_scheduler.sql
-- Ejecutar como: API_DEMO
-- Job diario (03:00, hora de la sesión) que refresca posts_api.
-- Nota Free Tier: la base se detiene tras 7 días sin actividad.
-- =====================================================================

BEGIN
  DBMS_SCHEDULER.CREATE_JOB(
    job_name        => 'JOB_CARGAR_POSTS',
    job_type        => 'STORED_PROCEDURE',
    job_action      => 'CARGAR_POSTS',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=DAILY; BYHOUR=3; BYMINUTE=0; BYSECOND=0',
    enabled         => TRUE,
    comments        => 'Refresca posts_api desde JSONPlaceholder');
END;
/

-- Ejecutar ahora, sin esperar al horario:
-- EXEC DBMS_SCHEDULER.RUN_JOB('JOB_CARGAR_POSTS');

-- Ver historial:
-- SELECT log_date, status, error#, additional_info
-- FROM   user_scheduler_job_run_details
-- WHERE  job_name = 'JOB_CARGAR_POSTS'
-- ORDER  BY log_date DESC;
