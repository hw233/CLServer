---@public 常量定义
IDConst = {}
---@public 基础资源量
IDConst.baseRes = 50000

---@public GM账号idx
IDConst.gmPidx = -10000
---@public 系统账号idx
IDConst.sysPidx = -1

---@public 建筑id
IDConst.BuildingID = {
    headquarters = 1, -- 主基地
    dockyard = 2, -- 造船厂
    alliance = 4, -- 联盟港口
    foodStorage = 7,
    goldStorage = 11,
    oildStorage = 9,
    foodFactory = 6,
    goldMine = 10,
    oilWell = 8
}

---@public 建筑类别
IDConst.BuildingGID = {
    spec = -1, -- 特殊建筑
    com = 1, -- 基础建筑
    resource = 2, -- 资源建筑
    defense = 3, -- 防御建筑
    trap = 4, --陷阱
    decorate = 5, -- 装饰
    tree = 6 -- 树
}

IDConst.PlayerType = {
    gm = -1, -- GM
    player = 0, -- 正常
}

IDConst.PlayerState = {
    normal = 1, -- 正常
    forbid = 2, -- 封号
}

IDConst.CityState = {
    normal = 1, -- 正常
    protect = 2 -- 免战保护
}

IDConst.BuildingState = {
    normal = 0, --正常
    upgrade = 1, --升级中
    working = 2, --工作中
    renew = 9 -- 恢复中
}

---@public 战斗类型
IDConst.BattleType = {
    attackIsland = 1, -- 攻击岛
    attackFleet = 2, -- 攻击舰队
}

---@public 游戏中各种类型
IDConst.UnitType = {
    building = 1,
    role = 2, -- (ship, pet)
    tech = 3,
    skill = 4
}
---@public 角色类别
IDConst.RoleGID = {
    worker = 100, -- 工人
    ship = 101, -- 舰船
    solider = 102, -- 陆战兵
    pet = 103 -- 宠物
}

---@public 资源各类
IDConst.ResType = {
    food = 1,
    gold = 2,
    oil = 3,
    diam = 9
}
---@public 大地图地块类型
IDConst.WorldmapCellType = {
    port = 1, -- 港口
    decorate = 2, -- 装饰
    user = 3, -- 玩家
    empty = 4, -- 空地
    fleet = 5, -- 舰队停留
    occupy = 99 -- 占用
}

---@public 舰队任务
IDConst.FleetTask = {
    idel = 1, -- 待命状态
    voyage = 2, -- 出征
    back = 3, -- 返航
    attack = 4 -- 攻击
}
---@public 舰队状态
IDConst.FleetState = {
    none = 1, -- 无
    moving = 2, -- 航行中
    docked = 3, -- 停泊在港口
    stay = 4, -- 停留在海面
    fightingFleet = 5, -- 正在战斗中
    fightingIsland = 6 -- 正在战斗中
}
---@public 免战保护
IDConst.ProtectLev = {
    [1] = 60, -- 1星时，分钟
    [2] = 240, -- 2星时，分钟
    [3] = 480 -- 3星时，分钟
}

---@public 邮件类型，1：系统，2：战报；3：私信，4:联盟，5：客服
IDConst.MailType = {
    system = 1, -- 1：系统
    report = 2, -- 2：战报；
    private = 3, -- 3：私信、gm
    -- union = 4, -- 4:联盟
    -- gm = 5 -- 5：客服
}
---@public 邮件状态
IDConst.MailState = {
    unread = 0, -- 未读
    readNotRewared = 1, -- 已读未领取
    readRewared = 2  -- 已读已领取
}

return IDConst
