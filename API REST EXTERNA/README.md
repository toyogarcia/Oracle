# Oracle ADB API Consumer

Proyecto completo que **consume una API pública desde Oracle Autonomous Database (Free Tier)**, almacena los datos en una tabla, los **refresca automáticamente** con un job programado y los **expone como API REST con ORDS**: lectura pública y escritura protegida con OAuth2.

![Oracle](https://img.shields.io/badge/Oracle-Autonomous%20DB-F80000?logo=oracle&logoColor=white)
![ORDS](https://img.shields.io/badge/ORDS-REST-blue)
![PL/SQL](https://img.shields.io/badge/PL%2FSQL-UTL__HTTP-orange)

## Contenido

- [Qué hace](#qué-hace)
- [Arquitectura](#arquitectura)
- [Estructura del repositorio](#estructura-del-repositorio)
- [Requisitos](#requisitos)
- [Instalación](#instalación)
- [Carga automática](#carga-automática)
- [API REST](#api-rest)
- [Solución de problemas](#solución-de-problemas)

## Qué hace

1. Un procedimiento PL/SQL (`cargar_posts`) llama a la API pública [JSONPlaceholder](https://jsonplaceholder.typicode.com/) (`/posts`, 100 registros) con `UTL_HTTP`.
2. Parsea el JSON con `JSON_TABLE` y lo guarda en la tabla `posts_api` mediante `MERGE`, de forma que puede ejecutarse varias veces sin duplicar datos.
3. Un job de `DBMS_SCHEDULER` repite la carga cada día.
4. ORDS publica los datos como API REST: lectura abierta y escritura (POST, PUT, DELETE) protegida con OAuth2 *client credentials*.
5. Una colección de Postman y un script con `curl` permiten probar todo.

## Arquitectura

```
JSONPlaceholder ──HTTPS──▶ cargar_posts (PL/SQL) ──MERGE──▶ posts_api ──ORDS──▶ Clientes REST
                                  ▲                                          ├─ GET  /posts/          (público)
                                  │                                          └─ POST/PUT/DELETE
                          DBMS_SCHEDULER (diario)                               /admin/posts/  (OAuth2)
```

## Estructura del repositorio

```
API REST EXTERNA/
├── README.md
├── sql/
│   ├── 01_usuario.sql           # Usuario, privilegios y habilitación de ORDS
│   ├── 02_tablas.sql            # Tabla posts_api y secuencia posts_seq
│   ├── 03_proc_cargar_posts.sql # Consumo de la API y carga con MERGE
│   ├── 04_ords.sql              # Módulo público de lectura
│   ├── 05_scheduler.sql         # Job de carga automática
│   ├── 06_ords_oauth.sql        # Módulo de escritura + cliente OAuth2
│   └── 99_pruebas.sql           # Consultas de verificación
├── postman/
    └── ORDS_Posts_API.postman_environment.json
```

## Requisitos

- Cuenta de Oracle Cloud con una **Autonomous Database Always Free**
- Acceso a **Database Actions** (SQL y REST) con el usuario `ADMIN`
- `curl` y `python3` (para `scripts/probar_api.sh`) y/o [Postman](https://www.postman.com/)

No hace falta wallet ni ACL: Autonomous permite conexiones salientes HTTPS por el puerto 443 hacia APIs públicas.

## Instalación

Ejecuta los scripts de `sql/` en orden desde **Database Actions → SQL**.

| Orden | Script | Usuario | Qué hace |
|---|---|---|---|
| 1 | `01_usuario.sql` | `ADMIN` | Crea `API_DEMO`, concede privilegios y habilita el esquema para ORDS |
| 2 | `02_tablas.sql` | `API_DEMO` | Crea `posts_api` y `posts_seq` |
| 3 | `03_proc_cargar_posts.sql` | `API_DEMO` | Crea el procedimiento `cargar_posts` |
| 4 | `04_ords.sql` | `API_DEMO` | Publica el módulo público `posts` |
| 5 | `05_scheduler.sql` | `API_DEMO` | Programa el job diario |
| 6 | `06_ords_oauth.sql` | `API_DEMO` | Crea el módulo `posts_admin`, el privilegio y el cliente OAuth2 |
| 7 | `99_pruebas.sql` | `API_DEMO` | Carga los datos y verifica el resultado |

Antes de empezar:

- El alias REST de este proyecto es `demo` (`/ords/demo/`). Debe ser único por esquema: si ya usas ese alias en otro esquema, cámbialo en `01_usuario.sql` y en `BASE_URL`. Puedes ver los alias en uso con `SELECT parsing_schema, pattern FROM dba_ords_schemas;`.
- En `01_usuario.sql`, sustituye `<TU_CLAVE>` por una contraseña segura (solo en tu copia local).
- En `06_ords_oauth.sql`, cambia `tu_correo@ejemplo.com` por tu correo.
- Tras ejecutar `06_ords_oauth.sql`, copia el `client_id` y el `client_secret` que devuelve el `SELECT` final.

Primera carga y verificación:

```sql
EXEC cargar_posts;
SELECT COUNT(*) FROM posts_api;   -- esperado: 100
```

## Carga automática

El job `JOB_CARGAR_POSTS` ejecuta `cargar_posts` cada día a las 03:00 (hora de la sesión, normalmente UTC).

```sql
-- Ejecutar ahora
EXEC DBMS_SCHEDULER.RUN_JOB('JOB_CARGAR_POSTS');

-- Historial de ejecuciones
SELECT log_date, status, error#, additional_info
FROM   user_scheduler_job_run_details
WHERE  job_name = 'JOB_CARGAR_POSTS'
ORDER  BY log_date DESC;
```

> **Free Tier:** la base se detiene tras 7 días sin actividad y el job solo corre mientras está encendida.

La carga solo toca los IDs 1 a 100. Los posts creados por la API de administración usan IDs desde 1000 y no se ven afectados, pero la carga sí restaura los originales que hayas modificado o borrado.

## API REST

URL base (en *Database Actions → REST*):

```
https://<IDENTIFICADOR>-<NOMBRE_DB>.adb.<REGION>.oraclecloudapps.com/ords/demo
```

### Endpoints públicos (solo lectura)

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/posts/` | Lista paginada (25 por página) |
| GET | `/posts/{id}` | Un post por id |

```bash
curl "<URL_BASE>/posts/"
curl "<URL_BASE>/posts/1"
curl "<URL_BASE>/posts/?limit=5&offset=10"
curl -G "<URL_BASE>/posts/" --data-urlencode 'q={"user_id":3}'
```

La respuesta incluye `items`, `hasMore`, `limit`, `offset` y `links`.

### Endpoints protegidos (OAuth2)

| Método | Ruta | Descripción |
|---|---|---|
| POST | `/admin/posts/` | Crear post (devuelve `new_id`) |
| PUT | `/admin/posts/{id}` | Modificar post |
| DELETE | `/admin/posts/{id}` | Borrar post |

**1. Obtener el token** (válido 3600 s):

```bash
curl -s -u "<CLIENT_ID>:<CLIENT_SECRET>" \
     -d "grant_type=client_credentials" \
     "<URL_BASE>/oauth/token"
```

**2. Usarlo:**

```bash
curl -X POST "<URL_BASE>/admin/posts/" \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"user_id":1,"titulo":"Mi post","cuerpo":"Creado vía ORDS"}'
```

Sin token, estos endpoints responden `401 Unauthorized`.

## Solución de problemas

| Síntoma | Causa probable |
|---|---|
| `ORA-29273` / `ORA-12545` | URL en HTTP o puerto distinto de 443 |
| `ORA-29024` | Certificado no emitido por una CA pública conocida |
| `ORA-01031` | Faltan privilegios (`EXECUTE` sobre `DBMS_CLOUD`/`UTL_HTTP`, `CREATE JOB`) |
| `404` en la API | Esquema no habilitado, alias distinto de `api` o módulo sin `PUBLISHED` |
| `401` con token | Cliente sin rol concedido o credenciales incorrectas |
| `403` con token válido | Falta `OAUTH.GRANT_CLIENT_ROLE` o el patrón del privilegio no coincide |
| `items: []` | No se ejecutó `cargar_posts` o falta el `COMMIT` |
| Job en `FAILED` | Revisa `additional_info` en `USER_SCHEDULER_JOB_RUN_DETAILS` |


