USE `cashcard`;


-- Dumping structure for table cashcard.category
DROP TABLE IF EXISTS `category`;
CREATE TABLE IF NOT EXISTS `category` (
  `id` smallint(6) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL DEFAULT '' COMMENT 'Name of the categroy',
  `color` varchar(10) DEFAULT NULL,
  `del_sp` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- Dumping structure for table cashcard.product
DROP TABLE IF EXISTS `product`;
CREATE TABLE IF NOT EXISTS `product` (
  `id` mediumint(9) NOT NULL AUTO_INCREMENT COMMENT 'Id',
  `code` varchar(100) DEFAULT NULL,
  `name` varchar(100) NOT NULL COMMENT 'Name',
  `price_huf` int(10) NOT NULL DEFAULT 0 COMMENT 'Price HUF',
  `favourite` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'Is favourite?',
  `category_id` smallint(6) NOT NULL DEFAULT 0 COMMENT 'Category of the product',
  `del_sp` datetime NOT NULL DEFAULT '0000-00-00 00:00:00' COMMENT 'Deletion timestamp',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=99 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- Dumping structure for table cashcard.sales
DROP TABLE IF EXISTS `sales`;
CREATE TABLE IF NOT EXISTS `sales` (
  `id` mediumint(9) NOT NULL AUTO_INCREMENT COMMENT 'Id',
  `transaction_id` varchar(50) NOT NULL DEFAULT '0' COMMENT 'Transaction id',
  `balance_id` varchar(50) DEFAULT NULL COMMENT 'Balance id',
  `product_id` mediumint(9) DEFAULT NULL COMMENT 'Product id',
  `product_code` varchar(100) DEFAULT NULL,
  `product_name` varchar(100) NOT NULL COMMENT 'Product name',
  `product_favourite` tinyint(1) DEFAULT NULL COMMENT 'Product is favourite?',
  `product_category_id` tinyint(1) DEFAULT NULL COMMENT 'Product category',
  `product_price_huf` int(10) NOT NULL COMMENT 'Product price',
  `eff_sp` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- Dumping structure for trigger cashcard.insert_balance_log
DROP TRIGGER IF EXISTS `insert_balance_log`;
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER insert_balance_log AFTER UPDATE
 ON `balance` FOR EACH ROW
  INSERT INTO `balance_log` (id, eff_sp, amount) VALUES (NEW.id, SYSDATE(), NEW.balance - OLD.balance)//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Dumping structure for trigger cashcard.insert_sales
DROP TRIGGER IF EXISTS `insert_sales`;
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `insert_sales` BEFORE INSERT ON `sales` FOR EACH ROW BEGIN
	
	-- PRODUCT_ID must be filled
	IF NEW.product_id IS NULL THEN -- AND NEW.product_price_huf IS NULL THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Missing PRODUCT_ID';
	END IF;
	
	-- Find the given product details
	IF NEW.product_id IS NOT NULL THEN
		SELECT
		   `code`,
			`name`,
			`price_huf`,
			`favourite`,
			`category_id`
		INTO
		   @product_code,
			@product_name,
			@product_price_huf,
			@product_favourite,
			@product_category_id
		FROM
			`product`
		WHERE
			`id` = NEW.product_id;
	
		SET NEW.product_code = @product_code;
		SET NEW.product_name = @product_name;
		SET NEW.product_price_huf = @product_price_huf;
		SET NEW.product_favourite = @product_favourite;
		SET NEW.product_category_id = @product_category_id;
	END IF;
	
	IF NEW.balance_id IS NOT NULL THEN
		
		-- BALANCE_ID must be valid
		SELECT `balance` INTO @orig_balance FROM `balance` WHERE `id` = NEW.balance_id;
	
		IF @orig_balance IS NULL THEN
			SIGNAL SQLSTATE '45000'
				SET MESSAGE_TEXT = 'Invalid BALANCE_ID';
		END IF;
	
		UPDATE `balance` SET `balance` = @orig_balance - NEW.product_price_huf WHERE `id` = NEW.balance_id;
	
	END IF;

END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;