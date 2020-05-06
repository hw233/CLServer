local tab = {
    name = "itemsused",
    desc = "道具物品使用记录",
    columns = {
        {"idx", "int(11) NOT NULL", "唯一标识"},
        {"itemidx", "int(11) NOT NULL", "道具唯一标识"},
        {"pidx", "int(11) NOT NULL", "玩家唯一标识"},
        {"id", "int(11) NOT NULL", "对应的id"},
        {"type", "TINYINT NOT NULL", "类型,IDConst.ItemType"},
        {"num", "int(11)", "数量"},
        {"dateuse", "datetime", "使用时间"},
        {"dec", "varchar(128)", "使用备注"}
    },
    primaryKey = {"idx"},
    cacheKey = {"idx"}, -- 缓存key
    groupKey = {{"pidx"}}, -- 组key
    defaultData = {} -- 初始数据
}

return tab
