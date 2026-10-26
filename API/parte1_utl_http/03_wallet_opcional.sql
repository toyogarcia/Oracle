-- =====================================================================
-- SCRIPT 03 - WALLET PARA HTTPS (OPCIONAL EN AUTONOMOUS DATABASE)
-- =====================================================================
-- EJECUTAR COMO : ADMIN (parte de base de datos) + tu PC (parte local)
--
-- ¿QUÉ ES UN WALLET?
--   Cuando llamas a una URL https://, Oracle debe comprobar que el
--   certificado del servidor es de confianza. Esos certificados de
--   confianza (CA raíz) viven en un "wallet" (archivo cifrado).
--
-- ¿LO NECESITO EN TU CUENTA FREE DE OCI?
--   NO, normalmente. Autonomous Database (Always Free) ya trae un
--   wallet preconfigurado con las autoridades certificadoras públicas
--   más comunes, así que UTL_HTTP funciona con HTTPS solo con la ACL.
--   >>> Si el SCRIPT 04 te funciona, puedes SALTARTE este script. <<<
--
--   Este script sirve para APRENDER cómo se usa un wallet propio
--   (imprescindible en bases Oracle on-premise o Base Database Service,
--   o si la API usa una CA que no está en el wallet por defecto).
--   Si en el SCRIPT 04 ves el error ORA-29024 (certificate validation
--   failure), este script es la solución.
-- =====================================================================

-- ---------------------------------------------------------------------
-- PASO 3.1 - (EN TU PC) Crear el wallet con orapki
-- ---------------------------------------------------------------------
-- orapki viene con el Oracle Client / Instant Client Tools / SQLcl no lo
-- incluye; instálalo desde el Oracle Database client. Comandos:
--
--   1) Crear un wallet de auto-login (sin contraseña):
--        orapki wallet create -wallet ./mi_wallet -auto_login_only
--
--   2) Descargar el certificado RAÍZ de la cadena de la API. Una forma:
--        openssl s_client -showcerts -connect jsonplaceholder.typicode.com:443
--      o exportarlo desde el navegador (candado > certificado > raíz,
--      formato .crt/.pem en Base64).
--
--   3) Añadirlo al wallet:
--        orapki wallet add -wallet ./mi_wallet -trusted_cert \
--               -cert raiz_ca.crt -auto_login_only
--
--   Se genera el archivo  ./mi_wallet/cwallet.sso  (es el que usaremos).

-- ---------------------------------------------------------------------
-- PASO 3.2 - (EN OCI) Subir cwallet.sso a Object Storage
-- ---------------------------------------------------------------------
--   1) Menú OCI > Almacenamiento > Buckets > crear bucket "wallet-demo".
--   2) Sube el archivo cwallet.sso.
--   3) Crea una "Pre-Authenticated Request (PAR)" de lectura sobre ese
--      objeto y copia la URL (solo se muestra una vez).
--   OJO: la URL PAR es una "llave" de acceso; no la subas a GitHub.

-- ---------------------------------------------------------------------
-- PASO 3.3 - Copiar el wallet al sistema de archivos de la BD
-- ---------------------------------------------------------------------
-- Sustituye <URL_PAR> por la URL del paso anterior.
BEGIN
  DBMS_CLOUD.GET_OBJECT(
    credential_name => NULL,               -- NULL porque la URL PAR ya lleva la autorización
    object_uri      => '<URL_PAR>',
    directory_name  => 'DATA_PUMP_DIR',    -- directorio ya existente en ADB
    file_name       => 'cwallet.sso'
  );
END;
/

-- ---------------------------------------------------------------------
-- PASO 3.4 - Comprobar que el archivo está en el directorio
-- ---------------------------------------------------------------------
SELECT object_name, bytes
  FROM DBMS_CLOUD.LIST_FILES('DATA_PUMP_DIR');
-- RESULTADO ESPERADO: aparece cwallet.sso

-- ---------------------------------------------------------------------
-- PASO 3.5 - Obtener la RUTA física del directorio
-- ---------------------------------------------------------------------
SELECT directory_path
  FROM dba_directories
 WHERE directory_name = 'DATA_PUMP_DIR';
-- Copia el valor, p. ej.:  /u03/dbfs/ABC123/data/dpump
-- (solo la carpeta, SIN el nombre del archivo)

-- ---------------------------------------------------------------------
-- PASO 3.6 - Dar permiso de lectura del directorio a APIDEMO
-- ---------------------------------------------------------------------
GRANT READ ON DIRECTORY data_pump_dir TO apidemo;

-- ---------------------------------------------------------------------
-- PASO 3.7 - Cómo USAR el wallet (se hace luego como APIDEMO)
-- ---------------------------------------------------------------------
-- Una vez creado el paquete API_CLIENTE (scripts 05 y 06), antes de
-- llamar a la API ejecuta en tu sesión:
--
--     EXEC api_cliente.set_wallet('/u03/dbfs/ABC123/data/dpump');
--
-- Para volver al wallet por defecto de ADB:
--
--     EXEC api_cliente.set_wallet(NULL);
--
-- SIGUIENTE: SCRIPT 04 (como APIDEMO).
