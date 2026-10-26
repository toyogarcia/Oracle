-- =====================================================================
-- SCRIPT 04 - PRUEBA RÁPIDA DE CONECTIVIDAD
-- =====================================================================
-- EJECUTAR COMO : APIDEMO
-- OBJETIVO      : Comprobar que ACL (+ wallet) funcionan ANTES de crear
--                 el paquete completo. Es la prueba más sencilla posible:
--                 un GET y mostrar el código de respuesta HTTP.
-- =====================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED

-- ---------------------------------------------------------------------
-- PASO 4.1 - Hacer un GET simple con UTL_HTTP
-- ---------------------------------------------------------------------
DECLARE
  l_req  UTL_HTTP.req;    -- representa la PETICIÓN
  l_resp UTL_HTTP.resp;   -- representa la RESPUESTA
BEGIN
  -- Mensajes de error más detallados
  UTL_HTTP.set_detailed_excp_support(TRUE);

  -- 1) Preparar la petición (GET por defecto)
  l_req := UTL_HTTP.begin_request('https://jsonplaceholder.typicode.com/posts/1');

  -- 2) Cabecera User-Agent (algunas APIs rechazan peticiones sin ella)
  UTL_HTTP.set_header(l_req, 'User-Agent', 'Oracle-UTL_HTTP-Demo/1.0');

  -- 3) Enviar y recibir la respuesta
  l_resp := UTL_HTTP.get_response(l_req);

  -- 4) Mostrar el resultado
  DBMS_OUTPUT.put_line('Código HTTP : ' || l_resp.status_code);
  DBMS_OUTPUT.put_line('Descripción : ' || l_resp.reason_phrase);

  -- 5) Cerrar (liberar recursos)
  UTL_HTTP.end_response(l_resp);
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.put_line('ERROR: ' || SQLERRM);
    DBMS_OUTPUT.put_line('--- Cómo interpretarlo ---');
    DBMS_OUTPUT.put_line('ORA-24247 -> falta la ACL: revisa el SCRIPT 02.');
    DBMS_OUTPUT.put_line('ORA-29024 -> certificado no válido: usa el SCRIPT 03.');
    DBMS_OUTPUT.put_line('ORA-29273/12545 -> problema de red/DNS: revisa el host.');
END;
/

-- RESULTADO ESPERADO:
--   Código HTTP : 200
--   Descripción : OK
--
-- SIGUIENTE: SCRIPT 05 (especificación del paquete).
