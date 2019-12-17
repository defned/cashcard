CREATE DATABASE `cashcard` /*!40100 COLLATE 'utf8_general_ci' */;
USE `cashcard`;

CREATE TABLE `balance` (
	`id` VARCHAR(50) NOT NULL COMMENT 'Card id',
	`name` VARCHAR(100) NOT NULL COMMENT 'Name',
	`balance` INT(11) NOT NULL DEFAULT 0 COMMENT 'Total balance',
	`del_sp` DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00' COMMENT 'Time of deletion',
	PRIMARY KEY (`id`, `del_sp`)
)
COLLATE='utf8_general_ci'
ENGINE=InnoDB
;


CREATE TABLE `balance_log` (
	`id` VARCHAR(50) NOT NULL COMMENT 'Card id',
	`eff_sp` DATETIME NOT NULL COMMENT 'Effective stamp',
	`amount` INT(11) NOT NULL DEFAULT 0 COMMENT 'Amount',
	INDEX `FK_balance_log_balance` (`id`),
	CONSTRAINT `FK_balance_log_balance` FOREIGN KEY (`id`) REFERENCES `balance` (`id`)
)
COLLATE='utf8_general_ci'
ENGINE=InnoDB
;

DELIMITER //

CREATE OR REPLACE TRIGGER insert_balance_log 
AFTER
UPDATE
   ON `balance` FOR EACH ROW
BEGIN
	 INSERT INTO `balance_log` (id, eff_sp, amount) VALUES (NEW.id, SYSDATE(), NEW.balance - OLD.balance);
END; //

DELIMITER ;