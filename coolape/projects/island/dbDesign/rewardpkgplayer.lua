local tab = {
    name = "rewardpkgplayer",
    desc = "用户的奖励包",
    columns = {
        {"pidx", "int(11) NOT NULL", "玩家唯一标识"},
        {"rwidx", "int(11) NOT NULL", "邮件唯一标识"},
    },
    primaryKey = {"pidx", "rwidx"},
    cacheKey = {"pidx", "rwidx"}, -- 缓存key
    groupKey = {{"pidx"},{"rwidx"}}, -- 组key
    defaultData = {}, -- 初始数据
    needBak = true -- 需要备份
}

return tab
