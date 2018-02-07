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
  `cidx` varchar(45) NOT NULL,
  `pos` varchar(45) NOT NULL,
  `attrid` int(5),
  `lev` int(5),
  `val` int(11),
  `val2` int(11),
  `val3` int(11),
  `val4` int(11),
  PRIMARY KEY (`idx`, `cidx`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
#----------------------------------------------------
#---- 主城表
DROP TABLE IF EXISTS `city`;
CREATE TABLE `city` (
  `idx` int(11) NOT NULL,
  `name` varchar(45),
  `pidx` varchar(45) NOT NULL,
  `pos` int(11),
  `status` int(11),
  `lev` int(4),
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