local tab = {
    name = "building",
    desc = "建筑表",
    columns = {
        { "idx", "int(11) NOT NULL", "唯一标识" },
        { "cidx", "varchar(45) NOT NULL", "主城idx" },
        { "pos", "int(8) NOT NULL", "位置，即在城的gird中的index" },
        { "attrid", "int(5)", "属性配置id" },
        { "lev", "int(5)", "等级" },
        { "val", "int(11)", "值。如:产量，仓库的存储量等" },
        { "val2", "int(11)", "值2。如:产量，仓库的存储量等" },
        { "val3", "int(11)", "值3。如:产量，仓库的存储量等" },
        { "val4", "int(11)", "值4。如:产量，仓库的存储量等" },
    },
    primaryKey = { "idx", "cidx" },
    cacheKey = { "idx" }, -- 缓存key
    groupKey = "cidx", -- 组key
    defaultData = {}, -- 初始数据
}

return tab
