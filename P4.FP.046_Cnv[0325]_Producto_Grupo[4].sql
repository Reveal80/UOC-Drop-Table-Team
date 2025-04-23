-- PLANTILLA DE ENTREGA DE LA PARTE PRÁCTICA DE LAS ACTIVIDADES
-- --------------------------------------------------------------
-- Actividad: Fase3 - P4
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

-- PREGUNTA 1: ¿Cómo se podrían optimizar cada una de las consultas de los productos 2 y 3 o qué consultas toman en cuenta los puntos de este producto y por qué?

-- Usuarios sin compras
SELECT users.userid, users.firstname, users.lastname, users.phone
FROM users
LEFT JOIN sales ON users.userid = sales.buyerid
WHERE sales.buyerid IS NULL;

-- Usuarios sin ventas
SELECT users.userid, users.firstname, users.lastname, users.phone
FROM users
LEFT JOIN sales ON users.userid = sales.sellerid
WHERE sales.sellerid IS NULL;

-- Usuarios sin listings
SELECT users.userid, users.firstname, users.lastname, users.phone
FROM users
LEFT JOIN listing ON users.userid = listing.sellerid
WHERE listing.sellerid IS NULL;

-- Eventos del mes actual que coinciden con la semana actual
SET @mes_actual := UPPER(LEFT(MONTHNAME(CURDATE()), 3));
SET @semana_actual := WEEK(CURDATE());

SELECT event.eventid, event.eventname, date.caldate, date.week,
  CASE 
    WHEN date.week = @semana_actual THEN 'si'
    ELSE 'no'
  END AS coincideSemana
FROM event
JOIN date ON event.dateid = date.dateid
WHERE date.month = @mes_actual AND date.year = 2008
ORDER BY date.week;

-- PREGUNTA 2: ¿Luego del análisis de la pregunta 1, consideráis necesario crear algunos índices? ¿Cuáles y por qué?

-- Índices en sales.
-- Se utiliza para consultas como LEFT JOIN sales ON users.userid = sales.buyerid, seguidas de WHERE sales.buyerid IS NULL. Si no hay un índice en buyerid, 
-- MySQL realiza un escaneo completo sobre sales en cada fila de users. Este índice permite buscar rápidamente las coincidencias por comprador, mejorando el rendimiento del JOIN y del filtro.
CREATE INDEX idx_sales_buyerid ON sales(buyerid);

-- Similar al anterior, este índice optimiza la consulta donde se buscan usuarios que no han vendido (users.userid = sales.sellerid). 
-- Facilita búsquedas por vendedores en las combinaciones LEFT JOIN, reduciendo los tiempos de ejecución.
CREATE INDEX idx_sales_sellerid ON sales(sellerid);

-- Índice en users.
-- userid es clave primaria, por lo tanto ya suele estar indexado automáticamente, pero se declara explícitamente para indicar que su uso es clave en los JOINs con sales y listing. 
-- Mejora el rendimiento al combinar tablas desde la perspectiva de users.
CREATE INDEX idx_users_userid ON users(userid);

-- Índice en listing
-- Utilizado para identificar qué usuarios no están en la tabla listing (nunca han publicado un evento). El índice acelera la búsqueda de registros relacionados con cada userid.
CREATE INDEX idx_listing_sellerid ON listing(sellerid);

-- Índice en event
-- Este indice ya existe en la BBDD, pero si no existiera deberiamos crearlo así:
-- Usado en JOIN date ON event.dateid = date.dateid. Si no hay índice, el motor tendría que revisar todos los registros de event para buscar coincidencias con date. El índice agiliza esa búsqueda.
-- CREATE INDEX idx_event_dateid ON event(dateid);

-- Índices en date
-- Complementa el anterior JOIN, permitiendo encontrar más rápidamente las fechas relacionadas con los eventos.
CREATE INDEX idx_date_dateid ON date(dateid);

-- Esta combinación de columnas se usa en la cláusula WHERE d.month = @mes AND d.year = 2008. 
-- Tener un índice conjunto permite que la consulta filtre directamente usando ese índice, en lugar de recorrer la tabla completa de fechas.
CREATE INDEX idx_date_month_year ON date(month, year);

-- Pregunta P3. ¿Qué roles se podrían crear para la Base de Datos? (Justificar)
-- Ventaja de usar roles: Se asignan permisos a grupos, no uno a uno. Si un nuevo usuario entra al equipo, solo se le asigna un rol, sin tener que configurar permisos manualmente. Mejora la seguridad y el mantenimiento de la base de datos.

-- Rol 1. rol_lectura_usuarios. Para usuarios que solo necesitan consultar información de los usuarios, sin modificar nada.
-- Permisos: SELECT sobre la tabla users.
CREATE ROLE rol_lectura_usuarios;
GRANT SELECT ON users TO rol_lectura_usuarios;
	
-- Rol 2. rol_gestor_ventas. Para personal encargado de gestionar las ventas de entradas. Necesitan consultar y modificar ventas.
-- Permisos: SELECT, INSERT, UPDATE sobre sales. Y SELECT sobre users y listing.
CREATE ROLE rol_gestor_ventas;
GRANT SELECT ON TICKIT.users TO rol_gestor_ventas;
GRANT SELECT ON TICKIT.listing TO rol_gestor_ventas;

-- Rol 3. rol_analista_eventos. Este rol es ideal para quien necesite sacar estadísticas o informes de eventos, como un analista de datos.
-- Permisos: SELECT sobre event, date, sales, users.
CREATE ROLE rol_analista_eventos;
GRANT SELECT ON TICKIT.event TO rol_analista_eventos;
GRANT SELECT ON TICKIT.date TO rol_analista_eventos;
GRANT SELECT ON TICKIT.sales TO rol_analista_eventos;
GRANT SELECT ON TICKIT.users TO rol_analista_eventos;


-- Rol 4. rol_admin_db
-- Permisos: Todos los privilegios necesarios para administración: ALL PRIVILEGES.
CREATE ROLE rol_admin_db;
GRANT ALL PRIVILEGES ON TICKIT.* TO rol_admin_db;