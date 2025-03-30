-- PLANTILLA DE ENTREGA DE LA PARTE PRÁCTICA DE LAS ACTIVIDADES
-- --------------------------------------------------------------
-- Actividad: Fase3 - P1
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
-- Pregunta P1.B.1. Importar las tablas y el script de control que se encuentra en los archivos .sql con el mismo nombre.
-- Hecho ok.

--
-- Pregunta P1.B.2. Hacer un análisis del contenido de las tablas. Para ello, cada una de las columnas de las mismas, se encuentran comentadas. También se puede hacer uso de las instrucciones que se encuentran en el script de control.
-- Podemos dar un vistazo rápido usando la petición DESCRIBE.
DESCRIBE event;
DESCRIBE venue;
DESCRIBE category;
DESCRIBE listing;
DESCRIBE sales;
DESCRIBE category;
DESCRIBE date;
--
-- Pregunta P1.B.3. Crear dos campos adicionales en la tabla users: VIP (enum: sí, no; default: no) y birthdate (date). Se utilizarán posteriormente en próximos productos.
ALTER TABLE users
ADD COLUMN VIP ENUM('sí', 'no') DEFAULT 'no', -- Campo VIP: por defecto 'no'
ADD COLUMN birthdate DATE; -- Fecha de nacimiento

--
-- Pregunta P1.B.4. Relacionar las tablas de la Base de Datos tomando en cuenta aquellas columnas que tienen en su descripción el texto Referencia de clave externa a la tabla xxx.. 
-- Para poder relacionar las claves foráneas, queríamos asegurarnos de que todas las tablas tengan los registros correspondientes en los campos que participan en las relaciones, para ello haremos lo siguiente:
-- Al crear las claves foráneas, agregar las cláusulas ON UPDATE y ON DELETE pertinentes, justificando con un comentario cada decisión, con comentarios en la plantilla.
-- Modificamos en la tabla event, catid como SMALLINT NULL antes de hacer las relaciones.
ALTER TABLE event MODIFY catid SMALLINT NULL; -- Necesario para usar ON DELETE SET NULL en la relación con category.
-- Modificamos las FK de sales para que permita valores nulos.
ALTER TABLE sales MODIFY listid INT DEFAULT NULL;
ALTER TABLE sales MODIFY eventid INT DEFAULT NULL;
ALTER TABLE sales MODIFY sellerid INT DEFAULT NULL;
ALTER TABLE sales MODIFY buyerid INT DEFAULT NULL;
-- Insertamos un nuevo registro en la tabla `date`, representando el 1 de enero de 2025. Necesario para poder asignarlo en relaciones.
INSERT INTO date (dateid, caldate, day, month, qtr, year, holiday, week)
VALUES (1, '2025-01-01', 'MO', 'JAN', '1', 2025, 0, WEEK('2025-01-01'));
-- En la tabla event creamos los eventos borrados para poder hacer relaciones.
INSERT INTO event (eventid, venueid, catid, dateid, eventname, starttime) 
SELECT DISTINCT sales.eventid, 1 AS venueid, 1 AS catid, 1 AS dateid, 'Evento Borrado' AS eventname, NOW() AS starttime 
FROM sales
LEFT JOIN event ON sales.eventid = event.eventid
WHERE event.eventid IS NULL;
-- Creamos registro Evento desconocido en event para poder hacer relaciones.
INSERT INTO event (eventid, venueid, catid, dateid, eventname, starttime)
SELECT DISTINCT listing.eventid, 1, 1, 1, 'Evento Desconocido', NOW()
FROM listing
LEFT JOIN event ON listing.eventid = event.eventid
WHERE event.eventid IS NULL;
-- Creamos registro base en listing para poder hacer relaciones.
INSERT INTO listing (listid, sellerid, eventid, dateid, numtickets, priceperticket, listtime)
SELECT DISTINCT sales.listid, 1, 1, 1, 1, 1, NOW()
FROM sales
LEFT JOIN listing ON sales.listid = listing.listid
WHERE listing.listid IS NULL;
-- Relacionamos event con otras tablas.
ALTER TABLE event 
    ADD CONSTRAINT fk_event_venue FOREIGN KEY (venueid) REFERENCES venue(venueid) 
        ON UPDATE CASCADE ON DELETE RESTRICT, -- No permitimos eliminar un venue si tiene eventos asociados.
	ADD CONSTRAINT fk_event_category FOREIGN KEY (catid) REFERENCES category(catid) 
		ON UPDATE CASCADE ON DELETE SET NULL, -- Si se elimina una categoría, el evento queda sin categoría.
    ADD CONSTRAINT fk_event_date FOREIGN KEY (dateid) REFERENCES date(dateid) 
        ON UPDATE CASCADE ON DELETE RESTRICT; -- No permitimos eliminar una fecha si hay eventos en esa fecha.
-- Relacionamos listing con otras tablas.
ALTER TABLE listing 
    ADD CONSTRAINT fk_listing_event FOREIGN KEY (eventid) REFERENCES event(eventid) 
        ON UPDATE CASCADE ON DELETE CASCADE, -- Si un evento se elimina, también se eliminan sus listados.
    ADD CONSTRAINT fk_listing_date FOREIGN KEY (dateid) REFERENCES date(dateid) 
        ON UPDATE CASCADE ON DELETE RESTRICT, -- No permitimos eliminar una fecha si hay listados asociados.
    ADD CONSTRAINT fk_listing_seller FOREIGN KEY (sellerid) REFERENCES users(userid) 
        ON UPDATE CASCADE ON DELETE RESTRICT; -- No permitimos eliminar un usuario si tiene listados activos.
-- Relacionamos sales con otras tablas.
ALTER TABLE sales 
	ADD CONSTRAINT fk_sales_listing FOREIGN KEY (listid) REFERENCES listing(listid) 
		ON UPDATE CASCADE ON DELETE SET NULL, -- Si el listado desaparece, la venta queda sin referencia pero sigue existiendo.
	ADD CONSTRAINT fk_sales_event FOREIGN KEY (eventid) REFERENCES event(eventid) 
		ON UPDATE CASCADE ON DELETE SET NULL, -- Si el evento desaparece, la venta sigue existiendo sin evento asignado.
    ADD CONSTRAINT fk_sales_date FOREIGN KEY (dateid) REFERENCES date(dateid) 
        ON UPDATE CASCADE ON DELETE RESTRICT, -- No permitimos eliminar una fecha si hay ventas registradas.
	ADD CONSTRAINT fk_sales_seller FOREIGN KEY (sellerid) REFERENCES users(userid) 
		ON UPDATE CASCADE ON DELETE SET NULL, -- Si el vendedor se borra, la venta sigue existiendo sin vendedor asignado.
	ADD CONSTRAINT fk_sales_buyer FOREIGN KEY (buyerid) REFERENCES users(userid) 
		ON UPDATE CASCADE ON DELETE SET NULL; -- Si el comprador se borra, la venta sigue existiendo sin comprador asignado.

--
-- Pregunta P1.B.5. Revisar los comentarios en las tablas y generar dos restricciones de tipo check para controlar la integridad de los datos.
-- Check1. Comprobar que solo se pueden vender 8 entradas.							  
ALTER TABLE sales 
ADD CONSTRAINT chk_qtysold_limit 
CHECK (qtysold >= 1 AND qtysold <= 8);
-- Check2. En la tabla listing, el número de tickets (numtickets) sea mayor a 0.
ALTER TABLE listing
ADD CONSTRAINT chk_listing_numtickets
CHECK (numtickets > 0);

--
-- Pregunta P1.B.6. Revisar los comentarios en las tablas y cambiar los campos que así lo requieran, por campos autocalculados.
-- Borramos totalprice de la tabla listing y la creamos como autocalculado.
ALTER TABLE listing
DROP COLUMN totalprice,
ADD COLUMN totalprice DECIMAL(10,2) GENERATED ALWAYS AS (numtickets * priceperticket) STORED
COMMENT "El precio total para un listado en particular (NUMTICKETS*PRICEPERTICKET)";
-- Borramos commission de la tabla sales y la creamos para que sea autocalculada (15% de PRICEPAID)
ALTER TABLE sales
DROP COLUMN commission, 
ADD COLUMN commission DECIMAL(8,2) GENERATED ALWAYS AS (pricepaid * 0.15) STORED
COMMENT "15 % de comisión que el negocio obtiene de la venta (PRICEPAID * 0.15)";	
																							   
--
-- Pregunta P1.B.7. Agregar dos campos adicionales a la Base de Datos que enriquezca la información de la misma. Justificar.
-- Campo1. Creamos columna status permite controlar la disponibilidad y gestión de cada evento.
ALTER TABLE event 
ADD COLUMN status ENUM('Disponible', 'Cancelado', 'Finalizado') DEFAULT 'Disponible';
-- Campo2. Creamos columna user_type para identificar que tipo de usuario es, comprador, vendedor o admin. 
ALTER TABLE users 
ADD COLUMN user_type ENUM('Comprador', 'Vendedor', 'Admin') DEFAULT 'Comprador';


--
-- Pregunta P1.B.8. Crear un disparador que al actualizar el campo username de la tabla users revise si su contenido contiene mayúsculas, minúsculas, digitos y alguno de los siguientes símbolos: -_#@. De no ser así, no permitir la actualización.
DELIMITER $$
CREATE TRIGGER before_update_users_username
BEFORE UPDATE ON users
FOR EACH ROW
BEGIN
    -- Verificar si el nuevo username cumple con los requisitos  
  IF NOT (
       NEW.username REGEXP '[A-Z]' AND
       NEW.username REGEXP '[a-z]' AND
       NEW.username REGEXP '[0-9]' AND
       NEW.username REGEXP '[-_#@]'
     ) THEN
        -- Generar un error y cancelar la actualización
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El nombre de usuario debe contener al menos, una mayúscula, una minúscula, un dígito, y uno de los siguientes símbolos: -_@#';
    END IF;
END$$
DELIMITER ;

--
-- Pregunta P1.B.9. Diseñar un disparador que prevenga que el campo email de la tabla users tenga un formato correcto al actualizar o insertar un nuevo email.
-- Validamos que el email contenga un '@' y un '.' al añadirlo la primera vez.
DELIMITER $$
CREATE TRIGGER validate_email_before_insert
BEFORE INSERT ON users
FOR EACH ROW
BEGIN
    IF NOT (NEW.email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'El email tiene un formato incorrecto';
  END IF;
END$$
DELIMITER ;
-- Validación similar en el caso de actualización.
DELIMITER $$
CREATE TRIGGER trg_validate_email_before_update
BEFORE UPDATE ON users
FOR EACH ROW
BEGIN
    IF NOT (NEW.email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'El email tiene un formato incorrecto';
  END IF;
END$$
DELIMITER ;

--
-- Pregunta P1.B.10. Inventar una restricción que sirva de utilidad para mantener la integridad de la Base de Datos.
-- Creamos una columna llamada endtime donde indicamos la fecha fin del evento y añadimos una restricción.
ALTER TABLE event
ADD COLUMN endtime DATETIME,
ADD CONSTRAINT chk_event_dates
CHECK (starttime <= endtime);



