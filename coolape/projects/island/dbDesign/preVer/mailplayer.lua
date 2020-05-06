local tab = {
    name = "mailplayer",
    desc = "邮件与用户的关系表",
    columns = {
        {"pidx", "int(11) NOT NULL", "玩家唯一标识"},
        {"midx", "int(11) NOT NULL", "邮件唯一标识"},
        {"state", "TINYINT", "状态，0：未读，1：已读&未领奖，2：已读&已领奖"},
    },
    primaryKey = {"pidx", "midx"},
    cacheKey = {"pidx", "midx"}, -- 缓存key
    groupKey = {{"pidx"}, {"midx"}}, -- 组key
    defaultData = {}, -- 初始数据
    needBak = true -- 需要备份
}

return tab
