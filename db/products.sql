-- --------------------------------------------------------
-- Host:                         127.0.0.1
-- Server version:               10.4.34-MariaDB - mariadb.org binary distribution
-- Server OS:                    Win64
-- HeidiSQL Version:             12.6.0.6765
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

-- Dumping data for table cashcard.product: ~8 rows (approximately)
INSERT INTO `product` (`id`, `name`, `price_huf`, `favourite`, `del_sp`) VALUES
	(1, 'Menü 1', 3490, 1, '0000-00-00 00:00:00'),
	(2, 'Menü 2', 2990, 1, '0000-00-00 00:00:00'),
	(3, 'Menü 3', 2490, 1, '0000-00-00 00:00:00'),
	(4, 'Kakaóscsiga', 990, 0, '0000-00-00 00:00:00'),
	(5, 'Lekváros bukta', 890, 0, '0000-00-00 00:00:00'),
	(6, 'Pizzás táska', 890, 0, '0000-00-00 00:00:00'),
	(7, 'Sonkás szendvics', 990, 0, '0000-00-00 00:00:00'),
	(8, 'Rántotthúsos szendvics', 1090, 0, '0000-00-00 00:00:00');
	
INSERT INTO `product` (`name`, `price_huf`, `favourite`, `del_sp`) VALUES
	('Főétel 1', 2490, 1, '0000-00-00 00:00:00'),
	('Főétel 2', 1990, 1, '0000-00-00 00:00:00'),
	('Főétel 3', 1490, 1, '0000-00-00 00:00:00'),
	('Leves 1', 2490, 1, '0000-00-00 00:00:00'),
	('Leves 2', 1990, 1, '0000-00-00 00:00:00'),
	('Leves 3', 1490, 1, '0000-00-00 00:00:00'),
	('1 Kakaóscsiga', 990, 0, '0000-00-00 00:00:00'),
	('1 Lekváros bukta', 890, 0, '0000-00-00 00:00:00'),
	('1 Pizzás táska', 890, 0, '0000-00-00 00:00:00'),
	('1 Sonkás szendvics', 990, 0, '0000-00-00 00:00:00'),
	('1 Rántotthúsos szendvics', 1090, 0, '0000-00-00 00:00:00'),
	('2 Kakaóscsiga', 990, 0, '0000-00-00 00:00:00'),
	('2 Lekváros bukta', 890, 0, '0000-00-00 00:00:00'),
	('2 Pizzás táska', 890, 0, '0000-00-00 00:00:00'),
	('2 Sonkás szendvics', 990, 0, '0000-00-00 00:00:00'),
	('2 Rántotthúsos szendvics', 1090, 0, '0000-00-00 00:00:00'),
	('3 Kakaóscsiga', 990, 0, '0000-00-00 00:00:00'),
	('3 Lekváros bukta', 890, 0, '0000-00-00 00:00:00'),
	('3 Pizzás táska', 890, 0, '0000-00-00 00:00:00'),
	('3 Sonkás szendvics', 990, 0, '0000-00-00 00:00:00'),
	('3 Rántotthúsos szendvics', 1090, 0, '0000-00-00 00:00:00'),
	('4 Kakaóscsiga', 990, 0, '0000-00-00 00:00:00'),
	('4 Lekváros bukta', 890, 0, '0000-00-00 00:00:00'),
	('4 Pizzás táska', 890, 0, '0000-00-00 00:00:00'),
	('4 Sonkás szendvics', 990, 0, '0000-00-00 00:00:00'),
	('4 Rántotthúsos szendvics', 1090, 0, '0000-00-00 00:00:00'),
	('5 Kakaóscsiga', 990, 0, '0000-00-00 00:00:00'),
	('5 Lekváros bukta', 890, 0, '0000-00-00 00:00:00'),
	('5 Pizzás táska', 890, 0, '0000-00-00 00:00:00'),
	('5 Sonkás szendvics', 990, 0, '0000-00-00 00:00:00'),
	('5 Rántotthúsos szendvics', 1090, 0, '0000-00-00 00:00:00'),
	('6 Kakaóscsiga', 990, 0, '0000-00-00 00:00:00'),
	('6 Lekváros bukta', 890, 0, '0000-00-00 00:00:00'),
	('6 Pizzás táska', 890, 0, '0000-00-00 00:00:00'),
	('6 Sonkás szendvics', 990, 0, '0000-00-00 00:00:00'),
	('6 Rántotthúsos szendvics', 1090, 0, '0000-00-00 00:00:00'),
	('7 Kakaóscsiga', 990, 0, '0000-00-00 00:00:00'),
	('7 Lekváros bukta', 890, 0, '0000-00-00 00:00:00'),
	('7 Pizzás táska', 890, 0, '0000-00-00 00:00:00'),
	('7 Sonkás szendvics', 990, 0, '0000-00-00 00:00:00'),
	('7 Rántotthúsos szendvics', 1090, 0, '0000-00-00 00:00:00'),
	('8 Kakaóscsiga', 990, 0, '0000-00-00 00:00:00'),
	('8 Lekváros bukta', 890, 0, '0000-00-00 00:00:00'),
	('8 Pizzás táska', 890, 0, '0000-00-00 00:00:00'),
	('8 Sonkás szendvics', 990, 0, '0000-00-00 00:00:00'),
	('8 Rántotthúsos szendvics', 1090, 0, '0000-00-00 00:00:00'),
	('9 Kakaóscsiga', 990, 0, '0000-00-00 00:00:00'),
	('9 Lekváros bukta', 890, 0, '0000-00-00 00:00:00'),
	('9 Pizzás táska', 890, 0, '0000-00-00 00:00:00'),
	('9 Sonkás szendvics', 990, 0, '0000-00-00 00:00:00'),
	('9 Rántotthúsos szendvics', 1090, 0, '0000-00-00 00:00:00'),
	('10 Kakaóscsiga', 990, 0, '0000-00-00 00:00:00'),
	('10 Lekváros bukta', 890, 0, '0000-00-00 00:00:00'),
	('10 Pizzás táska', 890, 0, '0000-00-00 00:00:00'),
	('10 Sonkás szendvics', 990, 0, '0000-00-00 00:00:00'),
	('10 Rántotthúsos szendvics', 1090, 0, '0000-00-00 00:00:00'),
	('11 Kakaóscsiga', 990, 0, '0000-00-00 00:00:00'),
	('11 Lekváros bukta', 890, 0, '0000-00-00 00:00:00'),
	('11 Pizzás táska', 890, 0, '0000-00-00 00:00:00'),
	('11 Sonkás szendvics', 990, 0, '0000-00-00 00:00:00'),
	('11 Rántotthúsos szendvics', 1090, 0, '0000-00-00 00:00:00'),
	('12 Kakaóscsiga', 990, 0, '0000-00-00 00:00:00'),
	('12 Lekváros bukta', 890, 0, '0000-00-00 00:00:00'),
	('12 Pizzás táska', 890, 0, '0000-00-00 00:00:00'),
	('12 Sonkás szendvics', 990, 0, '0000-00-00 00:00:00'),
	('12 Rántotthúsos szendvics', 1090, 0, '0000-00-00 00:00:00'),
	('13 Kakaóscsiga', 990, 0, '0000-00-00 00:00:00'),
	('13 Lekváros bukta', 890, 0, '0000-00-00 00:00:00'),
	('13 Pizzás táska', 890, 0, '0000-00-00 00:00:00'),
	('13 Sonkás szendvics', 990, 0, '0000-00-00 00:00:00'),
	('13 Rántotthúsos szendvics', 1090, 0, '0000-00-00 00:00:00'),
	('14 Kakaóscsiga', 990, 0, '0000-00-00 00:00:00'),
	('14 Lekváros bukta', 890, 0, '0000-00-00 00:00:00'),
	('14 Pizzás táska', 890, 0, '0000-00-00 00:00:00'),
	('14 Sonkás szendvics', 990, 0, '0000-00-00 00:00:00'),
	('14 Rántotthúsos szendvics', 1090, 0, '0000-00-00 00:00:00'),
	('15 Kakaóscsiga', 990, 0, '0000-00-00 00:00:00'),
	('15 Lekváros bukta', 890, 0, '0000-00-00 00:00:00'),
	('15 Pizzás táska', 890, 0, '0000-00-00 00:00:00'),
	('15 Sonkás szendvics', 990, 0, '0000-00-00 00:00:00'),
	('15 Rántotthúsos szendvics', 1090, 0, '0000-00-00 00:00:00'),
	('16 Kakaóscsiga', 990, 0, '0000-00-00 00:00:00'),
	('16 Lekváros bukta', 890, 0, '0000-00-00 00:00:00'),
	('16 Pizzás táska', 890, 0, '0000-00-00 00:00:00'),
	('16 Sonkás szendvics', 990, 0, '0000-00-00 00:00:00'),
	('16 Rántotthúsos szendvics', 1090, 0, '0000-00-00 00:00:00');

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
