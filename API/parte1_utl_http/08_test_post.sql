-- =====================================================================
-- SCRIPT 08 - PROBAR EL MÉTODO POST (CREAR)
-- =====================================================================
-- EJECUTAR COMO : APIDEMO
-- OBJETIVO      : Enviar un JSON a la API para crear un recurso nuevo.
-- =====================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED

-- ---------------------------------------------------------------------
-- PASO 8.1 - POST /posts
-- ---------------------------------------------------------------------
DECLARE
  l_resp api_cliente.t_respuesta;
BEGIN
  l_resp := api_cliente.crear_post(
              p_user_id   => 1,
              p_titulo    => 'Mi primer post desde Oracle',
              p_contenido => 'Enviado con UTL_HTTP desde Oracle Autonomous Database');
  api_cliente.imprimir(l_resp);
END;
/
-- RESULTADO ESPERADO:
--   HTTP 201 Created
--   { "userId": 1, "title": "Mi primer post desde Oracle",
--     "body": "Enviado con UTL_HTTP desde...", "id": 101 }
--
-- ¡IMPORTANTE! JSONPlaceholder SIMULA la creación: te devuelve el id 101
-- pero NO guarda nada. Si luego haces GET /posts/101 obtendrás 404.
-- Es normal: es una API de pruebas.

-- ---------------------------------------------------------------------
-- PASO 8.2 - COMPROBAR EN POSTMAN
-- ---------------------------------------------------------------------
--   Request: POST https://jsonplaceholder.typicode.com/posts
--   Pestaña Body > raw > JSON:
--     {
--       "userId": 1,
--       "title": "Mi primer post desde Oracle",
--       "body": "Enviado con UTL_HTTP desde Oracle Autonomous Database"
--     }
--   Debes recibir 201 Created con "id": 101, igual que en Oracle.
--
-- SIGUIENTE: SCRIPT 09 (PUT).
