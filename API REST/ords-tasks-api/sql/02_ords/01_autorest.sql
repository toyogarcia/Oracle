-- Como usuario TASKS_DEV activamos el objeto

-- Exponemos el objeto de base de datos como una API REST automáticamente (AutoREST o Auto PL/SQL)
-- Permite: 
-- Tablas y Vistas (TABLE, VIEW): Crea endpoints REST completos (GET, POST, PUT, DELETE) para consultar, insertar, actualizar y borrar datos de la tabla o vista sin necesidad de escribir código PL/SQL manual.
-- Procedimientos, Funciones y Paquetes PL/SQL: Permite ejecutar rutinas en la base de datos mediante peticiones HTTP (llamadas RPC o Remote Procedure Call), manejando de forma automática los parámetros de entrada y la salida en formato JSON.

-- Tras ejecutar este script se puede testear la API desde Cloud Shell de OCI:
-- BASE="https://<tu-host>.adb.<región>.oraclecloudapps.com/ords/api"
-- curl "$BASE/tasks_auto/"
-- curl "$BASE/tasks_auto/1"
-- curl "$BASE/tasks_auto/?q=%7B%22status%22:%22TODO%22%7D"   # filtro {"status":"TODO"}
-- curl -X POST "$BASE/tasks_auto/" -H "Content-Type: application/json" -d '{"title":"Probar POST","status":"DONE"}'

BEGIN
  ORDS.ENABLE_OBJECT(
    p_enabled        => TRUE,
    p_schema         => 'TASKS_DEV',
    p_object         => 'TASKS',
    p_object_type    => 'TABLE',
    p_object_alias   => 'tasks_auto',
    p_auto_rest_auth => FALSE);
  COMMIT;
END;
/