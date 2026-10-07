#####################
# REGULAR EXPRESSIONS
#####################

# Se usan con funciones nativas para buscar, validar o modificar patrones de texto complejos

# Metacaracteres más utilizados

# Carácter			Descripción										Ejemplo
# ---------         --------------------------------                ----------------------
# ^					Inicio de la cadena								^A (empieza con A)
# $					Final de la cadena								z$ (termina en z)
# .					Cualquier carácter (excepto salto de línea)		a.c (abc, a-c, etc.)
# [ ]				Conjunto de caracteres permitidos				[aeiou] (cualquier vocal)
# [^ ]				Negación del conjunto							[^0-9] (no es un dígito)
# *					0 o más repeticiones							a*
# +					1 o más repeticiones							[0-9]+ (uno o más dígitos)
# ?					0 o 1 repetición (opcional)						colou?r (colour o color)
# |					Operador lógico OR								cat|dog

#El parámetro [modificadores] (Match Parameters)
#     Este parámetro es común a las cuatro funciones. 
#     Se escribe entre comillas simples y acepta las siguientes letras (puedes combinarlas, por ejemplo 'iy'):
# 			Letra		Qué hace
#           -----       --------------------------
# 			i			Ignora mayúsculas y minúsculas (case-insensitive).
# 			c			Fuerza mayúsculas y minúsculas (case-sensitive, viene por defecto).
# 			n			Permite que el operador punto . coincida con caracteres de salto de línea.
# 			m			Trata el texto como múltiples líneas (hace que ^ y $ funcionen al inicio/fin de cada línea y no solo de todo el texto).
# 			x			Ignora los espacios en blanco dentro de tu expresión regular (útil para documentarla sin que afecte la búsqueda).

#############
# REGEXP_LIKE
#############
# Comprueba si una cadena cumple con un patrón (devuelve TRUE o FALSE). Se usa habitualmente en el WHERE.

# Sintaxis: REGEXP_LIKE( fuente, patron, [modificadores] )
# fuente: La cadena de texto o columna donde vas a buscar.
# patron: La expresión regular que define lo que buscas.
# [modificadores]: Letras opcionales para cambiar el comportamiento de la búsqueda.

# Buscar empleados cuyo correo electrónico pertenezca a un dominio específico (por ejemplo, Gmail):
SELECT nombre, email 
FROM empleados 
WHERE REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@gmail\.com$');

# Uso en restricciones (CHECK CONSTRAINT)
# Asegurar que una columna c1 solo contenga letras mayúsculas o minúsculas, rechazando números o símbolos:
CREATE TABLE t1 (
  c1 VARCHAR2(20),
  CONSTRAINT chk_solo_letras CHECK (REGEXP_LIKE(c1, '^[[:alpha:]]+$'))
)

###############
# REGEXP_SUBSTR
###############
# Extrae la subcadena que coincide con el patrón.

# Sintaxis: REGEXP_SUBSTR( fuente, patron, [posicion_inicio], [ocurrencia], [modificadores], [subexpresion] )
# fuente: El texto original.
# patron: La expresión regular.
# [posicion_inicio]: Dónde empieza a buscar (por defecto 1).
# [ocurrencia]: Qué coincidencia extraer si hay varias (por defecto 1).
# [modificadores]: Opciones de búsqueda
# [subexpresion]: Si usas paréntesis ( ) para agrupar, indica qué grupo específico quieres extraer. Si pones 1, solo te extraerá lo que esté dentro del primer par de paréntesis.

# Extraer solo la parte numérica de una cadena de código (por ejemplo, extraer 12345 de REF-12345-ABC)
SELECT REGEXP_SUBSTR('REF-12345-ABC', '[0-9]+') AS numero_extraido FROM DUAL;

################
# REGEXP_REPLACE
################
# Reemplaza las coincidencias del patrón con otra cadena.

# Sintaxis: REGEXP_REPLACE( fuente, patron, [cadena_reemplazo], [posicion_inicio], [ocurrencia], [modificadores] )
# fuente: El texto original.
# patron: La expresión regular que se va a borrar o sustituir.
# [cadena_reemplazo]: El texto que se va a poner en su lugar. Si lo dejas vacío o pones NULL, el patrón encontrado simplemente se elimina.
# [posicion_inicio]: Dónde empieza a buscar para reemplazar (por defecto 1).
# [ocurrencia]:
#		 0: Reemplaza todas las veces que aparezca el patrón (por defecto).
#		 Un número positivo (ej. 2): Reemplaza únicamente esa aparición específica.
# [modificadores]: Opciones de búsqueda

# Sustituir uno o más espacios en blanco consecutivos por un solo guion:
SELECT REGEXP_REPLACE('Oracle    SQL   es    potente', '\s+', '-') AS texto_limpio FROM DUAL;

##############
# REGEXP_INSTR
##############
# Devuelve la posición numérica donde inicia la coincidencia del patrón.

# Sintaxis: REGEXP_INSTR( fuente, patron, [posicion_inicio], [ocurrencia], [opcion_retorno], [modificadores], [subexpresion] )
# fuente: El texto donde se busca.
# patron: La expresión regular.
# [posicion_inicio]: El carácter exacto por el que empieza a buscar (por defecto es 1).
# [ocurrencia]: Si el patrón aparece varias veces, cuál quieres buscar. 1 para la primera, 2 para la segunda, etc. (por defecto es 1).
# [opcion_retorno]:
#		0: Devuelve la posición del primer carácter del patrón encontrado (por defecto).
#		1: Devuelve la posición del carácter siguiente al patrón encontrado.
# [modificadores]: Opciones de búsqueda.
# [subexpresion]: Si usas grupos con paréntesis ( ) en tu patrón, indica cuál de los grupos quieres rastrear (0 significa todo el patrón).

# Si tienes una cadena de texto mezclada y quieres saber exactamente en qué posición empieza el primer bloque de números:
SELECT REGEXP_INSTR('Código de producto: 481516-X', '[0-9]+') AS posicion_numero FROM DUAL

# tienes una dirección IP y quieres saber la posición del segundo punto:
SELECT REGEXP_INSTR('192.168.1.15', '\.', 1, 2) AS posicion_segundo_punto FROM DUAL

# buscar la posición justo después de un código postal de 5 dígitos:
SELECT REGEXP_INSTR('Madrid, CP 28001, España', '[0-9]{5}', 1, 1, 1) AS posicion_final FROM DUAL;
