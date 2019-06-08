local tab = {
    name = "servers",
    desc = "服务器列表",
    columns = {
        { "idx", "int(11) NOT NULL", "唯一标识" },
        { "appid", "int(11)  NOT NULL", "应用id" },
        { "channel", "varchar(11)  NOT NULL", "渠道id" },
        { "name", "varchar(45) NOT NULL", "服务器名" },
        { "status", "int(1)", "状态 1:正常; 2:爆满; 3:维护" },
        { "isnew", "bool", "新服" },
        { "host", "varchar(32) NOT NULL", "ip" },
        { "port", "int(11) NOT NULL", "port" },
        { "androidVer", "varchar(24)", "客户端android版本" },
        { "iosVer", "varchar(24)", "客户端ios版本" },
        { "pcVer", "varchar(24)", "客户端PC版本" },
        { "macVer", "varchar(24)", "客户端Mac版本" },
        { "note", "varchar(256)", "备注说明" },
    },
    primaryKey = {
        "idx",
        "appid",
        "channel",
    },
    cacheKey = { -- 缓存key
        "idx",
    },
    groupKey = {{"appid"}}, -- 组key
    defaultData = {}, -- 初始数据
}
return tab
