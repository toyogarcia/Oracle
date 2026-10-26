-- =====================================================================
-- SCRIPT 07 - PROBAR EL MÉTODO GET (LEER)
-- =====================================================================
-- EJECUTAR COMO : APIDEMO
-- OBJETIVO      : Leer datos de la API y mostrarlos desde Oracle.
-- =====================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED

-- ---------------------------------------------------------------------
-- PASO 7.1 - GET /posts/1 : leer UN registro
-- ---------------------------------------------------------------------
DECLARE
  l_resp api_cliente.t_respuesta;
BEGIN
  l_resp := api_cliente.get_post(1);
  api_cliente.imprimir(l_resp);
END;
/
-- RESULTADO ESPERADO:
--   HTTP 200 OK
--   { "userId": 1, "id": 1, "title": "sunt aut facere...", "body": "quia et..." }

-- ---------------------------------------------------------------------
-- PASO 7.2 - GET /posts : leer TODOS y convertirlos en filas SQL
-- ---------------------------------------------------------------------
-- JSON_TABLE convierte un JSON en una "tabla" que podemos consultar con SQL.
DECLARE
  l_resp api_cliente.t_respuesta;
BEGIN
  l_resp := api_cliente.get_posts;
  DBMS_OUTPUT.put_line('HTTP ' || l_resp.status_code || ' ' || l_resp.status_reason);

  FOR r IN (SELECT jt.id, jt.user_id, SUBSTR(jt.titulo, 1, 50) AS titulo
              FROM JSON_TABLE(l_resp.cuerpo, '$[*]'
                     COLUMNS (id      NUMBER        PATH '$.id',
                              user_id NUMBER        PATH '$.userId',
                              titulo  VARCHAR2(400) PATH '$.title')) jt
             ORDER BY jt.id
             FETCH FIRST 5 ROWS ONLY) LOOP
    DBMS_OUTPUT.put_line(LPAD(r.id, 3) || ' | usuario ' || r.user_id || ' | ' || r.titulo);
  END LOOP;
END;
/
-- RESULTADO ESPERADO: HTTP 200 OK y 5 líneas (los 5 primeros posts de 100).

-- ---------------------------------------------------------------------
-- PASO 7.3 - GET de un registro que NO existe (provocar un 404)
-- ---------------------------------------------------------------------
DECLARE
  l_resp api_cliente.t_respuesta;
BEGIN
  l_resp := api_cliente.get_post(99999);
  api_cliente.imprimir(l_resp);
END;
/
-- RESULTADO ESPERADO:  HTTP 404 Not Found   y cuerpo "{}"
-- (Demuestra que UTL_HTTP no falla: nos devuelve el código para decidir.)

-- ---------------------------------------------------------------------
-- PASO 7.4 - COMPROBAR EN POSTMAN
-- ---------------------------------------------------------------------
--   Importa postman/01_JSONPlaceholder.postman_collection.json y lanza
--   "GET - Un post (id 1)" y "GET - Todos los posts".
--   El JSON debe ser IDÉNTICO al que imprimió Oracle.
--   Equivalente: GET https://jsonplaceholder.typicode.com/posts/1
--
-- SIGUIENTE: SCRIPT 08 (POST).
