# Oracle UTL_HTTP + ORDS: consumir y publicar APIs REST desde Oracle Autonomous Database

Proyecto que muestra las dos caras de las APIs REST en Oracle:

Servicios REST: Es el concepto arquitectónico. Es la "autopista" y las reglas de tráfico para que dos sistemas se comuniquen en la web usando HTTP.
                Es un estándar de la industria. Utiliza los verbos HTTP estándar (GET, POST, PUT, DELETE) para intercambiar información (generalmente en formato JSON o XML).
				  

UTL_HTTP: 	Es una herramienta interna de la base de datos Oracle para consumir (llamar) servicios REST externos.
         	Saliente (De la Base de Datos hacia el mundo exterior)
			Actuar como un cliente web o navegador dentro de PL/SQL
			Requiere configurar la seguridad de la base de datos (ACLs - Access Control Lists) y si el sitio es HTTPS, debes configurar un Oracle Wallet con los certificados de seguridad
			
			• Operaciones:
				• GET: Traer información de una API externa (por ejemplo, consultar el clima actual o el tipo de cambio).
				• POST / PUT: Enviar datos de tus tablas a un sistema externo (por ejemplo, procesar un pago con Stripe o enviar un lead a un CRM).
				• DELETE: Solicitar la eliminación de un recurso en un servidor externo.


ORDS (Oracle REST Data Services): 	Es una herramienta de Oracle para crear (publicar) servicios REST a partir de tus datos y procedimientos almacenados.
									Entrante (Del mundo exterior hacia la Base de Datos)
									Actuar como una puerta de enlace (API Gateway) para la base de datos
									Es un puente Java que se coloca frente a tu base de datos Oracle.
									Traduce las peticiones HTTP/REST que envían aplicaciones externas en consultas SQL o ejecuciones PL/SQL dentro de la base de datos, y luego devuelve el resultado en formato JSON.
									Viene integrado con Oracle APEX, pero funciona de forma independiente para cualquier aplicación moderna (Angular, React, Node.js, etc.) que necesite interactuar con Oracle sin usar pesados drivers de base de datos.
				
									• Operaciones:
										• GET: Una app externa consulta datos de tus tablas (ej. GET /ords/hr/employees/).
										• POST / PUT: Una app externa inserta o actualiza registros en tus tablas (ej. registrar un nuevo usuario).
										• DELETE: Una app externa borra registros mediante una petición HTTP.

Cómo trabajan juntos (Ejemplo práctico)

	Imagina que tienes un sistema de facturación en Oracle:
	
		1. 	Una aplicación web de tus clientes necesita consultar una factura en tu base de datos. 
			La app web hace una petición HTTP a ORDS, y ORDS le devuelve la factura en un Servicio REST.

		2. 	Al mismo tiempo, tu base de datos necesita reportar esa factura al gobierno (Hacienda/DIAN/SAT). 
			Tu código PL/SQL usa UTL_HTTP para enviar la factura al Servicio REST del gobierno.




| Parte | Oracle actúa como... | Tecnología | Qué hacemos |
|-------|----------------------|------------|-------------|
| **1** | **Cliente** | `UTL_HTTP` + ACL (+ Wallet) | Llamar a una API pública con `GET`, `POST`, `PUT` y `DELETE` desde PL/SQL |
| **2** | **Servidor** | **ORDS** (Oracle REST Data Services) | Publicar una tabla como API REST y consumirla desde Postman, protegida con OAuth 2.0 |

Probado en **Oracle Autonomous Database – Always Free (OCI)**.

```
PARTE 1 (Oracle = cliente)                    PARTE 2 (Oracle = servidor)

 ┌──────────────┐  UTL_HTTP   ┌─────────────┐        ┌─────────┐   HTTPS   ┌──────────────┐
 │  PL/SQL      │────────────▶│ JSONPlace-  │        │ Postman │──────────▶│    ORDS      │
 │ API_CLIENTE  │◀────────────│ holder.com  │        └─────────┘◀──────────│ /ords/apidemo│
 └──────────────┘  HTTPS+ACL  └─────────────┘                              └──────┬───────┘
                                                                                    │ SQL
                                                                              ┌─────▼──────┐
                                                                              │ PRODUCTOS  │
                                                                              └────────────┘
```

---

## 📁 Estructura del proyecto

```
.
├── parte1_utl_http/
│   ├── 01_crear_usuario.sql            (ADMIN)    Crea el usuario APIDEMO
│   ├── 02_configurar_acl.sql           (ADMIN)    Permiso de red (ACL)
│   ├── 03_wallet_opcional.sql          (ADMIN)    Wallet propio (opcional en ADB)
│   ├── 04_test_conectividad.sql        (APIDEMO)  Prueba rápida
│   ├── 05_paquete_api_cliente_spec.sql (APIDEMO)  Paquete: especificación
│   ├── 06_paquete_api_cliente_body.sql (APIDEMO)  Paquete: cuerpo
│   ├── 07_test_get.sql                 (APIDEMO)  GET
│   ├── 08_test_post.sql                (APIDEMO)  POST
│   ├── 09_test_put.sql                 (APIDEMO)  PUT
│   └── 10_test_delete.sql              (APIDEMO)  DELETE
├── parte2_ords/
│   ├── 11_crear_tabla_productos.sql         (APIDEMO)  Tabla + datos
│   ├── 12_habilitar_ords_esquema.sql        (APIDEMO)  Habilitar esquema en ORDS
│   ├── 13_habilitar_ords_tabla_autorest.sql (APIDEMO)  Endpoints CRUD (AutoREST)
│   └── 14_proteger_con_oauth2.sql           (APIDEMO)  Seguridad OAuth 2.0
├── postman/
│   ├── 01_JSONPlaceholder.postman_collection.json
│   ├── 02_ORDS_Productos.postman_collection.json
│   └── ORDS_environment.postman_environment.json
└── limpieza/
    └── 99_limpieza.sql                 (ADMIN)    Elimina todo
```

Los scripts están **numerados en el orden en que debes ejecutarlos** y cada uno indica al inicio con qué usuario ejecutarlo, qué hace y qué resultado esperar.

---

## ✅ Requisitos

1. Cuenta de **Oracle Cloud (OCI) Free Tier** con una **Autonomous Database Always Free** creada (cualquier carga de trabajo: Transaction Processing / JSON / APEX).
2. La contraseña del usuario `ADMIN` de esa base de datos.
3. [Postman](https://www.postman.com/downloads/) (app de escritorio o web).
4. Un navegador. No necesitas instalar nada más: usamos **Database Actions** (SQL en el navegador).

> **¿Cómo abrir SQL en el navegador?** Consola OCI → *Oracle Database* → *Autonomous Database* → tu base de datos → **Database actions** → **SQL**.

---

## 🚀 Guía de ejecución

> En Database Actions ejecuta cada archivo con **Ejecutar script (F5)**, no con "Ejecutar sentencia" (Ctrl+Enter), para que se lancen todas las sentencias.
> Copia/pega el contenido de cada archivo en la hoja de trabajo.

### Parte 1 – Oracle consume una API (UTL_HTTP)

| Paso | Script | Usuario | Resultado esperado |
|------|--------|---------|--------------------|
| 1 | `01_crear_usuario.sql` | ADMIN | Usuario `APIDEMO` creado (**cambia la contraseña antes**) |
| 2 | `02_configurar_acl.sql` | ADMIN | `DBA_HOST_ACES` muestra el host con privilegio HTTP |
| 3 | `03_wallet_opcional.sql` | ADMIN | *Opcional.* Solo si el paso 4 da `ORA-29024` |
| 4 | `04_test_conectividad.sql` | APIDEMO | `Código HTTP : 200` |
| 5 | `05_paquete_api_cliente_spec.sql` | APIDEMO | Paquete creado sin errores |
| 6 | `06_paquete_api_cliente_body.sql` | APIDEMO | Cuerpo creado sin errores |
| 7 | `07_test_get.sql` | APIDEMO | `HTTP 200 OK` + datos del post |
| 8 | `08_test_post.sql` | APIDEMO | `HTTP 201 Created` + `id: 101` |
| 9 | `09_test_put.sql` | APIDEMO | `HTTP 200 OK` + datos modificados |
| 10 | `10_test_delete.sql` | APIDEMO | `HTTP 200 OK` + `{}` |

**Conectarte como `APIDEMO`:** abre Database Actions cambiando `admin` por `apidemo` en la URL
(`.../ords/apidemo/_sdw/?nav=worksheet`). Usa una ventana de incógnito para mantener también la sesión de ADMIN.

**Comprobar con Postman:** importa `postman/01_JSONPlaceholder.postman_collection.json` y ejecuta cada petición. El resultado debe coincidir con el que muestra Oracle. Con *Run collection* los tests deben salir en verde.

> ℹ️ **Nota sobre la API pública:** [JSONPlaceholder](https://jsonplaceholder.typicode.com) *simula* las escrituras: responde `201`/`200` pero **no guarda nada**. Es lo esperado y sirve para ver el funcionamiento sin efectos secundarios.

### Parte 2 – Oracle publica una tabla como API (ORDS)

| Paso | Script | Usuario | Resultado esperado |
|------|--------|---------|--------------------|
| 11 | `11_crear_tabla_productos.sql` | APIDEMO | Tabla `PRODUCTOS` con 5 filas |
| 12 | `12_habilitar_ords_esquema.sql` | APIDEMO | Esquema `ENABLED` con alias `apidemo` |
| 13 | `13_habilitar_ords_tabla_autorest.sql` | APIDEMO | Endpoints CRUD operativos (abiertos) |
| 14 | `14_proteger_con_oauth2.sql` | APIDEMO | Endpoints protegidos; obtienes `client_id`/`client_secret` |

**Probar con Postman:**

1. Obtén tu URL base (paso 12.3 del script 12): `https://<host>/ords/apidemo`
2. Importa en Postman las dos piezas de `postman/`: la colección `02_ORDS_Productos...` y el entorno `ORDS_environment...`.
3. Selecciona el entorno y rellena `ords_base`.
4. Lanza la carpeta **1 – Sin autenticación** (tras el script 13).
5. Ejecuta el script 14, copia `client_id` y `client_secret` al entorno y lanza la carpeta **2 – Con OAuth2**.
6. Repite la carpeta 1: ahora debe devolver **401 Unauthorized**. 🔒

Endpoints generados (AutoREST):

| Método | URL | Acción |
|--------|-----|--------|
| GET | `/ords/apidemo/productos/` | Lista paginada |
| GET | `/ords/apidemo/productos/{id}` | Un producto |
| GET | `/ords/apidemo/productos/?q={"precio":{"$gt":50}}` | Filtrar |
| POST | `/ords/apidemo/productos/` | Crear |
| PUT | `/ords/apidemo/productos/{id}` | Actualizar |
| DELETE | `/ords/apidemo/productos/{id}` | Borrar |

Ejemplo de `curl` (tras el script 13, antes de proteger):

```bash
curl "https://<host>/ords/apidemo/productos/"
curl -X POST "https://<host>/ords/apidemo/productos/" \
     -H "Content-Type: application/json" \
     -d '{"nombre":"Cable HDMI","precio":9.99,"stock":100}'
```

Con OAuth2:

```bash
TOKEN=$(curl -s -u "<client_id>:<client_secret>" \
        -d "grant_type=client_credentials" \
        "https://<host>/ords/apidemo/oauth/token" | jq -r .access_token)
curl -H "Authorization: Bearer $TOKEN" "https://<host>/ords/apidemo/productos/"
```

---

## 🧠 Conceptos clave

| Concepto | Explicación sencilla |
|----------|----------------------|
| **UTL_HTTP** | Paquete PL/SQL para hacer peticiones HTTP/HTTPS desde la base de datos. |
| **ACL** | Lista blanca de red: indica qué usuario puede conectarse a qué host y puerto. Sin ella, `ORA-24247`. |
| **Wallet** | Almacén de certificados de confianza para validar HTTPS. En Autonomous Database ya hay uno por defecto, por eso el script 03 es opcional. |
| **ORDS** | Servicio que convierte peticiones HTTP en SQL y devuelve JSON. Viene integrado en Autonomous Database. |
| **AutoREST** | Genera automáticamente los endpoints CRUD de una tabla con una sola llamada. |
| **OAuth2 client_credentials** | Flujo en el que una aplicación cambia `client_id` + `client_secret` por un token temporal. |

---

## 🛠️ Solución de problemas

| Error | Causa | Solución |
|-------|-------|----------|
| `ORA-24247: network access denied by access control list` | Falta la ACL o el principal está mal escrito | Repite el script 02 (usuario en **MAYÚSCULAS**) |
| `ORA-29024: Certificate validation failure` | La CA de la API no está en el wallet por defecto | Usa el script 03 y `api_cliente.set_wallet(...)` |
| `ORA-29273: HTTP request failed` + `ORA-12545/29261` | Problema de red o DNS | Verifica el host; comprueba que tu ADB permite salida a internet (endpoint público) |
| `ORA-01031: insufficient privileges` en `UTL_HTTP` | No se concedió `EXECUTE` | Repite el paso 1.3 del script 01 |
| HTTP `403` desde la API pública | La API rechaza peticiones sin `User-Agent` | Ya se envía; si usas otra API revisa sus requisitos |
| Postman: `404` en ORDS | Esquema/tabla sin habilitar o URL mal escrita | Revisa scripts 12 y 13 y la variable `ords_base` |
| Postman: `401` en ORDS | Hay protección activa (script 14) | Usa la carpeta 2 y obtén un token |
| `ORA-01940: cannot drop a user that is currently connected` | Sesión de APIDEMO abierta | Cierra Database Actions de APIDEMO y repite el script 99 |

---

## 🧹 Limpieza

Ejecuta `limpieza/99_limpieza.sql` como **ADMIN** para eliminar la ACL, la habilitación ORDS y el usuario `APIDEMO` con todos sus objetos.

---

## 📚 Referencias

- [UTL_HTTP – Oracle Database PL/SQL Packages Reference](https://docs.oracle.com/en/database/oracle/oracle-database/19/arpls/UTL_HTTP.html)
- [Oracle REST Data Services](https://docs.oracle.com/en/database/oracle/oracle-rest-data-services/)
- [Autonomous Database: llamadas HTTP salientes](https://docs.oracle.com/en/cloud/paas/autonomous-database/serverless/adbsb/)
- [JSONPlaceholder](https://jsonplaceholder.typicode.com)

