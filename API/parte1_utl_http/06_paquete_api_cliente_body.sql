-- =====================================================================
-- SCRIPT 06 - PAQUETE API_CLIENTE: CUERPO (EL CÓDIGO REAL)
-- =====================================================================
-- EJECUTAR COMO : APIDEMO
-- OBJETIVO      : Implementar las funciones declaradas en el SCRIPT 05.
--
-- IDEA CLAVE: las 5 funciones públicas hacen lo mismo salvo el método
-- HTTP, la URL y el cuerpo. Por eso escribimos UNA función privada,
-- LLAMAR, que hace el trabajo pesado, y las demás solo la invocan.
-- =====================================================================

CREATE OR REPLACE PACKAGE BODY api_cliente AS

  -- Variable de paquete (vive mientras dure tu sesión):
  -- ruta del wallet propio. NULL = usar el wallet por defecto.
  g_wallet_ruta VARCHAR2(500) := NULL;

  -- -------------------------------------------------------------------
  -- PASO 6.1 - set_wallet: guarda la ruta del wallet
  -- -------------------------------------------------------------------
  PROCEDURE set_wallet(p_ruta IN VARCHAR2 DEFAULT NULL) IS
  BEGIN
    g_wallet_ruta := p_ruta;
  END set_wallet;

  -- -------------------------------------------------------------------
  -- PASO 6.2 - llamar (PRIVADA): ejecuta cualquier petición HTTP
  --   p_metodo : 'GET', 'POST', 'PUT' o 'DELETE'
  --   p_url    : URL completa
  --   p_body   : JSON a enviar (solo POST y PUT; NULL en GET y DELETE)
  -- -------------------------------------------------------------------
  FUNCTION llamar(p_metodo IN VARCHAR2,
                  p_url    IN VARCHAR2,
                  p_body   IN VARCHAR2 DEFAULT NULL) RETURN t_respuesta IS
    l_req    UTL_HTTP.req;
    l_resp   UTL_HTTP.resp;
    l_res    t_respuesta;
    l_buffer VARCHAR2(8000);
    l_raw    RAW(32767);
  BEGIN
    -- (a) Ajustes generales de UTL_HTTP
    UTL_HTTP.set_detailed_excp_support(TRUE);   -- errores más descriptivos
    UTL_HTTP.set_transfer_timeout(30);          -- máximo 30 s de espera
    -- FALSE = si la API responde 404/500, NO lanzar excepción de Oracle;
    -- nos devuelve el código y decidimos nosotros qué hacer.
    UTL_HTTP.set_response_error_check(FALSE);

    -- (b) Wallet propio (solo si se configuró en el SCRIPT 03)
    IF g_wallet_ruta IS NOT NULL THEN
      UTL_HTTP.set_wallet('file:' || g_wallet_ruta, NULL);
    END IF;

    -- (c) Abrir la petición con el método indicado
    l_req := UTL_HTTP.begin_request(url         => p_url,
                                    method      => p_metodo,
                                    http_version => 'HTTP/1.1');

    -- (d) Cabeceras (headers)
    UTL_HTTP.set_header(l_req, 'User-Agent', 'Oracle-UTL_HTTP-Demo/1.0');
    UTL_HTTP.set_header(l_req, 'Accept',     'application/json');

    -- (e) Enviar el cuerpo JSON (solo si hay)
    IF p_body IS NOT NULL THEN
      l_raw := UTL_RAW.cast_to_raw(p_body);   -- texto -> bytes (UTF-8 en ADB)
      UTL_HTTP.set_header(l_req, 'Content-Type',   'application/json; charset=UTF-8');
      UTL_HTTP.set_header(l_req, 'Content-Length', TO_CHAR(UTL_RAW.length(l_raw)));
      UTL_HTTP.write_raw(l_req, l_raw);
    END IF;

    -- (f) Enviar y recibir la cabecera de la respuesta
    l_resp := UTL_HTTP.get_response(l_req);
    l_res.status_code   := l_resp.status_code;
    l_res.status_reason := l_resp.reason_phrase;

    -- (g) Leer el cuerpo de la respuesta por trozos y acumularlo en un CLOB
    DBMS_LOB.createtemporary(l_res.cuerpo, TRUE);
    LOOP
      BEGIN
        UTL_HTTP.read_text(l_resp, l_buffer, 2000);   -- hasta 2000 caracteres por vuelta
        DBMS_LOB.writeappend(l_res.cuerpo, LENGTH(l_buffer), l_buffer);
      EXCEPTION
        WHEN UTL_HTTP.end_of_body THEN
          EXIT;   -- ya no queda más texto
      END;
    END LOOP;

    -- (h) Cerrar la respuesta
    UTL_HTTP.end_response(l_resp);
    RETURN l_res;

  EXCEPTION
    WHEN OTHERS THEN
      -- Siempre liberar la conexión aunque falle algo
      BEGIN UTL_HTTP.end_response(l_resp); EXCEPTION WHEN OTHERS THEN NULL; END;
      RAISE;   -- re-lanzar el error original
  END llamar;

  -- -------------------------------------------------------------------
  -- PASO 6.3 - GET: leer datos (no lleva cuerpo)
  -- -------------------------------------------------------------------
  FUNCTION get_posts RETURN t_respuesta IS
  BEGIN
    RETURN llamar('GET', c_base_url || '/posts');
  END get_posts;

  FUNCTION get_post(p_id IN NUMBER) RETURN t_respuesta IS
  BEGIN
    RETURN llamar('GET', c_base_url || '/posts/' || p_id);
  END get_post;

  -- -------------------------------------------------------------------
  -- PASO 6.4 - POST: crear. Construimos el JSON con JSON_OBJECT
  --            (así Oracle escapa comillas y caracteres especiales).
  -- -------------------------------------------------------------------
  FUNCTION crear_post(p_user_id   IN NUMBER,
                      p_titulo    IN VARCHAR2,
                      p_contenido IN VARCHAR2) RETURN t_respuesta IS
    l_json VARCHAR2(4000);
  BEGIN
    SELECT JSON_OBJECT('userId' VALUE p_user_id,
                       'title'  VALUE p_titulo,
                       'body'   VALUE p_contenido)
      INTO l_json
      FROM dual;
    RETURN llamar('POST', c_base_url || '/posts', l_json);
  END crear_post;

  -- -------------------------------------------------------------------
  -- PASO 6.5 - PUT: actualizar (reemplaza el recurso completo)
  -- -------------------------------------------------------------------
  FUNCTION actualizar_post(p_id        IN NUMBER,
                           p_user_id   IN NUMBER,
                           p_titulo    IN VARCHAR2,
                           p_contenido IN VARCHAR2) RETURN t_respuesta IS
    l_json VARCHAR2(4000);
  BEGIN
    SELECT JSON_OBJECT('id'     VALUE p_id,
                       'userId' VALUE p_user_id,
                       'title'  VALUE p_titulo,
                       'body'   VALUE p_contenido)
      INTO l_json
      FROM dual;
    RETURN llamar('PUT', c_base_url || '/posts/' || p_id, l_json);
  END actualizar_post;

  -- -------------------------------------------------------------------
  -- PASO 6.6 - DELETE: borrar (no lleva cuerpo)
  -- -------------------------------------------------------------------
  FUNCTION eliminar_post(p_id IN NUMBER) RETURN t_respuesta IS
  BEGIN
    RETURN llamar('DELETE', c_base_url || '/posts/' || p_id);
  END eliminar_post;

  -- -------------------------------------------------------------------
  -- PASO 6.7 - imprimir: muestra código HTTP y el JSON (recortado)
  -- -------------------------------------------------------------------
  PROCEDURE imprimir(p_resp      IN t_respuesta,
                     p_max_chars IN PLS_INTEGER DEFAULT 1500) IS
  BEGIN
    DBMS_OUTPUT.put_line('HTTP ' || p_resp.status_code || ' ' || p_resp.status_reason);
    IF p_resp.cuerpo IS NOT NULL THEN
      DBMS_OUTPUT.put_line(DBMS_LOB.substr(p_resp.cuerpo, p_max_chars, 1));
      IF DBMS_LOB.getlength(p_resp.cuerpo) > p_max_chars THEN
        DBMS_OUTPUT.put_line('... (recortado; longitud total: '
                             || DBMS_LOB.getlength(p_resp.cuerpo) || ' caracteres)');
      END IF;
    END IF;
  END imprimir;

END api_cliente;
/

SHOW ERRORS PACKAGE BODY api_cliente
-- RESULTADO ESPERADO: "No errors".
--
-- SIGUIENTE: SCRIPT 07 (probar GET).
