-- =====================================================================
-- SCRIPT 05 - PAQUETE API_CLIENTE: ESPECIFICACIÓN (LA "VITRINA")
-- =====================================================================
-- EJECUTAR COMO : APIDEMO
-- OBJETIVO      : Declarar QUÉ ofrece el paquete (su interfaz pública).
--
-- ¿QUÉ ES UN PAQUETE?
--   Un paquete PL/SQL agrupa procedimientos y funciones relacionados.
--   Tiene dos partes:
--     - ESPECIFICACIÓN (este script): lista lo que se puede llamar.
--     - CUERPO (script 06): contiene el código real.
--
-- Cada función corresponde a un método HTTP sobre la API JSONPlaceholder:
--     GET    /posts        -> get_posts      (listar todos)
--     GET    /posts/{id}   -> get_post       (leer uno)
--     POST   /posts        -> crear_post     (crear)
--     PUT    /posts/{id}   -> actualizar_post(actualizar)
--     DELETE /posts/{id}   -> eliminar_post  (borrar)
-- =====================================================================

CREATE OR REPLACE PACKAGE api_cliente AS

  -- URL base de la API pública (constante: no cambia durante la ejecución)
  c_base_url CONSTANT VARCHAR2(200) := 'https://jsonplaceholder.typicode.com';

  -- Estructura (registro) con el resultado de CUALQUIER llamada HTTP:
  --   status_code   : 200, 201, 404...
  --   status_reason : "OK", "Created", "Not Found"...
  --   cuerpo        : el JSON devuelto por la API (CLOB = texto largo)
  TYPE t_respuesta IS RECORD (
    status_code   PLS_INTEGER,
    status_reason VARCHAR2(256),
    cuerpo        CLOB
  );

  -- Configura (opcional) un wallet propio. Ver SCRIPT 03.
  -- Con NULL se usa el wallet por defecto de Autonomous Database.
  PROCEDURE set_wallet(p_ruta IN VARCHAR2 DEFAULT NULL);

  -- GET /posts : devuelve la lista completa (100 registros)
  FUNCTION get_posts RETURN t_respuesta;

  -- GET /posts/{id} : devuelve un registro
  FUNCTION get_post(p_id IN NUMBER) RETURN t_respuesta;

  -- POST /posts : crea un registro nuevo
  FUNCTION crear_post(p_user_id   IN NUMBER,
                      p_titulo    IN VARCHAR2,
                      p_contenido IN VARCHAR2) RETURN t_respuesta;

  -- PUT /posts/{id} : reemplaza un registro existente
  FUNCTION actualizar_post(p_id        IN NUMBER,
                           p_user_id   IN NUMBER,
                           p_titulo    IN VARCHAR2,
                           p_contenido IN VARCHAR2) RETURN t_respuesta;

  -- DELETE /posts/{id} : borra un registro
  FUNCTION eliminar_post(p_id IN NUMBER) RETURN t_respuesta;

  -- Utilidad: imprime una respuesta con DBMS_OUTPUT (para las pruebas)
  PROCEDURE imprimir(p_resp      IN t_respuesta,
                     p_max_chars IN PLS_INTEGER DEFAULT 1500);

END api_cliente;
/

-- Comprobar que no hay errores de compilación:
SHOW ERRORS PACKAGE api_cliente
-- RESULTADO ESPERADO: sin errores ("No errors").
--
-- SIGUIENTE: SCRIPT 06 (cuerpo del paquete).
