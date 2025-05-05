-- PLANTILLA DE ENTREGA DE LA PARTE PRÁCTICA DE LAS ACTIVIDADES
-- --------------------------------------------------------------
-- Actividad: Fase3 - P5
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

-- PREGUNTA 1: Crear manualmente (CREATE TABLE) una tabla denominada shows_semanales. Agregar los siguientes campos:
-- año: smallint
-- mes: char(5)
-- semana: smallint
-- catname: varchar(10)
-- eventname: varchar(200)
-- localidad: varchar(15)
-- starttime timestamp
CREATE TABLE shows_semanales (
    anio SMALLINT,
    mes CHAR(5),
    semana SMALLINT,
    catname VARCHAR(10),
    eventname VARCHAR(200),
    localidad VARCHAR(15),
    starttime TIMESTAMP
);

-- PREGUNTA 2: Crear un procedimiento almacenado denominado shows_semana_proxima que realice lo siguiente:
-- Vaciar la tabla shows_semanales.
-- Llenar la tabla con los shows planificados para la semana siguiente a la semana en curso. Llenar los campos con la siguiente información
-- año: Los cuatro dígitos del año (2008).
-- mes: Nombre del mes (abreviado), ejemplo: JUN.
-- semana: Número de semana, ejemplo: 26.
-- catname: Nombre descriptivo abreviado de un tipo de eventos en un grupo, ejemplo: Opera.
-- eventname: Nombre del evento, ejemplo: Hamlet.
-- localidad: Nombre del recinto, ejemplo: Cleveland Browns Stadium, concatenado con el nombre de la ciudad, ejemplo: Cleveland.
-- starttime Fecha y hora de inicio del evento, ejemplo: 2008-10-10 19:30:00

DELIMITER $$
CREATE PROCEDURE shows_semana_proxima()
BEGIN
    -- Vaciamos la tabla shows_semanales.
    TRUNCATE TABLE shows_semanales;
    
    -- Rellenamos con datos de eventos para la semana siguiente.
    INSERT INTO shows_semanales (anio, mes, semana, catname, eventname, localidad, starttime)
    SELECT 
        date.year AS anio,
        date.month AS mes,
        date.week AS semana,
        category.catname AS catname,
        event.eventname AS eventname,
        CONCAT(LEFT(venue.venuename, 10), '-', LEFT(venue.venuecity, 4)) AS localidad, -- Usamos 10 + - + 4 ya que al crear la tabla nos dice el enunciado que es un VARCHAR(15)
        event.starttime
    FROM event
    JOIN date ON event.dateid = date.dateid
    JOIN listing ON event.eventid = listing.eventid
    JOIN category ON event.catid = category.catid
    JOIN venue ON event.venueid = venue.venueid
    WHERE date.week = WEEK(CURDATE()) + 1
      AND date.year = 2008;

END$$
DELIMITER ;
-- Para comprobar que el procedimiento funciona podemos llamarlo con:
-- CALL shows_semana_proxima(); 
-- Lo usaremos en la próxima pregunta, pero si lo ejecutamos manualmente podemos comprobar que afectan a 119 eventos.

-- PREGUNTA 3: Crear un evento que ejecute cada día sábado a las 8 de la mañana el procedimiento shows_semana_proxima y que permita exportar la tabla shows_semanales generada por el procedimiento anterior a un archivo de texto.

DELIMITER $$
CREATE EVENT IF NOT EXISTS generar_shows_semana_proxima
ON SCHEDULE 
    EVERY 1 WEEK 
    STARTS (TIMESTAMP(CURRENT_DATE) + INTERVAL (6 - DAYOFWEEK(CURRENT_DATE)) DAY + INTERVAL 8 HOUR)
DO
BEGIN
    CALL shows_semana_proxima();
END$$
DELIMITER ;

-- Como exportar el procedimiento.

-- Primero vemos donde nos permite MySQL exportar el archivo con esta consulta: 
SHOW VARIABLES LIKE 'secure_file_priv'; 

-- Vemos que el Value es: /var/lib/mysql-files/ en nuestro equipo local que es donde exportar el TXT.
-- Cuando lo ejecutamos en AWS la ruta es: /secure_file_priv_dir/ pero no tenemos permisos para exportar el archivo, por que nos da error.

SELECT * FROM shows_semanales
INTO OUTFILE '/secure_file_priv_dir/shows_semanales_export.txt'
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n';

-- Si todo funciona bien deberia aparecer un mensaje como este: 119 row(s) affected
-- Y en la consola de linux si hacemos un ls -rw-r----- 1 mysql mysql 9714 Apr 26 11:25 shows_semanales_export.txt

-- PREGUNTA 4: Crear manualmente una tabla denominada ventas_entradas. Agregar los siguientes campos:
-- caldate: date. Fecha de calendario, como 2008-06-24.
-- sellerid: integer. Referencia de clave externa a la tabla USERS (el usuario que vendió los tickets).
-- sellername: varchar(35) Usar la función NombreResumido para llenar este campo
-- email: varchar(100) Dirección de correo electrónico del usuario
-- qtysold: integer. La cantidad de entradas vendidas en una fecha.
-- pricepaid: decimal(8,2) La suma del precio total por la venta de entradas.
-- profit: decimal(8,2) La suma de las ganancias 85% a pagar al vendedor para ese día.

CREATE TABLE ventas_entradas (
    caldate DATE,
    sellerid INT,
    sellername VARCHAR(35),
    email VARCHAR(100),
    qtysold INT,
    pricepaid DECIMAL(8,2),
    profit DECIMAL(8,2)
);

-- PREGUNTA 5: Crear un procedimiento almacenado denominado profit_sellers que realice lo siguiente:
-- Vaciar la tabla ventas_entradas
-- Llenar la tabla, para el día y mes que coincida con el día y el mes de la fecha actual (CURRENT_DATE()).
-- (Dado que el año es 2008 no se tomará en cuenta en el ejercicio).
-- La tabla deberá tener un registro por cada vendedor cuyas ventas de ese día sean superiores a 0.

DELIMITER $$
CREATE PROCEDURE profit_sellers()
BEGIN
    -- Vaciamos la tabla ventas_entradas
    TRUNCATE TABLE ventas_entradas;
    
    -- Insertamos datos de vendedores que han vendido entradas en la fecha actual (día y mes coincidente)
    INSERT INTO ventas_entradas (caldate, sellerid, sellername, email, qtysold, pricepaid, profit)
    SELECT 
        date.caldate,
        users.userid,
        NombreResumido(users.firstname, users.lastname) AS sellername,
        users.email,
        SUM(listing.numtickets) AS qtysold,
        SUM(listing.totalprice) AS pricepaid,
        ROUND(SUM(listing.totalprice) * 0.85, 2) AS profit
    FROM sales
    JOIN listing ON sales.listid = listing.listid
    JOIN users ON listing.sellerid = users.userid
    JOIN date ON listing.dateid = date.dateid
    WHERE DAY(date.caldate) = DAY(CURDATE())
      AND MONTH(date.caldate) = MONTH(CURDATE())
      AND date.year = 2008
    GROUP BY users.userid, date.caldate
    HAVING qtysold > 0;
END$$
DELIMITER ;
-- Como hemos explicado antes podemos ejecutar el procedimiento con:
-- CALL profit_sellers();
-- Y si funciona bien ver algo así: SELECT * FROM ventas_entradas LIMIT 0, 1000 → 16 row(s) returned

-- PREGUNTA 6: Crear un evento que ejecute cada día a las 23:59 el procedimiento profit_sellers.

DELIMITER $$
CREATE EVENT IF NOT EXISTS profit_sellers_diario
ON SCHEDULE 
    EVERY 1 DAY
    STARTS (TIMESTAMP(CURRENT_DATE) + INTERVAL 23 HOUR + INTERVAL 59 MINUTE)
DO
BEGIN
    CALL profit_sellers();
END$$
DELIMITER ;

-- PREGUNTA 7: Inventar un procedimiento almacenado que permita optimizar las operaciones del sistema. Justificarlo

DELIMITER $$
CREATE PROCEDURE borrar_ventas_antiguas()
BEGIN
    -- Eliminar registros de ventas de más de 5 años de antigüedad. Hacienda nos dice que solo se deben guardar los ultimos 5 años. Esta limpieza periódica evita acumulación innecesaria de datos antiguos y mejora el rendimiento.
    DELETE FROM sales
    WHERE listid IN (
        SELECT listing.listid
        FROM listing
        JOIN date ON listing.dateid = date.dateid
        WHERE date.year < (YEAR(CURDATE()) - 5)
    );
END$$
DELIMITER ;
