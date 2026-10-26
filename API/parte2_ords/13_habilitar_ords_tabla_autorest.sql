-- =====================================================================
-- SCRIPT 13 - PUBLICAR LA TABLA COMO API REST (AutoREST)
-- =====================================================================
-- EJECUTAR COMO : APIDEMO
-- OBJETIVO      : Con UNA llamada, ORDS genera automáticamente los
--                 endpoints CRUD de la tabla (AutoREST).
--
-- Endpoints generados (sustituye {{ords_base}} por tu URL del PASO 12.3):
--
--   Método  URL                                   Operación SQL
--   ------  ------------------------------------  ----------------
--   GET     {{ords_base}}/productos/              SELECT (lista paginada)
--   GET     {{ords_base}}/productos/{id}          SELECT por clave primaria
--   POST    {{ords_base}}/productos/              INSERT
--   PUT     {{ords_base}}/productos/{id}          UPDATE (o INSERT si no existe)
--   DELETE  {{ords_base}}/productos/{id}          DELETE
--
-- ¡ATENCIÓN! En este paso los endpoints quedan ABIERTOS a internet,
-- sin contraseña. Es para aprender y probar con Postman. Antes de
-- usar datos reales, ejecuta el SCRIPT 14 para protegerlos.
-- =====================================================================

-- ---------------------------------------------------------------------
-- PASO 13.1 - Habilitar la tabla
-- ---------------------------------------------------------------------
BEGIN
  ORDS.ENABLE_OBJECT(
    p_enabled        => TRUE,
    p_schema         => 'APIDEMO',
    p_object         => 'PRODUCTOS',     -- nombre de la tabla (MAYÚSCULAS)
    p_object_type    => 'TABLE',
    p_object_alias   => 'productos',     -- cómo se verá en la URL
    p_auto_rest_auth => FALSE            -- sin autenticación (solo demo)
  );
  COMMIT;
END;
/

-- ---------------------------------------------------------------------
-- PASO 13.2 - Verificar
-- ---------------------------------------------------------------------
SELECT parsing_object, type, object_alias, status
  FROM user_ords_enabled_objects;
-- RESULTADO ESPERADO: PRODUCTOS | TABLE | productos | ENABLED

-- ---------------------------------------------------------------------
-- PASO 13.3 - PROBAR CON POSTMAN (o con el navegador)
-- ---------------------------------------------------------------------
--   Importa postman/02_ORDS_Productos.postman_collection.json y el
--   entorno postman/ORDS_environment.postman_environment.json.
--   Edita la variable ords_base con tu URL y ejecuta en orden la
--   carpeta "1 - Sin autenticación (script 13)":
--
--   1) GET lista     -> 200 y {"items":[...5 productos...],"hasMore":false,...}
--   2) GET uno       -> 200 con el producto id 1
--   3) GET filtrado  -> 200 solo productos con precio > 50
--                       (parámetro q={"precio":{"$gt":50}})
--   4) POST crear    -> 201 con el nuevo producto (id 6)
--   5) PUT           -> 200 con el producto modificado
--   6) DELETE        -> 200 {"rowsDeleted":1}
--
-- ---------------------------------------------------------------------
-- PASO 13.4 - COMPROBAR EL EFECTO EN LA BASE DE DATOS
-- ---------------------------------------------------------------------
-- Tras cada petición de escritura, consulta aquí para ver el cambio REAL:
SELECT id, nombre, precio, stock, activo, fecha_creacion
  FROM productos
 ORDER BY id;
-- (A diferencia de la API de la parte 1, estos cambios SÍ se guardan.)
--
-- NOTA: las columnas aparecen en minúsculas en el JSON (id, nombre...).
--
-- SIGUIENTE: SCRIPT 14 (seguridad).
