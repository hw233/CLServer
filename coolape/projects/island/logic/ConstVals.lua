---@public 常量定义
ConstVals = {
    headquartersBuildingID = 1,
    foodStorageBuildingID = 7,
    goldStorageBuildingID = 11,
    oildStorageBuildingID = 9,
    baseRes = 50000, -- 基础资源量
}

ConstVals.BuildingState = {
    normal = 0, --正常
    upgrade = 1, --升级中
    renew = 9, -- 恢复中
}

---@public 游戏中各种类型
ConstVals.UnitType = {
    building = 1,
    ship = 2,
    tech = 3,
    pet = 4,
    skill = 5,
}

---@public 资源各类
ConstVals.ResType = {
    food = 1,
    gold = 2,
    oil = 3,
    diam = 9,
}
return ConstVals
