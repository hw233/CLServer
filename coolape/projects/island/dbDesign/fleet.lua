local tab = {
    name = "fleet",
    desc = "舰队",
    columns = {
        {"idx", "int(11) NOT NULL", "唯一标识"},
        {"pidx", "int(11) NOT NULL", "玩家idx"},
        {"name", "varchar(45)", "名称"},
        {"pos", "int(11)", "城所在世界grid的index"},
        {"status", "TINYINT", "状态 1:待命; 2:出征中；3：停靠中"},
        {"deadtime", "datetime", "沉没的时间"},
    },
    primaryKey = {"idx", "pidx"},
    cacheKey = {"idx"}, -- 缓存key
    groupKey = {{"pidx"}}, -- 组key
    defaultData = {} -- 初始数据
}

return tab
