#################
# DECODE & CASE
#################

# Sirven para logica condicional dentro de una consulta.
# Ambos proporcionan una construccion de tipo:
#	If A = x then A1
#	else if A = y then A2
#	else X
	
# CASE puede hacer todo lo que hace DECODE, pero no al reves.

# Diferencias:
# 		CASE 														DECODE
#		----------------------------------------------------        -----------------------------------------------------
#		sentencia   												funcion
#		Puede trabajar con operadores = < > between like....        Solo trabaja con =
#		Puede trabajar con predicados y subquerys					Trabaja con experesiones que son valores escalares
#		Puede ser una construccion PL/SQL							Solo se usa en sentencias SQL
#		Se puede usar en PL/SQL para sustituir IF THEN ELSE			Solo se usa en sentencias SQL
#		Puede usarse como parametro de una funcion o procedure		NO Puede usarse como parametro
#		Consistencia de datos										No tiene consistencia de datos
#		ANSI SQL													Propietario de Oracle
#		Se ejecuta mas rápido en el optimizador.					Mas lento en optimizador.
		
# CASE:		
		SELECT first_name, 
			   salary,
			   CASE 
				   WHEN salary > 5000 THEN 'Alto'
				   ELSE 'Normal'
			   END AS nivel_salarial
		FROM employees
		
# DECODE:

		SELECT * 
		FROM employees 
		WHERE DECODE(department_id, 10, 'VIP', 'Normal') = 'VIP'
	  
		
		
			
