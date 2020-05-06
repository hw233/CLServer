local tab = {
    name = "fleet",
    desc = "舰队",
    columns = {
        {"idx", "int(11) NOT NULL", "唯一标识"},
        {"cidx", "int(11) NOT NULL", "城市idx"},
        {"name", "varchar(45)", "名称"},
        {"curpos", "int(11)", "当前所在世界grid的index"},
        {"frompos", "int(11)", "出征的开始所在世界grid的index"},
        {"topos", "int(11)", "出征的目地所在世界grid的index"},
        {"task", "TINYINT", "执行任务类型 idel = 1, -- 待命状态;voyage = 2, -- 出征;back = 3, -- 返航;attack = 4 -- 攻击"},
        {
            "status",
            "TINYINT",
            "状态 none = 1, -- 无;moving = 2, -- 航行中;docked = 3, -- 停泊在港口;stay = 4, -- 停留在海面;fighting = 5 -- 正在战斗中"
        },
        {"arrivetime", "datetime", "到达时间"},
        {"deadtime", "datetime", "沉没的时间"}
    },
    primaryKey = {"idx", "cidx"},
    cacheKey = {"idx"}, -- 缓存key
    groupKey = {{"cidx"}}, -- 组key
    defaultData = {}, -- 初始数据
    needBak = true -- 需要备份
}

return tab
