local tab = {
    name = "user",
    desc = "用户表",
    columns = {
        --{ "idx", "int(11) NOT NULL AUTO_INCREMENT", "唯一标识" },
        { "idx", "int(11) NOT NULL", "唯一标识" },
        { "uidChl", "varchar(45) NOT NULL", "用户id(第三方渠道用户)" },
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
    primaryKey = {"idx", "uid", "uidChl" },
    cacheKey = { "uid", "uidChl" }, -- 缓存key
    groupKey = "", -- 组key
    defaultData = {}, -- 初始数据
}

return tab
