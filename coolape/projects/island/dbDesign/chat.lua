local tab = {
    name = "chat",
    desc = "聊天表",
    columns = {
        {"idx", "int(11) NOT NULL", "唯一标识"},
        {"type", "TINYINT NOT NULL", "类型, IDConst.ChatType"},
        {"content", "varchar(1024)", "内容"},
        {"fromPidx", "int(11) NOT NULL", "发送人"},
        {"toPidx", "int(11) NOT NULL", "收信人"},
        {"time", "datetime", "发送时间"}
    },
    primaryKey = {"idx"},
    cacheKey = {"idx"}, -- 缓存key
    groupKey = {{"type"}, {"type", "fromPidx"}, {"type", "toPidx"}}, -- 组key
    defaultData = {}, -- 初始数据
    needBak = false
}

return tab
