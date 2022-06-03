DROP DATABASE IF EXISTS `webpos`;
CREATE DATABASE `webpos`;
use webpos;


-- 1. Table Product

DROP TABLE IF EXISTS `product`;
CREATE TABLE `product`
(
    `ID`    varchar(255) NOT NULL,
    `NAME`  varchar(1024) NOT NULL,
    `PRICE` double       NOT NULL,
    `IMAGE` varchar(1024) NOT NULL,
    PRIMARY KEY (`ID`)
) ENGINE = InnoDB
  AUTO_INCREMENT = 1
  DEFAULT CHARSET = UTF8MB4;
