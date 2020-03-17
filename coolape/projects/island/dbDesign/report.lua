local tab = {
    name = "report",
    desc = "战报",
    columns = {
        {"idx", "int(11) NOT NULL", "唯一标识"},
        {"type", "TINYINT NOT NULL", "类型 1:攻击岛,2:攻击舰队"},
        {"result", "text", "战斗结果(json)，方便可以快速查看战报"},
        {"content", "text", "战报过程等更详细的内容(json)"},
        {"crttime", "datetime", "创建时间"}
    },
    primaryKey = {"idx"},
    cacheKey = {"idx"}, -- 缓存key
    groupKey = {{"idx"}}, -- 组key
    defaultData = {} -- 初始数据
}

return tab
