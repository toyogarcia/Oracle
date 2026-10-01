############################################################################################
#
# Referencias: https://blogs.oracle.com/connect/bulk-processing-with-bulk-collect-and-forall
#              https://mundodb.es/bulk-collect-ejemplos
#
############################################################################################

# GENERAL
# La clave de esta técnica es reducir el context swith entre el motor ejecutor de PL/SQL y el motor ejecutor de SQL.
# Por ejemplo para actualizar los salarios de los empleados se puede hacer:
# 1.- bucle for loop para seleccionar los empleados y por cada empleado hacer la actualización.  
#	  Problema: Tantos context swith como registros a actualizar.
# 2.- Actualizando los registros directamente con un UPDATE. Un solo context swith. 
#     Problema: Si en los registros necesitamos hacer cualquier acción (verificación, etc) antes del update, no se puede ya que actualiza todo de golpe.
# SOLUCION: Usar BULL COLLECT FOR ALL. Permite devolver los datos en una sola busqueda y procesarlos de modo eficiente en un solo context switch. 

# BULK COLLECT: Sentencias select que devuelven multiples filas en una sola busqueda mejorando la velocidad de devolución de datos.Bulk collect no es aplicable a dblinks.
#               Colecciones Densas (Sin Huecos):
#                   Las colecciones rellenadas con BULK COLLECT son siempre densas (dense). Esto significa que no existen "huecos" entre los índices (por ejemplo, no saltará del índice 5 al 7).
# 					Puedes recorrer la colección de forma segura utilizando un bucle clásico FOR i IN 1 .. coleccion.COUNT.
#               Cláusula LIMIT
#                   Cuando procesas grandes volúmenes de datos, es obligatorio usar BULK COLLECT junto con FETCH ... LIMIT. 
#                   Al hacer esto, los índices se comportan de la siguiente manera:
#                   En cada iteración del bucle, los índices se reinician. El primer registro de ese "lote" (batch) vuelve a ser el índice 1.
#                   Si el lote recupera 100 filas, los índices irán del 1 al 100. En la siguiente iteración, si recupera 50 filas, los índices irán del 1 al 50.
# 				Colecciones de Registros (Records) e Índices
#                   Si haces un BULK COLLECT de varias columnas en una colección de tipos basados en objetos o registros (%ROWTYPE o un TYPE RECORD personalizado):
#                       El índice de la colección identifica la fila completa.
#                       Para acceder a un campo específico, la sintaxis correcta es coleccion(indice).nombre_columna.

# FORALL: operaciones INSERT, UPDATE, and DELETE que usan colecciones. FORALL permite sin cambio de contexto realizar una sentencia DML de manera masiva.
#         FORALL no es un bucle, es una sentencia declarativa: “Genera todas las sentencias DML y envialas al motor SQL con un solo context switch.”
#         PL/SQL declara el iterador de FORALL como integer. No se necesita ni se debe declarar una variable con el mismo nombre.
#         Cada sentencia FORALL solo debe contener una sentencia DML. Si tienes que hacer dos updates y un delete necesitaras escribir tres sentencias FORALL.
#         Uso de Índices en la cláusula FORALL
#         Si utilizas la colección cargada con BULK COLLECT para realizar operaciones DML masivas (INSERT, UPDATE, DELETE) mediante FORALL:
#                FORALL requiere un puntero o índice para iterar. La sintaxis estándar es FORALL i IN coleccion.FIRST .. coleccion.LAST.
#                Dado que BULK COLLECT garantiza que la colección es densa, este rango (FIRST .. LAST) funcionará perfectamente y sin errores de "elemento no encontrado".

###############
# BULK COLLECT
###############

###
# USO BASICO CON SELECT -> Recupera datos de una tabla en colecciones
###

DECLARE
  TYPE t_id IS TABLE OF employees.employee_id%TYPE;
  TYPE t_salarios IS TABLE OF employees.salary%TYPE;
  
  v_id  t_id;
  v_salarios t_salarios;
BEGIN
  -- Carga masiva en una sola operación
  SELECT employee_id, salary
  BULK COLLECT INTO v_id, v_salarios
  FROM employees
  WHERE department_id = 80;
  
  -- Recorrer la colección resultante
  FOR i IN 1 .. v_id.COUNT LOOP
    DBMS_OUTPUT.PUT_LINE('Empleado: ' || v_id(i) || ' - Salario: ' || v_salarios(i));
  END LOOP;
  
  DBMS_OUTPUT.PUT_LINE ('TOTAL REGISTROS: '||v_id.COUNT);
END;
/

###
# USO CON CURSORES Y LA CLAUSULA LIMIT -> Evita agotar la memoria PGA de la sesión al consultar tablas con millones de filas.
###

DECLARE

  c_limit PLS_INTEGER := 10;

  CURSOR c_empleados IS 
    SELECT employee_id, first_name, salary FROM employees;
    
  TYPE t_empleados IS TABLE OF c_empleados%ROWTYPE;
 
 v_empleados t_empleados;

BEGIN
  OPEN c_empleados;

  LOOP
    -- Recupera los registros en bloques de 10 en 10
    FETCH c_empleados BULK COLLECT INTO v_empleados LIMIT c_limit;
    
    EXIT WHEN v_empleados.COUNT = 0;
    
    -- Procesar el bloque actual
    FOR i IN 1 .. v_empleados.COUNT LOOP
      -- Lógica de negocio por cada registro
      DBMS_OUTPUT.PUT_LINE('Empleado: ' || v_empleados(i).employee_id || ' - Nombre: ' || v_empleados(i).first_name|| ' - Salario: ' || v_empleados(i).salary);
    END LOOP;
    
  END LOOP;
  CLOSE c_empleados;
END;
/

########################
# BULK COLLECT + FORALL
########################

##########
# INSERT
##########

# Insertamos en una tabla todos los empleados de un departamento concreto de otra.

DECLARE
  TYPE t_empleados IS TABLE OF employees%ROWTYPE;
  l_empleados t_empleados;
  
  -- Variables para rastrear el error
  errors_count NUMBER;
  error_index  NUMBER;
  error_code   NUMBER;
BEGIN
  -- Simulación de carga masiva de datos en la colección
  SELECT * BULK COLLECT INTO l_empleados FROM employees WHERE department_id = 50;

  BEGIN
    -- Agregamos SAVE EXCEPTIONS al final de la instrucción FORALL
    FORALL i IN 1..l_empleados.COUNT SAVE EXCEPTIONS
      INSERT INTO empleados_respaldo (employee_id, first_name, salary)
      VALUES (l_empleados(i).employee_id, l_empleados(i).first_name, l_empleados(i).salary);
      
  EXCEPTION
    WHEN OTHERS THEN
      -- Capturamos el error genérico de procesamiento en lote (ORA-24381)
      IF SQLCODE = -24381 THEN
        errors_count := SQL%BULK_EXCEPTIONS.COUNT;
        DBMS_OUTPUT.PUT_LINE('Se encontraron ' || errors_count || ' errores durante el INSERT.');
        
        -- Recorremos la colección de errores para ver el detalle
        FOR j IN 1..errors_count LOOP
          error_index := SQL%BULK_EXCEPTIONS(j).ERROR_INDEX; -- Índice de la colección que falló
          error_code  := SQL%BULK_EXCEPTIONS(j).ERROR_CODE;  -- Código de error de Oracle
          
          DBMS_OUTPUT.PUT_LINE('Fallo en el índice: ' || error_index || 
                               ' | ID Empleado: ' || l_empleados(error_index).employee_id || 
                               ' | Error Oracle: ORA-' || error_code);
        END LOOP;
      ELSE
        -- Si es un error completamente ajeno al FORALL, lo volvemos a lanzar
        RAISE;
      END IF;
  END;

  COMMIT;
END;
/

##########
# UPDATE
##########

# En este caso actualizamos los salarios de dos empleados a pelo para ver la sintaxis pero normalmente se cargarian en la coleccion los empleados a actualizar a partir de una select con BULK

DECLARE
  TYPE t_ids IS TABLE OF empleados_respaldo.employee_id%TYPE;
  TYPE t_sueldos IS TABLE OF empleados_respaldo.salary%TYPE;
  
  l_ids     t_ids := t_ids(120, 122); -- id de los registros a actualizar
  l_sueldos t_sueldos := t_sueldos(10000, 10500);  -- aumento de salario
BEGIN
  BEGIN
    FORALL i IN 1..l_ids.COUNT SAVE EXCEPTIONS
      UPDATE empleados_respaldo
      SET salary_inc = salary + l_sueldos(i)
      WHERE employee_id = l_ids(i);
      
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE = -24381 THEN
        FOR j IN 1..SQL%BULK_EXCEPTIONS.COUNT LOOP
          -- Mostramos qué ID específico causó el problema
          DBMS_OUTPUT.PUT_LINE('Error actualizando ID: ' || l_ids(SQL%BULK_EXCEPTIONS(j).ERROR_INDEX) || 
                               ' | Código de Error: ORA-' || SQL%BULK_EXCEPTIONS(j).ERROR_CODE);
        END LOOP;
      ELSE
        RAISE;
      END IF;
  END;

  COMMIT;
END;
/

##########
# BORRADO
##########

# En este caso borramos un empleado a pelo para ver la sintaxis pero normalmente se cargarian en la coleccion los empleados a borrar  a partir de una select con BULK
DECLARE
  TYPE t_emps IS TABLE OF empleados_respaldo.employee_id%TYPE;
  l_emps t_emps := t_emps(120); 
BEGIN
  BEGIN
    FORALL i IN 1..l_emps.COUNT SAVE EXCEPTIONS
      DELETE FROM empleados_respaldo
      WHERE employee_id = l_emps(i);
      
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE = -24381 THEN
        FOR j IN 1..SQL%BULK_EXCEPTIONS.COUNT LOOP
          DBMS_OUTPUT.PUT_LINE('No se pudo borrar el empleado: ' || l_emps(SQL%BULK_EXCEPTIONS(j).ERROR_INDEX) || 
                               ' | Razón: ORA-' || SQL%BULK_EXCEPTIONS(j).ERROR_CODE);
        END LOOP;
      ELSE
        RAISE;
      END IF;
  END;

  COMMIT;
END;
/








