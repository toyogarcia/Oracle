###################
#    JOINS
###################

#################
# INNER JOIN: Devuelve solo las filas que tienen coincidencia en ambas tablas. 
#################

# Mostrar los empleados y el nombre del departamento al que pertenecen (excluyendo a los que no tienen departamento o departamentos vacíos).
SELECT e.first_name, d.department_name
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id

SELECT e.first_name, d.department_name
FROM employees e,
     departments d
where e.department_id = d.department_id

#################
# LEFT OUTER JOIN: Devuelve todas las filas de la tabla izquierda (primera que escribes, la de la clausula FROM) y las coincidencias de la tabla derecha. Si no hay coincidencia en la derecha, muestra NULL.
#################

#  Mostrar todos los empleados, tengan o no un departamento asignado.
SELECT e.first_name, d.department_name
FROM employees e
LEFT OUTER JOIN departments d ON e.department_id = d.department_id

SELECT e.first_name, d.department_name
FROM employees e,  
     departments d
where e.department_id = d.department_id(+)

#################
# RIGHT OUTER JOIN: Devuelve todas las filas de la tabla derecha y las coincidencias de la tabla izquierda (primera que escribes, la de la clausula FROM). Si no hay coincidencia en la izquierda, muestra NULL.
#################

#  Mostrar todos los departamentos, aparezcan o no empleados en ellos.
SELECT e.first_name, d.department_name
FROM employees e
RIGHT OUTER JOIN departments d ON e.department_id = d.department_id

SELECT e.first_name, d.department_name
FROM employees e,
     departments d
where e.department_id(+) = d.department_id

#################
# FULL OUTER JOIN: Devuelve todas las filas de ambas tablas, rellenando con NULL donde no haya coincidencia.
#################

# Listar todos los empleados y todos los departamentos, enlazados si coinciden o solos si no tienen pareja.
SELECT e.first_name, d.department_name
FROM employees e
FULL OUTER JOIN departments d ON e.department_id = d.department_id

# FULL OUTER JOIN: No existe en la sintaxis antigua de Oracle.

#################
# CROSS JOIN (Producto cartesiano): Combina cada fila de la primera tabla con cada fila de la segunda tabla (multiplica filas: N × M).
#################

# lista cada empleado con cada departamento.
SELECT e.first_name, d.department_name
FROM employees e
CROSS JOIN departments d

SELECT e.first_name, d.department_name
FROM employees e,
     departments d

#################
# NATURAL JOIN: Oracle une automáticamente las tablas usando todas las columnas que tengan exactamente el mismo nombre en ambas tablas. (Se recomienda usar con precaución para evitar errores si cambian las columnas)
#################

SELECT e.first_name, d.department_name
FROM employees e
NATURAL JOIN departments d









