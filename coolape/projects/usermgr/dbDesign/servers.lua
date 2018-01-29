local tab = {
    name = "servers",
    desc = "服务器列表",
    columns = {
        { "idx", "int(11) NOT NULL", "唯一标识" },
        { "appid", "int(11)  NOT NULL", "应用id" },
        { "channel", "int(11)  NOT NULL", "渠道id" },
        { "name", "varchar(45) NOT NULL", "服务器名" },
        { "status", "int(1)", "状态 0:正常; 1:爆满; 2:维护" },
        { "isnew", "bool", "新服" },
        { "androidVer", "varchar(24)", "客户端android版本" },
        { "iosVer", "varchar(24)", "客户端ios版本" },
    },
    primaryKey = { "idx", "appid", "channel" },
    cacheKey = { "idx" }, -- 缓存key
    groupKey = "appid", -- 组key
    defaultData = {}, -- 初始数据
}

return tab