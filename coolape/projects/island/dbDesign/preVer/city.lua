local tab = {
    name = "city",
    desc = "主城表",
    columns = {
        { "idx", "int(11) NOT NULL", "唯一标识" },
        { "name", "varchar(45)", "名称" },
        { "pidx", "int(11) NOT NULL", "玩家idx" },
        { "pos", "int(11)", "城所在世界grid的index" },
        { "status", "TINYINT", "状态 1:正常;" },
        --{ "lev", "int(4)", "等级" },
        --{ "iron", "int(11)", "铁" },
        --{ "oil", "int(11)", "油" },
        --{ "food", "int(11)", "粮食" },
        --{ "water", "int(11)", "淡水" },
    },
    primaryKey = { "idx", "pidx" },
    cacheKey = { "idx" }, -- 缓存key
    groupKey = {{"pidx"}}, -- 组key
    defaultData = {}, -- 初始数据
}

return tab
