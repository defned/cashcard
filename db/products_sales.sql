USE `cashcard`;

CREATE TABLE `product` (
	`id` MEDIUMINT NOT NULL AUTO_INCREMENT COMMENT 'Id',
	`name` VARCHAR(100) NOT NULL COMMENT 'Name',
	`price_huf` INT(10) NOT NULL DEFAULT 0 COMMENT 'Price HUF',
	`favourite` BOOL NOT NULL DEFAULT false COMMENT 'Is favourite?',
	`del_sp` DATETIME NULL DEFAULT 0 COMMENT 'Deletion timestamp',
	PRIMARY KEY (`id`, `del_sp`)
)
COLLATE='utf8_general_ci'
ENGINE=InnoDB
;

CREATE TABLE `sale_log` (
	`id` MEDIUMINT NOT NULL AUTO_INCREMENT COMMENT 'Id',
	`balance_id` VARCHAR(50) NOT NULL COMMENT 'Balance id',
	`product_id` MEDIUMINT NULL COMMENT 'Product id',
	`product_name` VARCHAR(100) NULL COMMENT 'Product name',
	`product_favourite` BOOL NULL COMMENT 'Product is favourite?',
	`product_price_huf` INT(10) NOT NULL COMMENT 'Product price',
	`eff_sp` DATETIME NOT NULL DEFAULT SYSDATE() COMMENT 'Effective timestamp',
	PRIMARY KEY (`id`)
)
COLLATE='utf8_general_ci'
ENGINE=InnoDB
;

DELIMITER //
CREATE OR REPLACE TRIGGER insert_sales BEFORE INSERT
 ON `sales` FOR EACH ROW
BEGIN
	
	-- PRODUCT_ID or PRODUCT_PRICE_HUF must be filled
	IF NEW.product_id IS NULL AND NEW.product_price_huf IS NULL THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Missing PRODUCT_ID or PRODUCT_PRICE_HUF';
	END IF;

	-- BALANCE_ID must be filled
	IF NEW.balance_id IS NULL THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Missing BALANCE_ID';
	END IF;
	
	-- Find the given product details
	IF NEW.product_id IS NOT NULL THEN
		SELECT
			`name`,
			`price_huf`,
			`favourite`
		INTO
			@product_name,
			@product_price_huf,
			@product_favourite
		FROM
			`product`
		WHERE
			`id` = NEW.product_id;
		
		SET NEW.product_name = @product_name;
		SET NEW.product_price_huf = @product_price_huf;
		SET NEW.product_favourite = @product_favourite;
	END IF;
	
	-- BALANCE_ID must be valid
	SELECT `balance` INTO @orig_balance FROM `balance` WHERE `id` = NEW.balance_id;
	
	IF @orig_balance IS NULL THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Invalid BALANCE_ID';
	END IF;
	
	UPDATE `balance` SET `balance` = @orig_balance - NEW.product_price_huf;

END
END; //
DELIMITER ;