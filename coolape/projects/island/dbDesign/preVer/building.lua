local tab = {
    name = "building",
    desc = "建筑表",
    columns = {
        { "idx", "int(11) NOT NULL", "唯一标识" },
        { "cidx", "varchar(45) NOT NULL", "主城idx" },
        { "pos", "int(8) NOT NULL", "位置，即在城的gird中的index" },
        { "attrid", "int(5)", "属性配置id" },
        { "lev", "int(5)", "等级" },
        { "state", "INT(1)", "状态. 0：正常；1：升级中；9：恢复中" },
        { "starttime", "DATETIME", "开始升级、恢复、采集等的时间点" },
        { "endtime", "DATETIME", "完成升级、恢复、采集等的时间点" },
        { "val", "int(11)", "值。如:产量，仓库的存储量等" },
        { "val2", "int(11)", "值2。如:产量，仓库的存储量等" },
        { "val3", "int(11)", "值3。如:产量，仓库的存储量等" },
        { "val4", "int(11)", "值4。如:产量，仓库的存储量等" },
        { "val5", "INT(11)", "值5。如:产量，仓库的存储量等" },
    },
    primaryKey = {
        "idx",
        "cidx",
    },
    cacheKey = { -- 缓存key
        "idx",
    },
    groupKey = "cidx", -- 组key
    defaultData = {}, -- 初始数据
}
return tab
