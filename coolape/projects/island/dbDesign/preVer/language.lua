local tab = {
    name = "language",
    desc = "语言表(国际化)",
    columns = {
        {"language", "TINYINT NOT NULL", "语言类别"},
        {"ckey", "varchar(128) NOT NULL", "内容key"},
        {"content", "text", "内容"}
    },
    primaryKey = {"language", "ckey"},
    cacheKey = {"language", "ckey"}, -- 缓存key
    groupKey = {{"ckey"}}, -- 组key
    defaultData = {} -- 初始数据
}

return tab
