local tab = {
    name = "building",
    desc = "建筑表",
    columns = {
        { "idx", "int(11) NOT NULL", "唯一标识" },
        { "cidx", "int(11)  NOT NULL", "主城idx" },
        { "pos", "int(8) NOT NULL", "位置，即在城的gird中的index" },
        { "attrid", "int(5)", "属性配置id" },
        { "lev", "int(5)", "等级" },
        { "state", "INT(1)", "状态. 0：正常；1：升级中；9：恢复中" },
        { "starttime", "DATETIME", "开始升级、恢复、采集等的时间点" },
        { "endtime", "DATETIME", "完成升级、恢复、采集等的时间点" },
        { "val", "bigint(14)", "值。如:产量，仓库的存储量等" },
        { "val2", "bigint(14)", "值2。如:产量，仓库的存储量等" },
        { "val3", "bigint(14)", "值3。如:产量，仓库的存储量等" },
        { "val4", "bigint(14)", "值4。如:产量，仓库的存储量等" },
        { "val5", "bigint(14)", "值5。如:产量，仓库的存储量等" },
        { "valstr", "VARCHAR(2000)", "string类型的值" },
        { "valstr2", "VARCHAR(2000)", "string类型的值" },
    },
    primaryKey = {
        "idx",
        "cidx",
    },
    cacheKey = { -- 缓存key
        "idx",
    },
    groupKey  = { -- 缓存组key
    {
        "cidx",
    },
    },
    defaultData = {}, -- 初始数据
}
return tab
