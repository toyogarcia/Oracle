############################################################################################
#
# Referencias: https://blogdeaitor.wordpress.com/2013/02/06/trabajar-con-xml-en-oracle/
#
############################################################################################

# GENERAL

# Para almacenar información en formato XML en una tabla Oracle, tenemos la opción de crear atributos CLOB (Character Large Object) o XMLType. 
# Aunque ambos son válidos, si vamos a utilizarlos como simples contenedores y la gestión de información la haremos desde una aplicación externa, puede ser mejor opción crear un atributo del tipo CLOB. 
# Los atributos CLOB guardarán nuestro XML básicamente como texto plano. 
# En cambio, si queremos poder trabajar con el contenido de estos atributos directamente desde la base de datos, puede resultar más cómodo hacerlo con atributos del tipo XMLType.
# El contenido almacenado está ya preparado y listo para ser utilizado. Además el XML es validado antes de poder ser almacenado en la tabla y en caso de error Oracle devuelve error.
# Sin embargo si se almacena como CLOB se almacenará aunque el XML contenga un error.
# Debemos tener en cuenta que el nombre de las etiquetas es case sensitive con lo cual deberemos escribirlas exactamente igual como las hemos creado en nuestro tipo XMLType.

##########################
# TABLAS/REGISTROS EJEMPLO
##########################

# Tabla ejemplo 1
CREATE TABLE alumnosXMLType
( 
  id number PRIMARY KEY,
  alumno XMLType
);

# Tabla ejemplo 2
CREATE TABLE alumnosClob
( 
  id number PRIMARY KEY,
  alumno Clob
);

####################
# INSERCION DE DATOS
####################

INSERT INTO alumnosXMLType
     VALUES(1, XMLType('<?xml version="1.0"?>
                    <ALUMNO>
                       <NOMBRE>Aitor</NOMBRE>
                       <APELLIDOS>Díaz</APELLIDOS>
                       <DIRECCION>
                          <CALLE>Mimoses S/N</CALLE>
                          <POBLACION>San Boi de Llobregat</POBLACION>
                          <PROVINCIA>Barcelona</PROVINCIA>
                       </DIRECCION>
                       <CURSO>1</CURSO>
                    </ALUMNO>'));

INSERT INTO alumnosClob
     VALUES(1, '<?xml version="1.0"?>
                    <ALUMNO>
                       <NOMBRE>Aitor</NOMBRE>
                       <APELLIDOS>Díaz</APELLIDOS>
                       <DIRECCION>
                          <CALLE>Mimoses S/N</CALLE>
                          <POBLACION>San Boi de Llobregat</POBLACION>
                          <PROVINCIA>Barcelona</PROVINCIA>
                       </DIRECCION>
                       <CURSO>1</CURSO>
                    </ALUMNO>');

# Si intentamos insertar un XML con errores en la tabla alumnosClob se inserta pero en la tabla alumnosXMLType se valida el XML y devuelve error.
# El error es: <NOMBRE>Aitor<NOMBRE>

INSERT INTO alumnosClob
     VALUES(2, '<?xml version="1.0"?>
                    <ALUMNO>
                       <NOMBRE>Aitor<NOMBRE>
                       <APELLIDOS>Díaz</APELLIDOS>
                       <DIRECCION>
                          <CALLE>Mimoses S/N</CALLE>
                          <POBLACION>San Boi de Llobregat</POBLACION>
                          <PROVINCIA>Barcelona</PROVINCIA>
                       </DIRECCION>
                       <CURSO>1</CURSO>
                    </ALUMNO>');

INSERT INTO alumnosXMLType
     VALUES(2, XMLType('<?xml version="1.0"?>
                    <ALUMNO>
                       <NOMBRE>Aitor<NOMBRE>
                       <APELLIDOS>Díaz</APELLIDOS>
                       <DIRECCION>
                          <CALLE>Mimoses S/N</CALLE>
                          <POBLACION>San Boi de Llobregat</POBLACION>
                          <PROVINCIA>Barcelona</PROVINCIA>
                       </DIRECCION>
                       <CURSO>1</CURSO>
                    </ALUMNO>'));

# Devuelve:
# SQL Error: ORA-64464: XML event error
# ORA-19202: Error occurred in XML processing
# In line 11 of orastream:
# LPX-00225: end-element tag "ALUMNO" does not match start-element tag "NOMBRE"

####################
# SELECCION DE DATOS
####################

select * from alumnosXMLType;

select * from alumnosClob;

select a.alumno.extract('/ALUMNO/NOMBRE').getStringVal()  -- Devuelve <NOMBRE>Aitor</NOMBRE>
from alumnosXMLType a
where id=1;

select a.alumno.extract('/ALUMNO/NOMBRE/text()').getStringVal()  -- Devuelve Aitor
from alumnosXMLType a
where id=1;

select a.alumno.extract('/ALUMNO/DIRECCION/POBLACION/text()').getStringVal() -- Devuelve San Boi de Llobregat
from alumnosXMLType a
where id=1 AND a.alumno.extract('/ALUMNO/NOMBRE/text()').getStringVal() = 'Aitor';

SELECT a.alumno.extract('/ALUMNO/DIRECCION/POBLACION/text()').getStringVal()
FROM alumnosXMLType a
WHERE a.alumno.extract('/ALUMNO/NOMBRE/text()').getStringVal() = 'Aitor' 
 AND a.alumno.extract('/ALUMNO/DIRECCION/PROVINCIA/text()').getStringVal()='Barcelona';
 
# A la hora de realizar comparaciones o condiciones con contenidos almacenados en campos XMLType, podemos utilizar la función llamada existsNode().
# Devuelve 1 si se cumple la condición de su interior o, de lo contrario, nos devolverá 0.

SELECT a.alumno.extract('/ALUMNO/DIRECCION/POBLACION/text()').getStringVal()
FROM alumnosXMLType a
WHERE a.alumno.existsNode('/ALUMNO[NOMBRE="Aitor" and DIRECCION/PROVINCIA="Barcelona"]')=1;

########################
# ACTUALIZACION DE DATOS
########################

UPDATE alumnosXMLType a
   SET  a.alumno = XMLType('<?xml version="1.0"?>
                    <ALUMNO>
                       <NOMBRE>Aitor</NOMBRE>
                       <APELLIDOS/>
                       <DIRECCION>
                          <CALLE>Bonavista S/N</CALLE>
                          <POBLACION>Cornella de Llobregat</POBLACION>
                          <PROVINCIA>Barcelona</PROVINCIA>
                       </DIRECCION>
                       <CURSO>1</CURSO>
                    </ALUMNO>')
WHERE a.alumno.EXTRACT('/ALUMNO/NOMBRE/text()').getStringVal() like 'A%r';

# UPDATEXML() que nos permite modificar partes concretas de un documento XML dado (únicamente queremos modificar el contenido de una etiqueta).
# Actualiza la provincia a Girona

UPDATE alumnosXMLType a
SET alumno =  UPDATEXML(alumno,'//DIRECCION/PROVINCIA/text()', 'Girona') 
WHERE a.alumno.EXTRACT('//NOMBRE/text()').getStringVal() = 'Aitor';

UPDATE alumnosxmltype a
SET alumno =  UPDATEXML(alumno, 
'//DIRECCION/PROVINCIA/text()', 'Barcelona',
'//DIRECCION/POBLACION/text()', 'Sant Boi de Llobregat'
) 
WHERE a.alumno.existsNode('/ALUMNO[NOMBRE="Aitor"]')=1;


##################
# BORRADO DE DATOS
##################
 
DELETE FROM alumnosXMLType a
WHERE a.alumno.extract('/ALUMNO/NOMBRE/text()').getStringVal()='Aitor';
