local tab = {
    name = "rewardpkg",
    desc = "奖励包(礼包)",
    columns = {
        {"idx", "int(11) NOT NULL", "唯一标识"},
        {"rwidx", "int(11) NOT NULL", "奖励包idx"},
        {"type", "TINYINT NOT NULL", "类型,IDConst.ItemType"},
        {"id", "int(11)  NOT NULL", "对应的id"},
        {"num", "int(11)", "数量"},
        {"permillage", "int(5)", "掉落千分率"}
    },
    primaryKey = {"idx", "rwidx"},
    cacheKey = {"idx"}, -- 缓存key
    groupKey = {{"rwidx"}}, -- 组key
    defaultData = {}, -- 初始数据
    needBak = true -- 需要备份
}

return tab
