create database if not exists `usermgr`;
use `usermgr`;
alter table servers ADD pcVer varchar(24); # 客户端PC版本
alter table servers ADD macVer varchar(24); # 客户端Mac版本
alter table servers ADD note varchar(256); # 备注说明