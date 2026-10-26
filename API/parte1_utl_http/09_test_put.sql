-- =====================================================================
-- SCRIPT 09 - PROBAR EL MÉTODO PUT (ACTUALIZAR)
-- =====================================================================
-- EJECUTAR COMO : APIDEMO
-- OBJETIVO      : Reemplazar un recurso existente (el post número 1).
--
-- PUT vs PATCH: PUT reemplaza el recurso COMPLETO, por eso enviamos
-- todos los campos (id, userId, title, body).
-- =====================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED

-- ---------------------------------------------------------------------
-- PASO 9.1 - PUT /posts/1
-- ---------------------------------------------------------------------
DECLARE
  l_resp api_cliente.t_respuesta;
BEGIN
  l_resp := api_cliente.actualizar_post(
              p_id        => 1,
              p_user_id   => 1,
              p_titulo    => 'Título ACTUALIZADO desde Oracle',
              p_contenido => 'Contenido modificado con un PUT');
  api_cliente.imprimir(l_resp);
END;
/
-- RESULTADO ESPERADO:
--   HTTP 200 OK
--   { "id": 1, "userId": 1, "title": "Título ACTUALIZADO desde Oracle",
--     "body": "Contenido modificado con un PUT" }
--
-- Igual que antes, la API de pruebas NO persiste el cambio:
-- un GET /posts/1 posterior devolverá el título original.

-- ---------------------------------------------------------------------
-- PASO 9.2 - COMPROBAR EN POSTMAN
-- ---------------------------------------------------------------------
--   Request: PUT https://jsonplaceholder.typicode.com/posts/1
--   Body > raw > JSON:
--     { "id": 1, "userId": 1,
--       "title": "Título ACTUALIZADO desde Oracle",
--       "body": "Contenido modificado con un PUT" }
--   Debes recibir 200 OK con el mismo JSON.
--
-- SIGUIENTE: SCRIPT 10 (DELETE).
