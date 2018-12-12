---@public 常量定义
IDConstVals = {
    headquartersBuildingID = 1, -- 主基地
    dockyardBuildingID = 2,     -- 造船厂
    foodStorageBuildingID = 7,
    goldStorageBuildingID = 11,
    oildStorageBuildingID = 9,
    baseRes = 50000, -- 基础资源量
}

IDConstVals.BuildingState = {
    normal = 0, --正常
    upgrade = 1, --升级中
    working = 2, --工作中
    renew = 9, -- 恢复中
}

---@public 游戏中各种类型
IDConstVals.UnitType = {
    building = 1,
    ship = 2,
    tech = 3,
    pet = 4,
    skill = 5,
}
---@public 角色类别
IDConstVals.RoleGID = {
    worker = 0, -- 工人
    ship = 1, -- 舰船
    solider = 2, -- 陆战兵
    pet = 3, -- 宠物
}

---@public 资源各类
IDConstVals.ResType = {
    food = 1,
    gold = 2,
    oil = 3,
    diam = 9,
}
return IDConstVals
