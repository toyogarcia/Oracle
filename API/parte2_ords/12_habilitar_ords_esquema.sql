-- =====================================================================
-- SCRIPT 12 - HABILITAR (REST-ENABLE) EL ESQUEMA APIDEMO PARA ORDS
-- =====================================================================
-- EJECUTAR COMO : APIDEMO
-- OBJETIVO      : Decirle a ORDS que el esquema APIDEMO puede publicar
--                 servicios REST y con qué "nombre" aparecerá en la URL.
--
-- Si ejecutaste el PASO 1.4 del SCRIPT 01, el esquema ya está habilitado;
-- repetirlo es inofensivo (es idempotente) y aquí lo vemos en detalle.
--
-- La URL final tendrá esta forma:
--   https://<HOST-DE-TU-ADB>/ords/<alias_esquema>/<alias_tabla>/
--                                  ^^^^^^^^^^^^^   ^^^^^^^^^^^^
--                                  'apidemo'       'productos' (script 13)
-- =====================================================================

-- ---------------------------------------------------------------------
-- PASO 12.1 - Habilitar el esquema
-- ---------------------------------------------------------------------
BEGIN
  ORDS.ENABLE_SCHEMA(
    p_enabled             => TRUE,
    p_schema              => 'APIDEMO',      -- esquema real en la BD
    p_url_mapping_type    => 'BASE_PATH',    -- el alias va en la ruta de la URL
    p_url_mapping_pattern => 'apidemo',      -- el alias (puede ser distinto del esquema)
    p_auto_rest_auth      => FALSE           -- FALSE = AutoREST SIN autenticación (solo demo)
  );
  COMMIT;
END;
/

-- ---------------------------------------------------------------------
-- PASO 12.2 - Verificar
-- ---------------------------------------------------------------------
SELECT parsing_schema, pattern AS alias, status
  FROM user_ords_schemas;
-- RESULTADO ESPERADO: APIDEMO | apidemo | ENABLED

-- ---------------------------------------------------------------------
-- PASO 12.3 - (Manual) Averiguar la URL base de tu base de datos
-- ---------------------------------------------------------------------
--   Consola OCI > Oracle Database > Autonomous Database > tu BD >
--   pestaña "Configuración de herramientas" (Tool configuration) >
--   copia la "URL de acceso público" de Oracle REST Data Services.
--   Tendrá esta forma (ejemplo):
--     https://abcd1234xyz-mibd.adb.eu-frankfurt-1.oraclecloudapps.com
--   Tu URL base de la API será:
--     https://abcd1234xyz-mibd.adb.eu-frankfurt-1.oraclecloudapps.com/ords/apidemo
--   Guárdala: es la variable {{ords_base}} de Postman.
--
-- SIGUIENTE: SCRIPT 13.
