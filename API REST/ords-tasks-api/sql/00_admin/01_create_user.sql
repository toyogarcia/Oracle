-- Este script se debe ejecutar con el usuarios ADMIN
-- El resto de scripts se deben ejecutar con el usuario tasks_dev

-- Creacion del usuario de base de datos
CREATE USER tasks_dev IDENTIFIED BY "<TU_CLAVE>"
  QUOTA UNLIMITED ON data;

-- Concesion de los permisos necesarios al usuario de base de datos creado
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE,
      CREATE PROCEDURE, CREATE TRIGGER, CREATE TYPE TO tasks_dev;

-- Habilitar el esquema para ORDS
-- Habilita el acceso REST: Permite que ORDS cree y gestione servicios RESTful asociados a los objetos (tablas, vistas, etc.) de ese esquema específico.
-- Mapeo de URL: Define cómo se va a identificar el esquema en las peticiones HTTP mediante parámetros como p_url_mapping_type y p_url_mapping_pattern (creando un alias para la URL).
-- Control de autenticación: Permite configurar (con el parámetro p_auto_rest_auth) si se requiere autenticación para acceder al catálogo de metadatos REST de dicho esquema.
-- Acceso a Database Actions: En entornos como Oracle Autonomous Database, habilitar el esquema es un paso indispensable para que un usuario pueda conectarse y gestionar la base de datos a través de la interfaz web de Database Actions (SQL Developer Web).
BEGIN
  ORDS_ADMIN.ENABLE_SCHEMA(
    p_enabled             => TRUE,
    p_schema              => 'TASKS_DEV',
    p_url_mapping_type    => 'BASE_PATH',
    p_url_mapping_pattern => 'api',
    p_auto_rest_auth      => FALSE
  );
  COMMIT;
END;
/

-- Creacion de Workspace APEX para posterior consumo de la API
-- Crea un Workspace: Añade el espacio de trabajo en la instancia de APEX con el nombre que se le indique.
-- Asocia esquemas de base de datos: Vincula un esquema primario (p_primary_schema) y, opcionalmente, esquemas adicionales (p_additional_schemas) a dicho workspace.
BEGIN
  APEX_INSTANCE_ADMIN.ADD_WORKSPACE(
    p_workspace      => 'TASKS',
    p_primary_schema => 'TASKS_DEV');
  COMMIT;
END;
/