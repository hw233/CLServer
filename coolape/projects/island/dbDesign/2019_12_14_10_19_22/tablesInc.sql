create database if not exists `island`;
use `island`;
alter table fleet ADD task TINYINT; # 执行任务类型 idel = 1, -- 待命状态;voyage = 2, -- 出征;back = 3, -- 返航;attack = 4 -- 攻击