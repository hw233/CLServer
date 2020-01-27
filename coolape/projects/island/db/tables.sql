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
  `idx` int(11) NOT NULL COMMENT '唯一标识',
  `cidx` int(11)  NOT NULL COMMENT '主城idx',
  `pos` int(8) NOT NULL COMMENT '位置，即在城的gird中的index',
  `attrid` int(5) COMMENT '属性配置id',
  `lev` int(5) COMMENT '等级',
  `state` TINYINT COMMENT '状态. 0：正常；1：升级中；9：恢复中',
  `starttime` DATETIME COMMENT '开始升级、恢复、采集等的时间点',
  `endtime` DATETIME COMMENT '完成升级、恢复、采集等的时间点',
  `val` bigint(14) COMMENT '值。如:产量，仓库的存储量等',
  `val2` bigint(14) COMMENT '值2。如:产量，仓库的存储量等',
  `val3` bigint(14) COMMENT '值3。如:产量，仓库的存储量等',
  `val4` bigint(14) COMMENT '值4。如:产量，仓库的存储量等',
  `val5` bigint(14) COMMENT '值5。如:产量，仓库的存储量等',
  `valstr` VARCHAR(2000) COMMENT 'string类型的值',
  `valstr2` VARCHAR(2000) COMMENT 'string类型的值',
  PRIMARY KEY (`idx`, `cidx`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
#----------------------------------------------------
#---- 主城表
DROP TABLE IF EXISTS `city`;
CREATE TABLE `city` (
  `idx` int(11) NOT NULL COMMENT '唯一标识',
  `name` varchar(45) COMMENT '名称',
  `pidx` int(11) NOT NULL COMMENT '玩家idx',
  `pos` int(11) COMMENT '城所在世界grid的index',
  `status` TINYINT COMMENT '状态 1:正常;',
  PRIMARY KEY (`idx`, `pidx`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
#----------------------------------------------------
#---- 舰队
DROP TABLE IF EXISTS `fleet`;
CREATE TABLE `fleet` (
  `idx` int(11) NOT NULL COMMENT '唯一标识',
  `cidx` int(11) NOT NULL COMMENT '城市idx',
  `name` varchar(45) COMMENT '名称',
  `curpos` int(11) COMMENT '当前所在世界grid的index',
  `frompos` int(11) COMMENT '出征的开始所在世界grid的index',
  `topos` int(11) COMMENT '出征的目地所在世界grid的index',
  `task` TINYINT COMMENT '执行任务类型 idel = 1, -- 待命状态;voyage = 2, -- 出征;back = 3, -- 返航;attack = 4 -- 攻击',
  `status` TINYINT COMMENT '状态 none = 1, -- 无;moving = 2, -- 航行中;docked = 3, -- 停泊在港口;stay = 4, -- 停留在海面;fighting = 5 -- 正在战斗中',
  `arrivetime` datetime COMMENT '到达时间',
  `deadtime` datetime COMMENT '沉没的时间',
  PRIMARY KEY (`idx`, `cidx`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
#----------------------------------------------------
#---- 玩家表
DROP TABLE IF EXISTS `player`;
CREATE TABLE `player` (
  `idx` int(11) NOT NULL COMMENT '唯一标识',
  `status` int(11) COMMENT '状态 1:正常;',
  `name` varchar(45) COMMENT '名称',
  `lev` int(4) COMMENT '等级',
  `exp` int(11) COMMENT '经验值',
  `money` int(11) COMMENT '充值总数',
  `diam` int(11) COMMENT '钻石',
  `diam4reward` int(11) COMMENT '系统奖励钻石',
  `cityidx` int(11) COMMENT '主城idx',
  `unionidx` int(11) COMMENT '联盟idx',
  `crtTime` datetime COMMENT '创建时间',
  `lastEnTime` datetime COMMENT '最后登陆时间',
  `channel` varchar(45) COMMENT '渠道',
  `deviceid` varchar(45) COMMENT '机器id',
  PRIMARY KEY (`idx`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
#----------------------------------------------------
#---- 地块表
DROP TABLE IF EXISTS `tile`;
CREATE TABLE `tile` (
  `idx` int(11) NOT NULL COMMENT '唯一标识',
  `cidx` int(11) NOT NULL COMMENT '主城idx',
  `attrid` int(11) NOT NULL COMMENT '属性id',
  `pos` int(11) COMMENT '城所在世界grid的index',
  PRIMARY KEY (`idx`, `cidx`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
#----------------------------------------------------
#---- 单元(舰船、盟宠等)
DROP TABLE IF EXISTS `unit`;
CREATE TABLE `unit` (
  `idx` int(11) NOT NULL COMMENT '唯一标识',
  `id` TINYINT COMMENT '配置数量的id',
  `bidx` int(11) NOT NULL COMMENT '所属建筑idx',
  `fidx` int(11) COMMENT '所属舰队idx',
  `num` int(11) COMMENT '数量',
  PRIMARY KEY (`idx`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
#----------------------------------------------------
#---- 世界地图
DROP TABLE IF EXISTS `worldmap`;
CREATE TABLE `worldmap` (
  `idx` INT(10) NOT NULL COMMENT '网格index',
  `type` TINYINT NOT NULL COMMENT '地块类型 3：玩家，2：npc',
  `attrid` INT COMMENT '配置id',
  `cidx` INT(11) COMMENT '主城idx',
  `fidx` INT(11) COMMENT '驻扎在改地块的舰队idx',
  `pageIdx` INT(11) NOT NULL COMMENT '所在屏的index',
  `val1` INT(11) COMMENT '值1',
  `val2` INT(11) COMMENT '值2',
  `val3` INT(11) COMMENT '值3',
  PRIMARY KEY (`idx`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;