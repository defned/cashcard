CREATE DATABASE `cashcard` /*!40100 COLLATE 'utf8_general_ci' */;

CREATE TABLE `balance` (
	`id` VARCHAR(50) NOT NULL COMMENT 'Card id' PRIMARY KEY,
	`name` VARCHAR(100) NOT NULL COMMENT 'Name',
	`balance` INT(11) NOT NULL DEFAULT 0 COMMENT 'Total balance',
	`del_sp` DATETIME NULL DEFAULT NULL COMMENT 'Time of deletion'
)
ENGINE=InnoDB
;

CREATE TABLE `balance_log` (
	`id` VARCHAR(50) NOT NULL COMMENT 'Card id',
	`eff_sp` DATETIME NOT NULL COMMENT 'Effective stamp',
	`amount` INT(11) NOT NULL DEFAULT 0 COMMENT 'Amount',
	CONSTRAINT `FK_balance_log_balance` FOREIGN KEY (`id`) REFERENCES `balance` (`id`)
)
ENGINE=InnoDB
;

DELIMITER //
CREATE TRIGGER insert_balance_log 
  AFTER UPDATE ON `balance` 
  FOR EACH ROW 
BEGIN
  INSERT (id, eff_sp, amount) VALUES (NEW.id, NOW(), NEW.amount - OLD.amount);
END; //
DELIMITER ;