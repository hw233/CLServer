local tab = {
    name = "player",
    desc = "玩家表",
    columns = {
        { "idx", "int(11) NOT NULL", "唯一标识" },
        { "uidx", "varchar(45) NOT NULL", "用户id" },
        { "status", "int(11)", "状态 1:正常;" },
        { "lev", "int(4)", "等级" },
        { "money", "int(11)", "充值总数" },
        { "diam", "int(11)", "钻石" },
        {"cityidx", "int(11)", "主城idx" },
        { "unionidx", "int(11)", "联盟idx" },
        { "crtTime", "datetime", "创建时间" },
        { "lastEnTime", "datetime", "最后登陆时间" },
        { "channel", "varchar(45)", "渠道" },
        { "deviceid", "varchar(45)", "机器id" },
    },
    primaryKey = { "idx", "uid" },
    cacheKey = { "idx" }, -- 缓存key
    groupKey = "", -- 组key
    defaultData = {}, -- 初始数据
}

return tab
