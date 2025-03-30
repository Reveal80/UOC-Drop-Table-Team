-- PLANTILLA DE ENTREGA DE LA PARTE PRÁCTICA DE LAS ACTIVIDADES
-- --------------------------------------------------------------
-- Actividad: Fase3 - P3
--
-- Grupo: Cnv0325_Grupo04: Drop Table Team
-- 
-- Integrantes: 
-- 1. Francisco Manuel Puga Sáez
-- 2. Francisco Javier Ederer López
-- 3. Adrián Pérez López
--
-- Database: fp_204_3
-- --------------------------------------------------------------
--
-- B1. Parte Práctica.
--
-- Pregunta P1.B1. Mostrar aquellos eventos que se lleven a cabo durante el mes que coincida con el mes en curso.
-- (Ejemplo: si la consulta se hace en marzo, los eventos de marzo de 2008)
-- El listado deberá mostrar los siguientes campos, y estar ordenado por las semanas del mes (week):
-- eventid, eventname, caldate, week, coincideSemana (sí/no).
-- NOTA: Simulamos el numero de semana y el mes actual, en el mes actual como nos devuelve March tenemos que utilizar solo las 3 primeras letras usando LEFT 3 y pasandolas a Mayuscula con UPPER.
SELECT event.eventid, event.eventname, date.caldate, date.week,
  CASE 
    WHEN date.week = WEEK(CURDATE()) THEN 'si'
    ELSE 'no'
  END AS coincideSemana
FROM event
JOIN date ON event.dateid = date.dateid
WHERE date.month = UPPER(LEFT(MONTHNAME(CURDATE()), 3)) AND date.year = 2008
ORDER BY date.week;

--
-- Pregunta P2.B1. Mostrar cuántos usuarios que han comprado entradas para los eventos de la semana 9 son "locales". 
-- Se considera que un usuario es local, si el nombre de la ciudad donde se realiza el evento es igual a la ciudad natal del usuario, de lo contrario es un visitante.
-- La salida de la consulta deberá ser la siguiente.
-- Utilizar la función IF y agrupar.
-- NOTA: al comparar users.city = venue.venuecity nos hemos dado cuenta que hay ciudades que empiezan con un espacio ejemplo: ' Las vegas', para comprarlo bien debemos normalizar los datos que comparamos por eso usamos TRIM.
SELECT 
  IF( TRIM(UPPER(users.city)) = TRIM(UPPER(venue.venuecity)), 'Local', 'Visitante' ) AS tipo_usuario,
  COUNT(DISTINCT users.userid) AS cantidad_usuarios
FROM sales
JOIN users ON sales.buyerid = users.userid
JOIN listing ON sales.listid = listing.listid
JOIN event ON listing.eventid = event.eventid
JOIN date ON event.dateid = date.dateid
JOIN venue ON event.venueid = venue.venueid
WHERE date.week = 9 -- en la semana 9 solo hay visitantes, pero si probamos semana 5 o 7 veremos tambien locales.
GROUP BY tipo_usuario;

--
-- Pregunta P3.B1. Eliminar de la tabla users a todos aquellos usuarios registrados que no hayan comprado ni vendido ninguna entrada. 
-- Antes de eliminarlos, copiarlos a una tabla denominada backup_users para poder recuperarlos en caso de ser necesario.
-- NOTA: Cremos la tabla backup_users usando la misma estructura de users.
CREATE TABLE backup_users AS
SELECT * FROM users WHERE 1 = 0;
-- Copiamos los usuarios sin actividad en venta o compra en backups_users.
INSERT INTO backup_users
SELECT *
FROM users
WHERE userid NOT IN (SELECT buyerid FROM sales)
  AND userid NOT IN (SELECT sellerid FROM listing);
-- Borramos los usuarios que esten el backup_users en users.
DELETE FROM users
WHERE userid IN (
  SELECT userid FROM backup_users
);

--
-- Pregunta P4.B1. Mostrar una lista de usuarios donde se especifique para cada usuario si éste es un comprador (sólo ha comprado entradas), un vendedor (sólo ha vendido entradas) o ambos.
-- La salida de la consulta deberá ser la siguiente. Utilizar la función CASE y agrupar.
SELECT CASE WHEN users.userid IN (SELECT buyerid FROM sales) 
	AND users.userid IN (SELECT sellerid FROM listing) THEN 'Ambos'
    WHEN users.userid IN (SELECT buyerid FROM sales) THEN 'Comprador'
    WHEN users.userid IN (SELECT sellerid FROM listing) THEN 'Vendedor'
    ELSE 'Sin actividad'
  END AS tipo_usuario,
  COUNT(*) AS cantidad_usuarios
FROM users
GROUP BY tipo_usuario;

--
-- Pregunta P5.B1. Inventar una consulta que haga uso de una de las siguientes funciones: COALESCE, IFNULL, NULLIF.
-- Explicar su objetivo en los comentarios de la plantilla .sql
-- NOTA: Esta consulta muestra el nombre de los eventos, cuando empieza el evento y la hora de finalización (`endtime`). Usamos IFNULL para filtrar los que no tienen hora de finalizacion.
SELECT  event.eventid, event.eventname, event.starttime,  
IFNULL(event.endtime, 'No especificado') AS hora_finalizacion
FROM event
ORDER BY event.eventid
LIMIT 100;

--
-- B2. Funciones UDF
--
-- Pregunta P1.B2. Crear una función UDF llamada NombreResumido que reciba como parámetros un nombre y un apellido y retorne un nombre en formato (Inicial de Nombre + "." + Apellido en mayúsculas. Ejemplo: L. LANAU).
-- Probar la función en una consulta contra la tabla de socios y enviando directamente el nombre con tus datos en forma literal, por ejemplo escribir:
-- SELECT NombreResumido("Rita", "de la Torre") para probar la función, deberá devolver: R. DE LA TORRE.
DELIMITER //
CREATE FUNCTION NombreResumido(nombre VARCHAR(50), apellido VARCHAR(100))
RETURNS VARCHAR(200)
DETERMINISTIC
BEGIN
  RETURN CONCAT(UPPER(LEFT(nombre, 1)), '. ', UPPER(apellido));
END;
//
DELIMITER ;
-- Prueba:
SELECT NombreResumido("Rita", "de la Torre") AS nombre_procesado;

--
-- Pregunta P2.B2. Actualizar el campo VIP de la tabla de usuarios a sí a aquellos usuarios que hayan comprado más de 10 tickets para los eventos o aquellos que hayan vendido más de 25 tickets.
-- Nos hemos dado cuenta que los TRIGGER que creamos en la primera practica nos bloquea al modificar el campo VIP
-- por lo que hemos optado por borrarlos y volver a crearlos, pero que solo actue cuando modifiquemos el campo en cuestion.
-- Solo validar si el username cambia.
DROP TRIGGER IF EXISTS before_update_users_username;
DELIMITER $$
CREATE TRIGGER before_update_users_username
BEFORE UPDATE ON users
FOR EACH ROW
BEGIN
  IF NEW.username != OLD.username THEN
    IF NOT (
         NEW.username REGEXP '[A-Z]' AND
         NEW.username REGEXP '[a-z]' AND
         NEW.username REGEXP '[0-9]' AND
         NEW.username REGEXP '[-_#@]'
       ) THEN
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'El nombre de usuario debe contener al menos, una mayúscula, una minúscula, un dígito, y uno de los siguientes símbolos: -_@#';
    END IF;
  END IF;
END$$
DELIMITER ;

-- Solo validar si el email cambia
DROP TRIGGER IF EXISTS trg_validate_email_before_update;
DELIMITER $$
CREATE TRIGGER trg_validate_email_before_update
BEFORE UPDATE ON users
FOR EACH ROW
BEGIN
  IF NEW.email != OLD.email THEN
    IF NOT (NEW.email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$') THEN
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'El email tiene un formato incorrecto';
    END IF;
  END IF;
END$$
DELIMITER ;

-- Update de la tabla users VIP.
-- Si ejecutamos todo a la vez nos da error de desconexion por lo que hemos optado por crear una tabla temporal.
-- Crear tabla temporal para compradores.
CREATE TEMPORARY TABLE compradores_vip AS
SELECT sales.buyerid AS userid
FROM sales
JOIN listing ON sales.listid = listing.listid
GROUP BY sales.buyerid
HAVING SUM(listing.numtickets) > 10;
-- Crear tabla temporal para vendedores.
CREATE TEMPORARY TABLE vendedores_vip AS
SELECT sellerid AS userid
FROM listing
GROUP BY sellerid
HAVING SUM(numtickets) > 25;
-- Unimos ambas tablas.
CREATE TEMPORARY TABLE usuarios_vip AS
SELECT userid FROM compradores_vip
UNION
SELECT userid FROM vendedores_vip;
-- Update VIP en users usando la tabla temporal.
UPDATE users
JOIN usuarios_vip ON users.userid = usuarios_vip.userid
SET users.vip = 'si';
-- Borramos tablas temporales. Estas tablas se borran automaticamente al cerrar la sesion de MySQL Workbench, pero las borramos como buenas practicas.
DROP TEMPORARY TABLE IF EXISTS compradores_vip;
DROP TEMPORARY TABLE IF EXISTS vendedores_vip;
DROP TEMPORARY TABLE IF EXISTS usuarios_vip;

--
-- Pregunta P3.B2. Crear una función UDF llamada Pases_cortesía. Se regalará 1 pase de cortesía por cada 10 tickets comprados o vendidos, a los usuarios VIP. 
-- Hacer una consulta denominada pases_usuarios para probar la función y guardarla como una vista. 
-- Los campos de la misma deberán ser: userid, username, NombreResumido, número de pases.
-- Creamos una funcion llamada Pases_cortesia.
DELIMITER $$
CREATE FUNCTION Pases_cortesia(total_tickets INT)
RETURNS INT
DETERMINISTIC
BEGIN
  RETURN FLOOR(total_tickets / 10);
END$$
DELIMITER ;
-- Creamos la vista Pases_usuarios que se nos solicita.
CREATE OR REPLACE VIEW Pases_usuarios AS
SELECT users.userid, users.username, NombreResumido(users.firstname, users.lastname) AS NombreResumido,
  Pases_cortesía(
    IFNULL(tickets_comprados.total, 0) + IFNULL(tickets_vendidos.total, 0)
  ) AS numero_pases
FROM users
LEFT JOIN (
    SELECT sales.buyerid AS userid, SUM(listing.numtickets) AS total
    FROM sales
    JOIN listing ON sales.listid = listing.listid
    GROUP BY sales.buyerid
) AS tickets_comprados ON users.userid = tickets_comprados.userid
LEFT JOIN (
    SELECT sellerid AS userid, SUM(numtickets) AS total
    FROM listing
    GROUP BY sellerid
) AS tickets_vendidos ON users.userid = tickets_vendidos.userid
WHERE users.vip = 'si';

--
-- Pregunta P4.B2. La siguiente instrucción:
-- update mytable
-- set mycolumn = str_to_date(
-- concat(
--   floor(1 + rand() * (12-1)), '-',
--   floor(1 + rand() * (28-1)), '-',
--  floor(1 + rand() * (1998-1940) + 1940)),'%m-%d-%Y');
-- permite actualizar un campo fecha de una tabla con fechas aleatorias (en este caso el año de nacimiento estaría en el rango 1998-1940, y los días entre 1 y 28).
-- Sintaxis: select floor(rand()*(end - start) + start);
-- Actualizar el campo birthdate de la tabla users, creado en el P1.
UPDATE users
SET birthdate = STR_TO_DATE(
  CONCAT(
    FLOOR(1 + RAND() * 12), '-',       -- Mes entre 1 y 12
    FLOOR(1 + RAND() * 28), '-',       -- Día entre 1 y 28
    FLOOR(1940 + RAND() * (1999 - 1940)) -- Año entre 1940 y 1998
  ), '%m-%d-%Y'
);
-- Verificamos con la siguiente consulta.
SELECT birthdate FROM users LIMIT 10;

--
-- Pregunta P5.B2. Crear una función UDF llamada Kit_Eventos. Se regalará un kit a aquellos usuarios VIP que cumplan años durante el mes (que recibirá la función por parámetro). 
-- La función devolverá "Kit" o "-". Hacer una consulta pertinente para probar la función.
-- Cremos la funcion KIT_Eventos.
DELIMITER $$
CREATE FUNCTION Kit_Eventos(mes INT, cumple INT, es_vip VARCHAR(5))
RETURNS VARCHAR(10)
DETERMINISTIC
BEGIN
  IF es_vip = 'si' AND cumple = mes THEN
    RETURN 'Kit';
  ELSE
    RETURN '-';
  END IF;
END$$
DELIMITER ;
--
-- Esta consulta nos muestra 10, pero no indica que tengan KIT
SELECT userid, username, MONTH(birthdate) AS mes_cumple, VIP, Kit_Eventos(MONTH(CURDATE()), MONTH(birthdate), VIP) AS regalo_kit
FROM users
WHERE birthdate IS NOT NULL
ORDER BY userid
LIMIT 10;
-- Esta consulta filtra los que tienen Kit.
SELECT userid, username, MONTH(birthdate) AS mes_cumple, VIP, Kit_Eventos(MONTH(CURDATE()), MONTH(birthdate), VIP) AS regalo_kit
FROM users
WHERE birthdate IS NOT NULL
AND Kit_Eventos(MONTH(CURDATE()), MONTH(birthdate), VIP) = 'Kit'
ORDER BY userid
LIMIT 10;

--
-- Pregunta P6.B2. Inventar una función UDF que permita optimizar las operaciones de la Base de Datos. Justificarla.
-- Creamos una funcion para saber si el usuario esta o no activo.
DELIMITER $$
CREATE FUNCTION UsuarioActivo(user_id INT)
RETURNS VARCHAR(10)
DETERMINISTIC
BEGIN
  IF EXISTS (
    SELECT 1 FROM sales WHERE buyerid = user_id
    UNION
    SELECT 1 FROM listing WHERE sellerid = user_id
  ) THEN
    RETURN 'Activo';
  ELSE
    RETURN 'Inactivo';
  END IF;
END$$
DELIMITER ;
-- Probamos la funcion.
SELECT userid, username, UsuarioActivo(userid) AS Estado
FROM users
LIMIT 20;

--
-- B3. Variables de @usuario
-- 
-- Pregunta P1.B3. Hacer una vista llamada cumpleanhos. La consulta de la vista, deberá tener los siguientes campos: userid, username, NombreResumido, VIP, dia, mes, birthdate.
CREATE VIEW Cumpleanhos AS
SELECT userid, username, NombreResumido(firstname, lastname) AS NombreResumido, VIP, DAY(birthdate) AS dia, MONTH(birthdate) AS mes, birthdate
FROM users
WHERE birthdate IS NOT NULL;
-- Probamos la vista.
SELECT * FROM Cumpleanhos
ORDER BY mes, dia
LIMIT 20;

--
-- Pregunta P2.B3. Crear dos variables de usuario. Una denominada @esVIP y la otra @monthbirthday.
-- Asignar un valor a la variable @esVIP (true / false).
-- Asignar el valor del mes en curso a la variable @monthbirthday

SET @esVIP = 'si';
SET @monthbirthday = MONTH(CURDATE());

-- Probamos las variables.
SELECT userid, username, VIP, MONTH(birthdate) AS mes_cumple
FROM users
WHERE VIP = @esVIP
  AND MONTH(birthdate) = @monthbirthday;

--
-- Pregunta P3.B3.
-- Hacer una consulta basada en la vista cumpleanhos que utilice las variables de usuario para filtrar los cumpleañeros del mes en @monthbirthday cuyo valor en el campo VIP coincida con el asignado a la variable @esVIP.
SELECT *
FROM Cumpleanhos
WHERE mes = @monthbirthday
  AND VIP = @esVIP;