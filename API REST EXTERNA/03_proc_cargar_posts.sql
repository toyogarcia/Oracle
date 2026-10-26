-- =====================================================================
-- 03_proc_cargar_posts.sql
-- Ejecutar como: API_DEMO
-- Consume https://jsonplaceholder.typicode.com/posts y carga posts_api.
-- Usa MERGE, por lo que se puede ejecutar varias veces sin duplicar.
-- =====================================================================

CREATE OR REPLACE PROCEDURE cargar_posts IS
  l_req   UTL_HTTP.REQ;
  l_resp  UTL_HTTP.RESP;
  l_buf   VARCHAR2(32767);
  l_json  CLOB;
BEGIN
  UTL_HTTP.SET_TRANSFER_TIMEOUT(30);

  l_req  := UTL_HTTP.BEGIN_REQUEST('https://jsonplaceholder.typicode.com/posts', 'GET');
  UTL_HTTP.SET_HEADER(l_req, 'Accept', 'application/json');
  l_resp := UTL_HTTP.GET_RESPONSE(l_req);

  DBMS_LOB.CREATETEMPORARY(l_json, TRUE);
  BEGIN
    LOOP
      UTL_HTTP.READ_TEXT(l_resp, l_buf, 32000);
      DBMS_LOB.WRITEAPPEND(l_json, LENGTH(l_buf), l_buf);
    END LOOP;
  EXCEPTION
    WHEN UTL_HTTP.END_OF_BODY THEN NULL;
  END;
  UTL_HTTP.END_RESPONSE(l_resp);

  MERGE INTO posts_api t
  USING (
    SELECT id, userId, title, body
    FROM JSON_TABLE(l_json, '$[*]'
           COLUMNS (id     NUMBER        PATH '$.id',
                    userId NUMBER        PATH '$.userId',
                    title  VARCHAR2(500) PATH '$.title',
                    body   CLOB          PATH '$.body'))
  ) s
  ON (t.id = s.id)
  WHEN MATCHED THEN UPDATE SET
       t.user_id = s.userId, t.titulo = s.title, t.cuerpo = s.body
  WHEN NOT MATCHED THEN INSERT (id, user_id, titulo, cuerpo)
       VALUES (s.id, s.userId, s.title, s.body);

  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    BEGIN UTL_HTTP.END_RESPONSE(l_resp); EXCEPTION WHEN OTHERS THEN NULL; END;
    RAISE;
END cargar_posts;
/
