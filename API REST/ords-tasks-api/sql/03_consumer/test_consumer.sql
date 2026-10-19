BEGIN
  tasks_client_pkg.init(
    p_base_url      => 'https://<tu-host>.adb.<región>.oraclecloudapps.com/ords/api/',
    p_client_id     => '<client_id>',
    p_client_secret => '<client_secret>');
END;
/

-- Crear una tarea llamando a tu propia API
SELECT tasks_client_pkg.create_task('Creada desde PL/SQL', 'vía APEX_WEB_SERVICE') FROM dual;

-- Convertir el JSON de la respuesta en filas
WITH resp AS (SELECT tasks_client_pkg.get_tasks_json('TODO') AS j FROM dual)
SELECT jt.*
  FROM resp,
       JSON_TABLE(resp.j, '$.items[*]'
         COLUMNS (id     NUMBER        PATH '$.id',
                  title  VARCHAR2(200) PATH '$.title',
                  status VARCHAR2(20)  PATH '$.status')) jt;