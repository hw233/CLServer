local user = {
    name = "user",
    desc = "用户表",
    columns = {
    --{ "idx", "int(11) NOT NULL AUTO_INCREMENT", "唯一标识" },
        { "uid", "varchar(45) NOT NULL", "用户id" },
        { "password", "varchar(45) NOT NULL", "用户密码" },
        { "crtTime", "datetime", "创建时间" },
        { "lastEnTime", "datetime", "最后登陆时间" },
        { "status", "int(11)", "状态 0:正常;" },
        { "appid", "int(11) ", "应用id" },
        { "channel", "varchar(45)", "渠道" },
        { "deviceid", "varchar(45)", "机器id" },
        { "deviceinfor", "varchar(128)", "机器信息" },
    },
    primaryKey = { "uid" },
    cacheKey = { "uid" }, -- 缓存key
    groupKey = "", -- 组key
    defaultData = {}, -- 初始数据
}

return user
