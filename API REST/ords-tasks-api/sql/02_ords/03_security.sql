BEGIN
  -- Define un rol lógico en ORDS: Sirve para agrupar permisos o privilegios de acceso a los servicios REST
  -- No es un role de base de datos. Es exclusivo de ORDS.
  ORDS.CREATE_ROLE(p_role_name => 'tasks_role');

  -- crear un privilegio de seguridad (un ámbito o scope de OAuth 2.0) que permite controlar y restringir qué usuarios o clientes pueden acceder a determinados servicios web RESTful
  ORDS.CREATE_PRIVILEGE(
    p_name        => 'tasks.priv',
    p_role_name   => 'tasks_role',
    p_label       => 'Tasks API',
    p_description => 'Acceso a la API de tareas');

  -- asociar un privilegio de seguridad con un patrón de URL (recurso REST)
  ORDS.CREATE_PRIVILEGE_MAPPING(
    p_privilege_name => 'tasks.priv',
    p_pattern        => '/v1/*');

  -- Registra credenciales de cliente: Crea un nuevo registro de aplicación o cliente externo que estará autorizado a solicitar tokens de acceso (como client_credentials) para consumir servicios web o APIs REST protegidas
  OAUTH.CREATE_CLIENT(
    p_name            => 'tasks_client',
    p_grant_type      => 'client_credentials',
    p_owner           => 'Tasks Dev',
    p_description     => 'Cliente máquina a máquina',
    p_support_email   => 'tu@email.com',
    p_privilege_names => 'tasks.priv');

  -- asignar el rol al cliente OAuth.
  OAUTH.GRANT_CLIENT_ROLE(
    p_client_name => 'tasks_client',
    p_role_name   => 'tasks_role');

  COMMIT;
END;
/