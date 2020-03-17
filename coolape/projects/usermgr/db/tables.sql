create database if not exists `usermgr`;
use `usermgr`;
alter database usermgr character set utf8;
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
  `idx` int(11) NOT NULL COMMENT '唯一标识',
  `appid` int(11)  NOT NULL COMMENT '应用id',
  `channel` varchar(11)  NOT NULL COMMENT '渠道id',
  `name` varchar(45) NOT NULL COMMENT '服务器名',
  `status` int(1) COMMENT '状态 1:正常; 2:爆满; 3:维护',
  `isnew` bool COMMENT '新服',
  `host` varchar(32) NOT NULL COMMENT 'ip',
  `port` int(11) NOT NULL COMMENT 'port',
  `androidVer` varchar(24) COMMENT '客户端android版本',
  `iosVer` varchar(24) COMMENT '客户端ios版本',
  `pcVer` varchar(24) COMMENT '客户端PC版本',
  `macVer` varchar(24) COMMENT '客户端Mac版本',
  `note` varchar(256) COMMENT '备注说明',
  PRIMARY KEY (`idx`, `appid`, `channel`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
#----------------------------------------------------
#---- 用户表
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
  `idx` int(11) NOT NULL COMMENT '唯一标识',
  `uidChl` varchar(45) NOT NULL COMMENT '用户id(第三方渠道用户)',
  `uid` varchar(45) NOT NULL COMMENT '用户id',
  `password` varchar(45) NOT NULL COMMENT '用户密码',
  `crtTime` datetime COMMENT '创建时间',
  `lastEnTime` datetime COMMENT '最后登陆时间',
  `status` int(11) COMMENT '状态 0:正常;',
  `email` varchar(45) COMMENT '邮箱',
  `appid` int(11)  COMMENT '应用id',
  `channel` varchar(45) COMMENT '渠道',
  `deviceid` varchar(45) COMMENT '机器id',
  `deviceinfor` varchar(128) COMMENT '机器信息',
  `groupid` TINYINT COMMENT '组id',
  PRIMARY KEY (`idx`, `uid`, `uidChl`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
#----------------------------------------------------
#---- 用户与服务器关系
DROP TABLE IF EXISTS `userserver`;
CREATE TABLE `userserver` (
  `sidx` int(11) NOT NULL COMMENT '服务器id',
  `uidx` int(11) NOT NULL COMMENT '用户id',
  `appid` int(11) NOT NULL COMMENT '应用id',
  PRIMARY KEY (`uidx`, `appid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;