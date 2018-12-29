create database if not exists `island`;
use `island`;
alter table building MODIFY val bigint(14); # 值。如:产量，仓库的存储量等
alter table building MODIFY val2 bigint(14); # 值2。如:产量，仓库的存储量等
alter table building MODIFY val3 bigint(14); # 值3。如:产量，仓库的存储量等
alter table building MODIFY val4 bigint(14); # 值4。如:产量，仓库的存储量等
alter table building MODIFY val5 bigint(14); # 值5。如:产量，仓库的存储量等