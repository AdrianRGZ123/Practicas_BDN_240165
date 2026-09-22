CREATE DATABASE  IF NOT EXISTS `db_test` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `db_test`;
-- MySQL dump 10.13  Distrib 8.0.36, for Win64 (x86_64)
--
-- Host: 127.0.0.1    Database: db_test
-- ------------------------------------------------------
-- Server version	8.0.36

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `tb_logs`
--

DROP TABLE IF EXISTS `tb_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_logs` (
  `ID` int NOT NULL AUTO_INCREMENT,
  `table_name` varchar(100) NOT NULL,
  `operation` enum('Create','Read','Update','Delete') NOT NULL,
  `db_user` varchar(80) NOT NULL,
  `description` text NOT NULL,
  `operation_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `operation_status` bit(1) DEFAULT b'1',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=23 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tb_logs`
--

LOCK TABLES `tb_logs` WRITE;
/*!40000 ALTER TABLE `tb_logs` DISABLE KEYS */;
INSERT INTO `tb_logs` VALUES (1,'tb_users','Create','root@localhost','Usuario creado. ID=1, email=240165@utxicotepec.edu.mx, nickname=ING-ADRIAN','2026-09-08 11:13:15',_binary ''),(2,'tb_users','Create','root@localhost','Usuario creado. ID=2, email=240221@utxicotepec.edu.mx, nickname=ING-CARLOS','2026-09-08 11:15:08',_binary ''),(3,'tb_users','Create','root@localhost','Usuario creado. ID=3, email=240628@utxicotepec.edu.mx, nickname=ING-CHEMA','2026-09-08 11:15:43',_binary ''),(4,'tb_users','Create','jose.maria@DESKTOP-TTGCQ98','Usuario creado. ID=5, email=240558@utxicotepec.edu.mx, nickname=ING-Johny','2026-09-08 11:39:10',_binary ''),(5,'tb_users','Create','jose.maria@DESKTOP-TTGCQ98','Usuario creado. ID=6, email=240890@utxicotepec.edu.mx, nickname=ING-OBED','2026-09-08 11:39:54',_binary ''),(6,'tb_users','Create','jose.maria@DESKTOP-TTGCQ98','Usuario creado. ID=7, email=240765@utxicotepec.edu.mx, nickname=ING-saul','2026-09-08 11:41:16',_binary ''),(7,'tb_users','Create','carlos.rene@PC-13','Usuario creado. ID=8, email=adrian.feo@utxicotepec.edu.mx, nickname=Adrian','2026-09-09 18:05:51',_binary ''),(8,'tb_users','Create','carlos.rene@PC-13','Usuario creado. ID=9, email=Jonny.Neri@utxicotepec.edu.mx, nickname=Jonny','2026-09-09 18:07:34',_binary ''),(9,'tb_users','Create','carlos.rene@PC-13','Usuario creado. ID=10, email=luis.mua@utxicotepec.edu.mx, nickname=Luismua','2026-09-09 18:07:49',_binary ''),(10,'tb_users','Create','carlos.rene@PC-13','Usuario creado. ID=1, email=240165@utxicotepec.edu.mx, nickname=Saul_Barrios','2026-09-09 18:10:29',_binary ''),(11,'tb_users','Create','carlos.rene@PC-13','Usuario creado. ID=1, email=240165@utxicotepec.edu.mx, nickname=Saul_Barrios','2026-09-09 18:10:41',_binary ''),(12,'tb_users','Delete','carlos.rene@PC-13','Usuario eliminado. ID=2, email=240221@utxicotepec.edu.mx, nickname=ING-CARLOS','2026-09-09 18:27:19',_binary ''),(13,'tb_users','Update','carlos.rene@PC-13','Usuario actualizado. ID=3 | Email: 240628@utxicotepec.edu.mx -> 240628@utxicotepec.edu.mx | Nickname: ING-CHEMA -> Saul_Barrios','2026-09-09 18:27:37',_binary ''),(14,'tb_users','Create','carlos.rene@DESKTOP-ACMHB9I','Usuario creado. ID=11, email=patricia.medina@gmail.com, nickname=pato24','2026-09-15 11:16:41',_binary ''),(15,'tb_users','Create','carlos.rene@DESKTOP-ACMHB9I','Usuario creado. ID=13, email=juanito@gmail.com, nickname=pato2','2026-09-15 11:21:41',_binary ''),(16,'tb_products','Create','root@localhost','Producto creado. ID=1, SKU=AMZ001, Nombre=Audifonos Inalambricos, Precio=599.00, Stock=20','2026-09-22 10:34:49',_binary ''),(17,'tb_products','Create','root@localhost','Producto creado. ID=2, SKU=AMZ002, Nombre=Mouse Inalambrico, Precio=299.00, Stock=15','2026-09-22 10:34:49',_binary ''),(18,'tb_products','Create','erick.uriel@PC-15','Producto creado. ID=3, SKU=AMZ003, Nombre=Teclado Inalambrico, Precio=449.00, Stock=10','2026-09-22 11:00:15',_binary ''),(19,'tb_products','Create','erick.uriel@PC-15','Producto creado. ID=4, SKU=AMZ004, Nombre=Bocina Bluetooth, Precio=799.00, Stock=8','2026-09-22 11:00:15',_binary ''),(20,'tb_products','Create','erick.uriel@PC-15','Producto creado. ID=5, SKU=AMZ005, Nombre=Monitor LED 24 Pulgadas, Precio=2499.00, Stock=7','2026-09-22 11:01:29',_binary ''),(21,'tb_products','Create','erick.uriel@PC-15','Producto creado. ID=6, SKU=AMZ006, Nombre=Camara Web HD, Precio=699.00, Stock=12','2026-09-22 11:01:29',_binary ''),(22,'tb_products','Create','erick.uriel@PC-15','Producto creado. ID=7, SKU=AMZ007, Nombre=Memoria USB 64GB, Precio=199.00, Stock=25','2026-09-22 11:01:29',_binary '');
/*!40000 ALTER TABLE `tb_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tb_products`
--

DROP TABLE IF EXISTS `tb_products`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_products` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `sku` varchar(50) NOT NULL,
  `name` varchar(250) NOT NULL,
  `description` text,
  `current_price` decimal(10,2) NOT NULL DEFAULT '0.00',
  `current_stock` int unsigned NOT NULL DEFAULT '0',
  `status` bit(1) DEFAULT b'1',
  `creation_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_update` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `sku` (`sku`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tb_products`
--

LOCK TABLES `tb_products` WRITE;
/*!40000 ALTER TABLE `tb_products` DISABLE KEYS */;
INSERT INTO `tb_products` VALUES (1,'AMZ001','Audifonos Inalambricos','Audifonos Bluetooth inalambricos con estuche de carga.',599.00,20,_binary '','2026-09-22 10:34:49','2026-09-22 10:34:49'),(2,'AMZ002','Mouse Inalambrico','Mouse inalambrico para computadora con conexion USB.',299.00,15,_binary '','2026-09-22 10:34:49','2026-09-22 10:34:49'),(3,'AMZ003','Teclado Inalambrico','Teclado inalambrico para computadora con conexion USB.',449.00,10,_binary '','2026-09-22 11:00:15','2026-09-22 11:00:15'),(4,'AMZ004','Bocina Bluetooth','Bocina portatil Bluetooth con bateria recargable.',799.00,8,_binary '','2026-09-22 11:00:15','2026-09-22 11:00:15'),(5,'AMZ005','Monitor LED 24 Pulgadas','Monitor LED de 24 pulgadas para computadora con entrada HDMI.',2499.00,7,_binary '','2026-09-22 11:01:29','2026-09-22 11:01:29'),(6,'AMZ006','Camara Web HD','Camara web HD para videollamadas y clases en linea.',699.00,12,_binary '','2026-09-22 11:01:29','2026-09-22 11:01:29'),(7,'AMZ007','Memoria USB 64GB','Memoria USB de 64GB para almacenar y transferir archivos.',199.00,25,_binary '','2026-09-22 11:01:29','2026-09-22 11:01:29');
/*!40000 ALTER TABLE `tb_products` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_products_after_insert` AFTER INSERT ON `tb_products` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tb_products',
        'Create',
        USER(),
        CONCAT('Producto creado. ID=', NEW.ID, ', SKU=', NEW.SKU, ', Nombre=', NEW.name, ', Precio=', NEW.current_price, ', Stock=', NEW.current_stock),
        NOW(),
        1
    );
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_products_after_update` AFTER UPDATE ON `tb_products` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tb_products',
        'Update',
        USER(),
        CONCAT('Producto actualizado. ID=', NEW.ID, ', SKU=', NEW.SKU, ' | Stock anterior: ', OLD.current_stock, ' -> Nuevo stock: ', NEW.current_stock, ' | Precio anterior: ', OLD.current_price, ' -> Nuevo precio: ', NEW.current_price),
        NOW(),
        1
    );
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_products_before_delete` BEFORE DELETE ON `tb_products` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tb_products',
        'Delete',
        USER(),
        CONCAT('Producto eliminado. ID=', OLD.ID, ', SKU=', OLD.SKU, ', Nombre=', OLD.name),
        NOW(),
        1
    );
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `tb_users`
--

DROP TABLE IF EXISTS `tb_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tb_users` (
  `ID` int NOT NULL AUTO_INCREMENT,
  `email` varchar(80) NOT NULL,
  `nickname` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `creation_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_update` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `last_login` datetime DEFAULT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `email` (`email`),
  UNIQUE KEY `nickname` (`nickname`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tb_users`
--

LOCK TABLES `tb_users` WRITE;
/*!40000 ALTER TABLE `tb_users` DISABLE KEYS */;
INSERT INTO `tb_users` VALUES (3,'240628@utxicotepec.edu.mx','Saul_Barrios','f180d9521dd923d5835a93f48639d309','2026-09-08 11:15:43','2026-09-09 18:27:37',NULL),(5,'240558@utxicotepec.edu.mx','ING-Johny','827ccb0eea8a706c4c34a16891f84e7b','2026-09-08 11:39:10','2026-09-09 17:44:35',NULL),(6,'240890@utxicotepec.edu.mx','ING-OBED','827ccb0eea8a706c4c34a16891f84e7b','2026-09-08 11:39:54','2026-09-09 17:44:35',NULL),(7,'240765@utxicotepec.edu.mx','ING-saul','827ccb0eea8a706c4c34a16891f84e7b','2026-09-08 11:41:16','2026-09-09 17:44:35',NULL),(8,'adrian.feo@utxicotepec.edu.mx','Adrian','52dcb810931e20f7aa2f49b3510d3805','2026-09-09 18:05:51','2026-09-09 18:05:51',NULL),(9,'Jonny.Neri@utxicotepec.edu.mx','Jonny','52dcb810931e20f7aa2f49b3510d3805','2026-09-09 18:07:34','2026-09-09 18:07:34',NULL),(10,'luis.mua@utxicotepec.edu.mx','Luismua','52dcb810931e20f7aa2f49b3510d3805','2026-09-09 18:07:49','2026-09-09 18:07:49',NULL),(11,'patricia.medina@gmail.com','pato24','5ec55ba95899a0707f8c6a51bf5a40b8','2026-09-15 11:16:41',NULL,NULL),(13,'juanito@gmail.com','pato2','5ec55ba95899a0707f8c6a51bf5a40b8','2026-09-15 11:21:41',NULL,NULL);
/*!40000 ALTER TABLE `tb_users` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_users_after_insert` AFTER INSERT ON `tb_users` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (
        table_name,
        operation,
        db_user,
        description,
        operation_date,
        operation_status
    )
    VALUES (
        'tb_users',
        'Create',
        USER(),
        CONCAT(
            'Usuario creado. ID=', NEW.ID,
            ', email=', NEW.email,
            ', nickname=', NEW.nickname
        ),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_users_after_update` AFTER UPDATE ON `tb_users` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (
        table_name,
        operation,
        db_user,
        description,
        operation_date,
        operation_status
    )
    VALUES (
        'tb_users',
        'Update', 
        USER(),
        CONCAT(
            'Usuario actualizado. ID=', OLD.ID, 
            ' | Email: ', OLD.email, ' -> ', NEW.email, 
            ' | Nickname: ', OLD.nickname, ' -> ', NEW.nickname
        ),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_users_after_delete` AFTER DELETE ON `tb_users` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (
        table_name,
        operation,
        db_user,
        description,
        operation_date,
        operation_status
    )
    VALUES (
        'tb_users',
        'Delete', 
        USER(),
        CONCAT(
            'Usuario eliminado. ID=', OLD.ID, 
            ', email=', OLD.email,
            ', nickname=', OLD.nickname
        ),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-09-22 11:38:58
