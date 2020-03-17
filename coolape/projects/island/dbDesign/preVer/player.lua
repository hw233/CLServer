local tab = {
    name = "player",
    desc = "玩家表",
    columns = {
        { "idx", "int(11) NOT NULL", "唯一标识" },
        { "status", "TINYINT", "状态 1:正常;2:封号" },
        { "type", "TINYINT", "类型 -1:GM,0:普通" },
        { "name", "varchar(45)", "名称" },
        { "icon", "int(11)", "头像id" },
        { "language", "TINYINT", "语言id" },
        { "lev", "int(4)", "等级" },
        { "exp", "int(11)", "经验值" },
        { "exp", "int(11)", "经验值" },
        { "point", "int(11)", "功勋" },
        { "money", "int(11)", "充值总数" },
        { "diam", "int(11)", "钻石" },
        { "diam4reward", "int(11)", "系统奖励钻石" },
        { "cityidx", "int(11)", "主城idx" },
        { "unionidx", "int(11)", "联盟idx" },
        { "attacking", "Boolean", "正在攻击玩家的岛屿"},
        { "beingattacked", "Boolean", "正在被玩家攻击"},
        { "crtTime", "datetime", "创建时间" },
        { "lastEnTime", "datetime", "最后登陆时间" },
        { "channel", "varchar(45)", "渠道" },
        { "deviceid", "varchar(45)", "机器id" },
    },
    primaryKey = { "idx", "name"},
    cacheKey = { "idx" }, -- 缓存key
    groupKey = {}, -- 组key
    defaultData = {}, -- 初始数据
}

return tab
