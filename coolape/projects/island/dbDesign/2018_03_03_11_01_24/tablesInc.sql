create database if not exists `island`;
use `island`;
alter table building MODIFY pos int(8) NOT NULL # 位置，即在城的gird中的index