local user = {
    name = "servers",
    desc = "服务器列表",
    columns = {
        { "idx", "int(11) NOT NULL", "唯一标识" },
        { "appid", "int(11)  NOT NULL", "应用id" },
        { "channel", "int(11)  NOT NULL", "渠道id" },
        { "name", "varchar(45) NOT NULL", "服务器名" },
        { "status", "int(1)", "状态 0:正常; 1:爆满; 2:维护" },
        { "isnew", "bool", "新服" },
    },
    primaryKey = { "idx", "appid", "channel"},
    cacheKey = { "idx" }, -- 缓存key
    groupKey = "appid", -- 组key
    defaultData = {}, -- 初始数据
}

return user
