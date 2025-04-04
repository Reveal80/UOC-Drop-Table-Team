-- PLANTILLA DE ENTREGA DE LA PARTE PRÁCTICA DE LAS ACTIVIDADES
-- --------------------------------------------------------------
-- Actividad: Fase3 - P2
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
-- B1. Resolver con Combinaciones Externas.
-- Pregunta P1.B1. Crear una nueva tabla usuarios sin compras que deberá guardar aquellos usuarios que no han comprado ningún ticket con los campos userid, firstname, lastname, phone.

CREATE TABLE usuarios_sin_compras AS
SELECT users.userid, users.firstname, users.lastname, users.phone
FROM users
LEFT JOIN sales ON users.userid = sales.buyerid
WHERE sales.buyerid IS NULL;

-- Pregunta P2.B1. Crear una nueva tabla usuarios sin ventas que deberá guardar aquellos usuarios que no han vendido ningún ticket con los campos userid, firstname, lastname, phone.

CREATE TABLE usuarios_sin_ventas AS
SELECT users.userid, users.firstname, users.lastname, users.phone
FROM users
LEFT JOIN sales ON users.userid = sales.sellerid
WHERE sales.sellerid IS NULL;

-- Pregunta P3.B1. Mostrar una lista con todos los usuarios que no se encuentren en la tabla listing con los campos userid, firstname, lastname, phone.

SELECT users.userid, users.firstname, users.lastname, users.phone
FROM users
LEFT JOIN listing ON users.userid = listing.sellerid
WHERE listing.sellerid IS NULL;

-- Pregunta P4.B1. Mostrar aquellas fechas en las cuales no ha habido ningún evento. Se deberá mostrar los campos caldate y holiday.

SELECT date.caldate, date.holiday
FROM date
LEFT JOIN event ON date.dateid = event.dateid
WHERE event.dateid IS NULL;

-- NOTA como en la anterior practica creamos los registros que no tenian evento y los creamos con id 1 y fecha 2025-01-01, para mostrar estos registros creamos la siguiente consulta: 

SELECT date.caldate, date.holiday
FROM date
LEFT JOIN event ON date.dateid = event.dateid
WHERE event.dateid IS NULL OR event.catid = 1;

--
-- B2. Resolver con Subconsultas.
-- Pregunta P1.B2. Mostrar la cantidad de tickets vendidos y sin vender para las diferentes categorías de eventos.

SELECT 
  category.catname,
  -- Entradas vendidas.
  ( 
    SELECT COALESCE(SUM(listing.numtickets), 0)
    FROM listing
    WHERE listing.listid IN (
      SELECT sales.listid
      FROM sales
      WHERE sales.listid = listing.listid
    )
    AND listing.eventid IN (
      SELECT event.eventid
      FROM event
      WHERE event.catid = category.catid
    )
  ) AS tickets_vendidos,
  -- Entradas sin vender.
  (
    SELECT COALESCE(SUM(listing.numtickets), 0)
    FROM listing
    WHERE listing.listid NOT IN (
      SELECT sales.listid
      FROM sales
    )
    AND listing.eventid IN (
      SELECT event.eventid
      FROM event
      WHERE event.catid = category.catid
    )
  ) AS tickets_sin_vender
FROM category
ORDER BY category.catid;


-- Pregunta P2.B2. Crea una consulta que calcule el precio promedio pagado por venta y la compare con el precio promedio por venta por trimestre. 
-- La consulta deberá mostrar tres campos: trimestre, precio_promedio_por_trimestre, precio_promedio_total
-- NOTA: Limitamos las medias al 2008 ya que en la primera practica añadimos fechas para poder relacionar con año 2025, estas fechas nos modifican las medias.
SELECT 
  date.qtr AS trimestre,
  -- Precio promedio por trimestre
  (
    SELECT AVG(listing.totalprice)
    FROM sales
    JOIN listing ON sales.listid = listing.listid
    JOIN date AS sub_date ON listing.dateid = sub_date.dateid
    WHERE sub_date.qtr = date.qtr
      AND sub_date.year = 2008
  ) AS precio_promedio_por_trimestre,
    -- Precio promedio total
  (
    SELECT AVG(listing.totalprice)
    FROM sales
    JOIN listing ON sales.listid = listing.listid
    JOIN date ON listing.dateid = date.dateid
    WHERE date.year = 2008
  ) AS precio_promedio_total
FROM date
WHERE date.year = 2008
GROUP BY date.qtr
ORDER BY date.qtr;


-- Pregunta P3.B2. Muestra el total de tickets de entradas compradas de Shows y Conciertos.

SELECT 
  -- Total Shows
  (
    SELECT SUM(listing.numtickets)
    FROM sales
    JOIN listing ON sales.listid = listing.listid
    WHERE listing.eventid IN (
      SELECT event.eventid
      FROM event
      WHERE event.catid IN (
        SELECT category.catid
        FROM category
        WHERE category.catgroup = 'Shows'
      )
    )
  ) AS tickets_shows,
  -- Total Concerts
  (
    SELECT SUM(listing.numtickets)
    FROM sales
    JOIN listing ON sales.listid = listing.listid
    WHERE listing.eventid IN (
      SELECT event.eventid
      FROM event
      WHERE event.catid IN (
        SELECT category.catid
        FROM category
        WHERE category.catgroup = 'Concerts'
      )
    )
  ) AS tickets_concerts,
  -- Total combinando ambos
  (
    SELECT SUM(listing.numtickets)
    FROM sales
    JOIN listing ON sales.listid = listing.listid
    WHERE listing.eventid IN (
      SELECT event.eventid
      FROM event
      WHERE event.catid IN (
        SELECT category.catid
        FROM category
        WHERE category.catgroup IN ('Shows', 'Concerts')
      )
    )
  ) AS tickets_totales;

-- Pregunta P4.B2. Muestra el id, fecha, nombre del evento y localización del evento que más entradas ha vendido.

SELECT event.eventid, date.caldate, event.eventname, venue.venuename,
  (
    SELECT SUM(listing.numtickets)
    FROM sales
    JOIN listing ON sales.listid = listing.listid
    WHERE listing.eventid = event.eventid
  ) AS total_entradas_vendidas
FROM event
JOIN date ON event.dateid = date.dateid
JOIN venue ON event.venueid = venue.venueid
WHERE event.eventid = (
  SELECT listing.eventid
  FROM sales
  JOIN listing ON sales.listid = listing.listid
  GROUP BY listing.eventid
  ORDER BY SUM(listing.numtickets) DESC
  LIMIT 1
);

--
-- B3. Resolver con Vistas.
-- Pregunta P1.B3. Crea una vista con los eventos del mes de la tabla que coincida con el mes actual. Grabar la vista con el nombre Eventos del mes.

CREATE VIEW `Eventos_del_mes` AS
SELECT 
  event.eventid,
  event.eventname,
  date.caldate,
  date.month
FROM event
JOIN date ON event.dateid = date.dateid
WHERE date.month = MONTH(CURDATE());

-- Pregunta P2.B3. Crear una vista que muestre las ventas por trimestre y grupo de eventos. Guardar con el nombre Estadisticas.

CREATE VIEW Estadisticas AS
SELECT 
  date.qtr AS trimestre,
  category.catgroup AS grupo_evento,
  SUM(listing.numtickets) AS Total_entradas,
  SUM(listing.totalprice) AS total_ventas
FROM sales
JOIN listing ON sales.listid = listing.listid
JOIN date ON listing.dateid = date.dateid
JOIN event ON listing.eventid = event.eventid
JOIN category ON event.catid = category.catid
GROUP BY date.qtr, category.catgroup
ORDER BY date.qtr, category.catgroup;

--
-- B4. Resolver con Consultas de UNION.
-- Pregunta P1.B4. Crear una consulta de UNION producto de las tablas usuarios sin compras y usuarios sin ventas.
SELECT * FROM usuarios_sin_compras
UNION
SELECT * FROM usuarios_sin_ventas;

--
-- Pregunta P2.B4. Crear una consulta de UNION que en forma de tabla las columnas mes, año, 'ventas' as concepto, totalventas y a continuación mes, año, 'comisiones' as concepto, totalcomisiones. 
-- Guardarla en forma de vista con el nombre operaciones
-- NOTA usamos la comision 0.15 que nos indicaron en la primera practica.

CREATE VIEW Operaciones AS
SELECT 
  date.month AS mes,
  date.year AS año,
  'ventas' AS concepto,
  SUM(listing.totalprice) AS total
FROM sales
JOIN listing ON sales.listid = listing.listid
JOIN date ON listing.dateid = date.dateid
GROUP BY date.month, date.year
UNION
SELECT 
  date.month AS mes,
  date.year AS año,
  'comisiones' AS concepto,
  SUM(listing.totalprice) * 0.15 AS total
FROM sales
JOIN listing ON sales.listid = listing.listid
JOIN date ON listing.dateid = date.dateid
GROUP BY date.month, date.year;