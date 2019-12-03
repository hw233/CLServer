create database if not exists `island`;
use `island`;
alter database island character set utf8;
#--DROP TABLE IF EXISTS sequence;
CREATE TABLE IF NOT EXISTS sequence (
     name VARCHAR(50) NOT NULL,
     current_value INT NOT NULL,
     increment INT NOT NULL DEFAULT 1,
     PRIMARY KEY (name)
) ENGINE=InnoDB;


DROP FUNCTION IF EXISTS currval;
DELIMITER $
CREATE FUNCTION currval (seq_name VARCHAR(50))
     RETURNS INTEGER
     LANGUAGE SQL
     DETERMINISTIC
     CONTAINS SQL
     SQL SECURITY DEFINER
     COMMENT ''
BEGIN
     DECLARE value INTEGER;
     SET value = 0;
     SELECT current_value INTO value
          FROM sequence
          WHERE name = seq_name;
     IF value = 0 THEN
          RETURN setval(seq_name, 1);
     END IF;
     RETURN value;
END
$
DELIMITER ;

DROP FUNCTION IF EXISTS nextval;
DELIMITER $
CREATE FUNCTION nextval (seq_name VARCHAR(50))
     RETURNS INTEGER
     LANGUAGE SQL
     DETERMINISTIC
     CONTAINS SQL
     SQL SECURITY DEFINER
     COMMENT ''
BEGIN
     UPDATE sequence
          SET current_value = current_value + increment
          WHERE name = seq_name;
     RETURN currval(seq_name);
END
$
DELIMITER ;

DROP FUNCTION IF EXISTS setval;
DELIMITER $
CREATE FUNCTION setval (seq_name VARCHAR(50), value INTEGER)
     RETURNS INTEGER
     LANGUAGE SQL
     DETERMINISTIC
     CONTAINS SQL
     SQL SECURITY DEFINER
     COMMENT ''
BEGIN
     DECLARE n INTEGER;
     SELECT COUNT(*) INTO n FROM sequence WHERE name = seq_name;
     IF n = 0 THEN
         INSERT INTO sequence VALUES (seq_name, 1, 1);
         RETURN 1;
     END IF;
     UPDATE sequence
          SET current_value = value
          WHERE name = seq_name;
     RETURN currval(seq_name);
END
$
DELIMITER ;
#----------------------------------------------
        
#----------------------------------------------------
#---- 建筑表
DROP TABLE IF EXISTS `building`;
CREATE TABLE `building` (
  `idx` int(11) NOT NULL,
  `cidx` int(11)  NOT NULL,
  `pos` int(8) NOT NULL,
  `attrid` int(5),
  `lev` int(5),
  `state` TINYINT,
  `starttime` DATETIME,
  `endtime` DATETIME,
  `val` bigint(14),
  `val2` bigint(14),
  `val3` bigint(14),
  `val4` bigint(14),
  `val5` bigint(14),
  `valstr` VARCHAR(2000),
  `valstr2` VARCHAR(2000),
  PRIMARY KEY (`idx`, `cidx`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
#----------------------------------------------------
#---- 主城表
DROP TABLE IF EXISTS `city`;
CREATE TABLE `city` (
  `idx` int(11) NOT NULL,
  `name` varchar(45),
  `pidx` int(11) NOT NULL,
  `pos` int(11),
  `status` TINYINT,
  PRIMARY KEY (`idx`, `pidx`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
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
#---- 玩家表
DROP TABLE IF EXISTS `player`;
CREATE TABLE `player` (
  `idx` int(11) NOT NULL,
  `status` int(11),
  `name` varchar(45),
  `lev` int(4),
  `money` int(11),
  `diam` int(11),
  `cityidx` int(11),
  `unionidx` int(11),
  `crtTime` datetime,
  `lastEnTime` datetime,
  `channel` varchar(45),
  `deviceid` varchar(45),
  PRIMARY KEY (`idx`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
#----------------------------------------------------
#---- 地块表
DROP TABLE IF EXISTS `tile`;
CREATE TABLE `tile` (
  `idx` int(11) NOT NULL,
  `cidx` int(11) NOT NULL,
  `attrid` int(11) NOT NULL,
  `pos` int(11),
  PRIMARY KEY (`idx`, `cidx`)
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
#----------------------------------------------------
#---- 世界地图
DROP TABLE IF EXISTS `worldmap`;
CREATE TABLE `worldmap` (
  `idx` INT(10) NOT NULL,
  `type` TINYINT NOT NULL,
  `attrid` INT,
  `cidx` INT(11),
  `pageIdx` INT(11) NOT NULL,
  `val1` INT(11),
  `val2` INT(11),
  `val3` INT(11),
  PRIMARY KEY (`idx`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;