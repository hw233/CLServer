local tab = {
    name = "unit",
    desc = "单元(舰船、盟宠等)",
    columns = {
        {"idx", "int(11) NOT NULL", "唯一标识"},
        {"id", "TINYINT", "配置数量的id"},
        {"type", "TINYINT", "类别的id"},
        {"bidx", "int(11) NOT NULL", "所属建筑idx"},
        {"fidx", "int(11)", "所属舰队idx"},
        {"num", "int(11)", "数量"}
    },
    primaryKey = {"idx"},
    cacheKey = {"idx"}, -- 缓存key
    groupKey = {{"bidx"}, {"fidx"}}, -- 组key
    defaultData = {}, -- 初始数据
    needBak = true -- 需要备份
}

return tab
