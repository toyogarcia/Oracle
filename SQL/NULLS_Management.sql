<<<<<<< HEAD
##################
# NULLs management
##################

# NVL()
#	La función NVL en Oracle SQL sirve para reemplazar un valor nulo (NULL) por otro valor alternativo especificado.
#	Ambos argumentos deben tener el mismo tipo de dato o ser compatibles, ya que Oracle intentará hacer una conversión implícita.
#	Es util para asegurarse de que un campo o expresion siempre tienen un valor.
	
	select first_name, nvl(department_id, 0) from employees

# NVL2()
#	NVL2 chequea si la primera expresion es NULL:
#		Si no es NULL devuelve la segunda expresion.
#		Si es NULL devuelve la tercera expresion.
=======
NULLs management
================

NVL()
	La función NVL en Oracle SQL sirve para reemplazar un valor nulo (NULL) por otro valor alternativo especificado.
	Ambos argumentos deben tener el mismo tipo de dato o ser compatibles, ya que Oracle intentará hacer una conversión implícita.
	Es util para asegurarse de que un campo o expresion siempre tienen un valor.
	
	SELECT nombre, NVL(comision, 0) AS comision_total FROM empleados;

NVL2()

	NVL2 chequea si la primera expresion es NULL:
		Si no es NULL devuelve la segunda expresion.
		Si es NULL devuelve la tercera expresion.
>>>>>>> 6153ead6e9d5e42e7d7f709e3ad1a71e755f1eee
		
	SELECT NVL2(NULL, 'Not Null', 'Is Null')    AS Result FROM DUAL; -- Output: 'Is Null'
	SELECT NVL2('Hello', 'Not Null', 'Is Null') AS Result FROM DUAL; -- Output: 'Not Null'
	
<<<<<<< HEAD
# COALESCE()
#	La función COALESCE de Oracle devuelve el primer valor que no sea nulo (NULL) de una lista de expresiones.
#	Revisa los valores en el orden en que los escribes.
#	Si el primer valor no es nulo, lo devuelve y se detiene.
#	Si es nulo, pasa al siguiente valor y repite el proceso.
#	Si todos los valores son nulos, devuelve NULL.
#	Utiliza evaluación de cortocircuito: no evalúa los elementos restantes una vez que encuentra un valor no nulo.
#	Requiere al menos dos expresiones.
	
	SELECT COALESCE(NULL, NULL, 'Valor Encontrado', 'Otro Valor') FROM dual;
	
# NULLIF()
#	La función NULLIF compara dos expresiones y devuelve NULL si son iguales, o el valor de la primera expresión si son diferentes.
=======
COALESCE()

	La función COALESCE de Oracle devuelve el primer valor que no sea nulo (NULL) de una lista de expresiones.
	Revisa los valores en el orden en que los escribes.
	Si el primer valor no es nulo, lo devuelve y se detiene.
	Si es nulo, pasa al siguiente valor y repite el proceso.
	Si todos los valores son nulos, devuelve NULL.
	Utiliza evaluación de cortocircuito: no evalúa los elementos restantes una vez que encuentra un valor no nulo.
	Requiere al menos dos expresiones.
	
	SELECT COALESCE(NULL, NULL, 'Valor Encontrado', 'Otro Valor') FROM dual;
	
	Este ejemplo devuelve 'Valor Encontrado' porque es el primer elemento que no es nulo en la lista.

NULLIF()

	La función NULLIF compara dos expresiones y devuelve NULL si son iguales, o el valor de la primera expresión si son diferentes.
>>>>>>> 6153ead6e9d5e42e7d7f709e3ad1a71e755f1eee
	
	SELECT NULLIF(10, 10) FROM dual;  -- Resultado: NULL (porque son iguales)
	SELECT NULLIF(10, 20) FROM dual;  -- Resultado: 10   (porque son diferentes)

