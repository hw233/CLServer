local tab = {
    name = "worldmap",
    desc = "世界地图",
    columns = {
        { "idx", "INT(10) NOT NULL", "网格index" },
        { "type", "TINYINT NOT NULL", "地块类型 1：玩家，2：npc" },
        { "cidx", "INT(11)", "主城idx" },
        { "pageIdx", "INT(11) NOT NULL", "所在屏的index"},
        { "val1", "INT(11)", "值1" },
        { "val2", "INT(11)", "值2" },
        { "val3", "INT(11)", "值3" },
    },
    primaryKey = {
        "idx",
    },
    cacheKey = { -- 缓存key
        "idx",
    },
    groupKey  = { -- 缓存组key
        {"pageIdx"},
    },
    defaultData = {}, -- 初始数据
}
return tab
