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