
DROP TABLE IF EXISTS `category`;

CREATE TABLE `category` (
  `catid` smallint NOT NULL COMMENT 'Clave primaria, un valor de ID único para cada fila. Cada fila representa un tipo de evento específico para el cual se compran y venden tickets.',
  `catgroup` varchar(10) DEFAULT NULL COMMENT 'Nombre descriptivo de un grupo de eventos, como Shows y Sports.',
  `catname` varchar(10) DEFAULT NULL COMMENT 'Nombre descriptivo abreviado de un tipo de eventos en un grupo, como Opera y Musicals.',
  `catdesc` varchar(50) DEFAULT NULL COMMENT 'Nombre descriptivo más largo del tipo de evento, como Musical theatre.',
  PRIMARY KEY (`catid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `category`
--

LOCK TABLES `category` WRITE;
/*!40000 ALTER TABLE `category` DISABLE KEYS */;

INSERT INTO `category` VALUES 
(1,'Sports','MLB','Major League Baseball'),
(2,'Sports','NHL','National Hockey League'),
(3,'Sports','NFL','National Football League'),
(4,'Sports','NBA','National Basketball Association'),
(5,'Sports','MLS','Major League Soccer'),
(6,'Shows','Musicals','Musical theatre'),
(7,'Shows','Plays','All non-musical theatre'),
(8,'Shows','Opera','All opera and light opera'),
(9,'Concerts','Pop','All rock and pop music concerts'),
(10,'Concerts','Jazz','All jazz singers and bands'),
(11,'Concerts','Classical','All symphony, concerto, and choir concerts');

UNLOCK TABLES;

