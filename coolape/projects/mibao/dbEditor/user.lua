local _user = {
    name = "user",
    desc = "用户表",
    columns = {
        --{ "idx", "int(11) NOT NULL AUTO_INCREMENT", "唯一标识" },
        { "uid", "varchar(45) NOT NULL", "用户id" },
        { "password", "varchar(45) NOT NULL", "用户密码" },
        { "crtTime", "datetime", "创建时间" },
        { "lastEnTime", "datetime", "最后登陆时间" },
        { "statu", "int(11)", "状态" },
    },
    primaryKey = { "uid", "password" },
    defaultData = {}, -- 初始数据
}

return _user
