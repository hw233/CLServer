local tab = {
    name = "tech",
    desc = "科技表",
    columns = {
        {"idx", "int(11) NOT NULL", "唯一标识"},
        {"id", "TINYINT NOT NULL", "配置id"},
        {"cidx", "int(11)", "城idx"},
        {"lev", "TINYINT", "等级"}
    },
    primaryKey = {"idx"},
    cacheKey = {"idx"}, -- 缓存key
    groupKey = {{"cidx"}}, -- 组key
    defaultData = {}, -- 初始数据
    needBak = true
}

return tab
