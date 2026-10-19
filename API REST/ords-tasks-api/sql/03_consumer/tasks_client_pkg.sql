-- Consumir tu propia API desde Oracle
CREATE OR REPLACE PACKAGE tasks_client_pkg AS
  PROCEDURE init(p_base_url IN VARCHAR2, p_client_id IN VARCHAR2, p_client_secret IN VARCHAR2);
  FUNCTION  get_token RETURN VARCHAR2;
  FUNCTION  get_tasks_json(p_status IN VARCHAR2 DEFAULT NULL) RETURN CLOB;
  FUNCTION  create_task(p_title IN VARCHAR2, p_description IN VARCHAR2 DEFAULT NULL) RETURN CLOB;
END tasks_client_pkg;
/

CREATE OR REPLACE PACKAGE BODY tasks_client_pkg AS
  g_base_url      VARCHAR2(500);   -- termina en /ords/api/
  g_client_id     VARCHAR2(200);
  g_client_secret VARCHAR2(200);

  PROCEDURE init(p_base_url IN VARCHAR2, p_client_id IN VARCHAR2, p_client_secret IN VARCHAR2) IS
  BEGIN
    g_base_url := p_base_url; g_client_id := p_client_id; g_client_secret := p_client_secret;
    -- Contexto APEX necesario para APEX_WEB_SERVICE fuera de una app APEX
    APEX_UTIL.SET_WORKSPACE('TASKS');
  END;

  FUNCTION get_token RETURN VARCHAR2 IS
    l_resp CLOB;
  BEGIN
    APEX_WEB_SERVICE.G_REQUEST_HEADERS.DELETE;
    APEX_WEB_SERVICE.G_REQUEST_HEADERS(1).NAME  := 'Content-Type';
    APEX_WEB_SERVICE.G_REQUEST_HEADERS(1).VALUE := 'application/x-www-form-urlencoded';
    l_resp := APEX_WEB_SERVICE.MAKE_REST_REQUEST(
                p_url         => g_base_url || 'oauth/token',
                p_http_method => 'POST',
                p_username    => g_client_id,
                p_password    => g_client_secret,
                p_body        => 'grant_type=client_credentials');
    RETURN JSON_VALUE(l_resp, '$.access_token');
  END;

    PROCEDURE set_auth_headers IS
    l_token VARCHAR2(4000);
  BEGIN
    l_token := get_token;   -- primero el token; get_token modifica las cabeceras

    APEX_WEB_SERVICE.G_REQUEST_HEADERS.DELETE;
    APEX_WEB_SERVICE.G_REQUEST_HEADERS(1).NAME  := 'Authorization';
    APEX_WEB_SERVICE.G_REQUEST_HEADERS(1).VALUE := 'Bearer ' || l_token;
    APEX_WEB_SERVICE.G_REQUEST_HEADERS(2).NAME  := 'Content-Type';
    APEX_WEB_SERVICE.G_REQUEST_HEADERS(2).VALUE := 'application/json';
  END;

  FUNCTION get_tasks_json(p_status IN VARCHAR2 DEFAULT NULL) RETURN CLOB IS
  BEGIN
    set_auth_headers;
    RETURN APEX_WEB_SERVICE.MAKE_REST_REQUEST(
             p_url         => g_base_url || 'v1/tasks/' ||
                              CASE WHEN p_status IS NOT NULL THEN '?status=' || p_status END,
             p_http_method => 'GET');
  END;

  FUNCTION create_task(p_title IN VARCHAR2, p_description IN VARCHAR2 DEFAULT NULL) RETURN CLOB IS
  BEGIN
    set_auth_headers;
    RETURN APEX_WEB_SERVICE.MAKE_REST_REQUEST(
             p_url         => g_base_url || 'v1/tasks/',
             p_http_method => 'POST',
             p_body        => JSON_OBJECT('title' VALUE p_title, 'description' VALUE p_description));
  END;
END tasks_client_pkg;
/