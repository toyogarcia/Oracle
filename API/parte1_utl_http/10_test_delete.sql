-- =====================================================================
-- SCRIPT 10 - PROBAR EL MÉTODO DELETE (BORRAR)
-- =====================================================================
-- EJECUTAR COMO : APIDEMO
-- OBJETIVO      : Borrar un recurso y mostrar un resumen de los 4 métodos.
-- =====================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED

-- ---------------------------------------------------------------------
-- PASO 10.1 - DELETE /posts/1
-- ---------------------------------------------------------------------
DECLARE
  l_resp api_cliente.t_respuesta;
BEGIN
  l_resp := api_cliente.eliminar_post(1);
  api_cliente.imprimir(l_resp);
END;
/
-- RESULTADO ESPERADO:
--   HTTP 200 OK
--   {}
-- (La API devuelve un JSON vacío; tampoco borra nada realmente.)

-- ---------------------------------------------------------------------
-- PASO 10.2 - PRUEBA COMPLETA: los 4 métodos en un solo bloque
-- ---------------------------------------------------------------------
DECLARE
  l_resp api_cliente.t_respuesta;
BEGIN
  l_resp := api_cliente.get_post(2);
  DBMS_OUTPUT.put_line('GET    -> ' || l_resp.status_code || ' ' || l_resp.status_reason);

  l_resp := api_cliente.crear_post(1, 'Nuevo', 'Cuerpo nuevo');
  DBMS_OUTPUT.put_line('POST   -> ' || l_resp.status_code || ' ' || l_resp.status_reason);

  l_resp := api_cliente.actualizar_post(2, 1, 'Cambiado', 'Cuerpo cambiado');
  DBMS_OUTPUT.put_line('PUT    -> ' || l_resp.status_code || ' ' || l_resp.status_reason);

  l_resp := api_cliente.eliminar_post(2);
  DBMS_OUTPUT.put_line('DELETE -> ' || l_resp.status_code || ' ' || l_resp.status_reason);
END;
/
-- RESULTADO ESPERADO:
--   GET    -> 200 OK
--   POST   -> 201 Created
--   PUT    -> 200 OK
--   DELETE -> 200 OK

-- ---------------------------------------------------------------------
-- PASO 10.3 - COMPROBAR EN POSTMAN
-- ---------------------------------------------------------------------
--   Request: DELETE https://jsonplaceholder.typicode.com/posts/1
--   Debes recibir 200 OK con cuerpo {}.
--   Lanza toda la colección con "Run collection": los tests deben
--   salir en verde.
--
-- FIN DE LA PARTE 1. SIGUIENTE: PARTE 2 (ORDS) -> SCRIPT 11.
