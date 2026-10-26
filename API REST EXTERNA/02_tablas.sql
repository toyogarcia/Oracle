-- =====================================================================
-- 02_tablas.sql
-- Ejecutar como: API_DEMO
-- =====================================================================

CREATE TABLE posts_api (
  id      NUMBER PRIMARY KEY,
  user_id NUMBER,
  titulo  VARCHAR2(500),
  cuerpo  CLOB
);

-- JSONPlaceholder usa los IDs 1 a 100; los posts creados por la API
-- de administración empiezan en 1000 para no chocar con la carga.
CREATE SEQUENCE posts_seq START WITH 1000;
