local tab = {
    name = "user",
    desc = "用户表",
    columns = {
        { "idx", "int(11) NOT NULL", "唯一标识" },
        { "uidChl", "varchar(45) NOT NULL", "用户id(第三方渠道用户)" },
        { "uid", "varchar(45) NOT NULL", "用户id" },
        { "password", "varchar(45) NOT NULL", "用户密码" },
        { "crtTime", "datetime", "创建时间" },
        { "lastEnTime", "datetime", "最后登陆时间" },
        { "status", "int(11)", "状态 0:正常;" },
        { "email", "varchar(45)", "邮箱" },
        { "appid", "int(11) ", "应用id" },
        { "channel", "varchar(45)", "渠道" },
        { "deviceid", "varchar(45)", "机器id" },
        { "deviceinfor", "varchar(128)", "机器信息" },
        { "groupid", "TINYINT", "组id" },
    },
    primaryKey = {
        "idx",
        "uid",
        "uidChl",
    },
    cacheKey = { -- 缓存key
        "uid",
        "uidChl",
    },
    groupKey = {{"deviceid"}, {"channel", "groupid"}}, -- 组key
    defaultData = {}, -- 初始数据
}
return tab
