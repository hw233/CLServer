local tab = {
    name = "box",
    desc = "宝箱(礼包)",
    columns = {
        {"idx", "int(11) NOT NULL", "唯一标识"},
        {"rwidx", "int(11) NOT NULL", "奖励包idx、掉落idx"},
        {"icon", "varchar(128)", "图标"},
        {"nameKey", "varchar(128)", "名称key"},
        {"descKey", "varchar(128)", "描述key"},
        {"maxOutput", "int(4) NOT NULL", "最大掉落数，如果小于等于0则没有限制"}
    },
    primaryKey = {"idx", "rwidx"},
    cacheKey = {"idx"}, -- 缓存key
    groupKey = {{"rwidx"}}, -- 组key
    defaultData = {}, -- 初始数据
    needBak = true -- 需要备份
}

return tab
