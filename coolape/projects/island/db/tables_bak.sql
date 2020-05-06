create database if not exists `island_bak`;
use `island_bak`;
alter database island_bak character set utf8;
#----------------------------------------------------
#---- 宝箱(礼包)
DROP TABLE IF EXISTS `box`;
CREATE TABLE `box` (
  `idx` int(11) NOT NULL COMMENT '唯一标识',
  `rwidx` int(11) NOT NULL COMMENT '奖励包idx、掉落idx',
  `icon` varchar(128) COMMENT '图标',
  `nameKey` varchar(128) COMMENT '名称key',
  `descKey` varchar(128) COMMENT '描述key',
  `maxOutput` int(4) NOT NULL COMMENT '最大掉落数，如果小于等于0则没有限制',
  PRIMARY KEY (`idx`, `rwidx`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
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
  `protectEndTime` Datetime COMMENT '免战结束时间',
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
#---- 道具物品
DROP TABLE IF EXISTS `items`;
CREATE TABLE `items` (
  `idx` int(11) NOT NULL COMMENT '唯一标识',
  `pidx` int(11) NOT NULL COMMENT '玩家唯一标识',
  `id` int(11) NOT NULL COMMENT '对应的id',
  `type` TINYINT NOT NULL COMMENT '类型，1：资源、经验值等（领奖就直接把数值加上），2：加速(建筑、造船、科技)，3：护盾4：碎片(海怪碎片)，5：图纸，6：舰船，7：复活药水(建筑、海怪)99：宝箱(嵌套礼包)',
  `num` int(11) COMMENT '数量',
  PRIMARY KEY (`idx`, `pidx`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
#----------------------------------------------------
#---- 邮件表
DROP TABLE IF EXISTS `mail`;
CREATE TABLE `mail` (
  `idx` int(11) NOT NULL COMMENT '唯一标识',
  `parent` int(11) COMMENT '父idx(其实就是邮件的idx，回复的邮件指向的主邮件的idx)',
  `type` TINYINT COMMENT '类型，1：系统，2：战报；3：私信，4:联盟，5：客服',
  `fromPidx` int(11) COMMENT '发件人',
  `toPidx` int(11) COMMENT '收件人',
  `titleKey` varchar(128) COMMENT '标题key',
  `titleParams` varchar(512) COMMENT '标题的参数(json的map)',
  `contentKey` varchar(128) COMMENT '内容key',
  `contentParams` varchar(512) COMMENT '内容参数(json的map)',
  `date` datetime COMMENT '时间',
  `rewardIdx` int(11) COMMENT '奖励idx',
  `comIdx` int(11) COMMENT '通用ID,可以关联到比如战报id等',
  `backup` VARCHAR(256) COMMENT '备用',
  PRIMARY KEY (`idx`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
#----------------------------------------------------
#---- 邮件与用户的关系表
DROP TABLE IF EXISTS `mailplayer`;
CREATE TABLE `mailplayer` (
  `pidx` int(11) NOT NULL COMMENT '玩家唯一标识',
  `midx` int(11) NOT NULL COMMENT '邮件唯一标识',
  `state` TINYINT COMMENT '状态，0：未读，1：已读&未领奖，2：已读&已领奖',
  PRIMARY KEY (`pidx`, `midx`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
#----------------------------------------------------
#---- 玩家表
DROP TABLE IF EXISTS `player`;
CREATE TABLE `player` (
  `idx` int(11) NOT NULL COMMENT '唯一标识',
  `status` TINYINT COMMENT '状态 1:正常;2:封号',
  `type` TINYINT COMMENT '类型 -1:GM,0:普通',
  `name` varchar(45) COMMENT '名称',
  `icon` int(4) COMMENT '头像id',
  `language` TINYINT COMMENT '语言id',
  `lev` int(4) COMMENT '等级',
  `exp` int(11) COMMENT '经验值',
  `honor` int(11) COMMENT '功勋',
  `money` int(11) COMMENT '充值总数',
  `diam` int(11) COMMENT '钻石',
  `diam4reward` int(11) COMMENT '系统奖励钻石',
  `cityidx` int(11) COMMENT '主城idx',
  `unionidx` int(11) COMMENT '联盟idx',
  `attacking` Boolean COMMENT '正在攻击玩家的岛屿',
  `beingattacked` Boolean COMMENT '正在被玩家攻击',
  `pvptimesTody` int(4) COMMENT '今天进攻玩家的次数',
  `crtTime` datetime COMMENT '创建时间',
  `lastEnTime` datetime COMMENT '最后登陆时间',
  `channel` varchar(45) COMMENT '渠道',
  `deviceid` varchar(45) COMMENT '机器id',
  PRIMARY KEY (`idx`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
#----------------------------------------------------
#---- 奖励包(礼包)
DROP TABLE IF EXISTS `rewardpkg`;
CREATE TABLE `rewardpkg` (
  `idx` int(11) NOT NULL COMMENT '唯一标识',
  `rwidx` int(11) NOT NULL COMMENT '奖励包idx',
  `type` TINYINT NOT NULL COMMENT '类型,IDConst.ItemType',
  `id` int(11)  NOT NULL COMMENT '对应的id',
  `num` int(11) COMMENT '数量',
  `permillage` int(5) COMMENT '掉落千分率',
  PRIMARY KEY (`idx`, `rwidx`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
#----------------------------------------------------
#---- 用户的奖励包
DROP TABLE IF EXISTS `rewardpkgplayer`;
CREATE TABLE `rewardpkgplayer` (
  `pidx` int(11) NOT NULL COMMENT '玩家唯一标识',
  `rwidx` int(11) NOT NULL COMMENT '邮件唯一标识',
  PRIMARY KEY (`pidx`, `rwidx`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
#----------------------------------------------------
#---- 科技表
DROP TABLE IF EXISTS `tech`;
CREATE TABLE `tech` (
  `idx` int(11) NOT NULL COMMENT '唯一标识',
  `id` TINYINT NOT NULL COMMENT '配置id',
  `cidx` int(11) COMMENT '城idx',
  `lev` TINYINT COMMENT '等级',
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
  `type` TINYINT COMMENT '类别的id',
  `bidx` int(11) NOT NULL COMMENT '所属建筑idx',
  `fidx` int(11) COMMENT '所属舰队idx',
  `num` int(11) COMMENT '数量',
  PRIMARY KEY (`idx`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;