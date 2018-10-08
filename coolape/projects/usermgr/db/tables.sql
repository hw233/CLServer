create database if not exists `usermgr`;
use `usermgr`;
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
#---- 服务器列表
DROP TABLE IF EXISTS `servers`;
CREATE TABLE `servers` (
  `idx` int(11) NOT NULL,
  `appid` int(11)  NOT NULL,
  `channel` varchar(11)  NOT NULL,
  `name` varchar(45) NOT NULL,
  `status` int(1),
  `isnew` bool,
  `host` varchar(32) NOT NULL,
  `port` int(11) NOT NULL,
  `androidVer` varchar(24),
  `iosVer` varchar(24),
  PRIMARY KEY (`idx`, `appid`, `channel`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
#----------------------------------------------------
#---- 用户表
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
  `idx` int(11) NOT NULL,
  `uidChl` varchar(45) NOT NULL,
  `uid` varchar(45) NOT NULL,
  `password` varchar(45) NOT NULL,
  `crtTime` datetime,
  `lastEnTime` datetime,
  `status` int(11),
  `email` varchar(45),
  `appid` int(11) ,
  `channel` varchar(45),
  `deviceid` varchar(45),
  `deviceinfor` varchar(128),
  `groupid` TINYINT,
  PRIMARY KEY (`idx`, `uid`, `uidChl`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
#----------------------------------------------------
#---- 用户与服务器关系
DROP TABLE IF EXISTS `userserver`;
CREATE TABLE `userserver` (
  `sidx` int(11) NOT NULL,
  `uidx` int(11) NOT NULL,
  `appid` int(11) NOT NULL,
  PRIMARY KEY (`uidx`, `appid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;