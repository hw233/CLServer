local tab = {
    name = "userserver",
    desc = "用户与服务器关系",
    columns = {
        { "sidx", "int(11) NOT NULL", "服务器id" },
        { "uidx", "int(11) NOT NULL", "用户id" },
        { "appid", "int(11) NOT NULL", "应用id" },
    },
    primaryKey = {"uidx", "appid" },
    cacheKey = { "uidx", "appid" }, -- 缓存key
    groupKey = {}, -- 组key
    defaultData = {}, -- 初始数据
}

return tab
