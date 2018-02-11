local tab = {
    name = "tile",
    desc = "地块表",
    columns = {
        { "idx", "int(11) NOT NULL", "唯一标识" },
        { "attrid", "int(11) NOT NULL", "属性id" },
        { "cidx", "int(11) NOT NULL", "主城idx" },
        { "pos", "int(11)", "城所在世界grid的index" },
    },
    primaryKey = { "idx", "cidx" },
    cacheKey = { "idx" }, -- 缓存key
    groupKey = "cidx", -- 组key
    defaultData = {}, -- 初始数据
}

return tab
