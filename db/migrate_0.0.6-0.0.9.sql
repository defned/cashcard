USE `cashcard`;

DROP TRIGGER `insert_balance_log`;
ALTER TABLE `balance_log` ADD COLUMN `bonus2` TINYINT(4) NOT NULL DEFAULT '0' COMMENT 'Bonus flag' AFTER `bonus`;
ALTER TABLE `balance_log` CHANGE COLUMN `eff_sp` `eff_sp` DATETIME NOT NULL DEFAULT SYSDATE() COMMENT 'Effective stamp' AFTER `bonus`;