create database if not exists `island`;
use `island`;
#----------------------------------------------------
#---- 舰队
DROP TABLE IF EXISTS `fleet`;
CREATE TABLE `fleet` (
  `idx` int(11) NOT NULL,
  `pidx` int(11) NOT NULL,
  `name` varchar(45),
  `pos` int(11),
  `status` TINYINT,
  `deadtime` datetime,
  PRIMARY KEY (`idx`, `pidx`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
#----------------------------------------------------
#---- 单元(舰船、盟宠等)
DROP TABLE IF EXISTS `unit`;
CREATE TABLE `unit` (
  `idx` int(11) NOT NULL,
  `id` TINYINT,
  `bidx` int(11) NOT NULL,
  `fidx` int(11),
  `num` int(11),
  PRIMARY KEY (`idx`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;