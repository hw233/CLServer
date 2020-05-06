local tab = {
    name = "mail",
    desc = "邮件表",
    columns = {
        {"idx", "int(11) NOT NULL", "唯一标识"},
        {"parent", "int(11)", "父idx(其实就是邮件的idx，回复的邮件指向的主邮件的idx)"},
        {"type", "TINYINT", "类型，1：系统，2：战报；3：私信，4:联盟，5：客服"},
        {"fromPidx", "int(11)", "发件人"},
        {"toPidx", "int(11)", "收件人"},
        {"titleKey", "varchar(128)", "标题key"},
        {"titleParams", "varchar(512)", "标题的参数(json的map)"},
        {"contentKey", "varchar(128)", "内容key"},
        {"contentParams", "varchar(512)", "内容参数(json的map)"},
        {"date", "datetime", "时间"},
        {"rewardIdx", "int(11)", "奖励idx"},
        {"comIdx", "int(11)", "通用ID,可以关联到比如战报id等"},
        {"backup", "VARCHAR(256)", "备用"}
    },
    primaryKey = {"idx"},
    cacheKey = {"idx"}, -- 缓存key
    groupKey = {{"parent"}}, -- 组key
    defaultData = {}, -- 初始数据
    needBak = true -- 需要备份
}

return tab
