---public 舰队vs舰队

local table = table
local skynet = require("skynet")
require("public.include")
require("Errcode")
require("dbworldmap")
require("dbfleet")
---@type logic4fleet
local logic4fleet = require("logic4fleet")
---@type logic4city
local logic4city = require("logic4city")
---@type logic4player
local logic4player = require("logic.logic4player")
---@type utl4mail
local utl4mail = require("logic.utl4mail")
local ClassUnit = require("battle.ClassUnit")
---@type CLQuickSort
local Sort = require "CLQuickSort"

--//TODO:因为战斗不是立即结束的，在停服之前需要特殊处理下，比如不让进攻，还有舰队的死亡时间在启服后要刷新下
---@class ClassFleetBattle:ClassBase 战斗处理
local ClassFleetBattle = class("ClassFleetBattle")
local UnitPool = CLLPool.new(ClassUnit)
local ClassBullet = require "battle.ClassBullet"
local BulletPool = CLLPool.new(ClassBullet)
local USWorld = "USWorld"
ClassFleetBattle.FixedDeltaTime = 0.04

local gridSize = 10
local cellSize = 1

---@class _UnitAction
local _UnitAction = {
    attack = 1,
    move = 2,
    onHurt = 3,
    dead = 4
}

function ClassFleetBattle:ctor()
    self.type = IDConst.BattleType.attackFleet
end

function ClassFleetBattle:init(fidx1, fidx2)
    self.fidx1 = fidx1
    self.fidx2 = fidx2
    if not self.grid1 then
        self.grid1 = Grid.new()
        self.grid1:init(Vector3.zero, gridSize, gridSize, cellSize)
    end
    if not self.grid2 then
        self.grid2 = Grid.new()
        self.grid2:init(Vector3(gridSize, 0, 0), gridSize, gridSize, cellSize)
    end

    self.fleet1 = dbfleet.instanse(fidx1) -- 进攻方
    self.fleetVal1 = logic4fleet.getFleet(fidx1)
    self.fleet2 = dbfleet.instanse(fidx2) -- 防守方
    self.fleetVal2 = logic4fleet.getFleet(fidx2)
    self.startTime = 0

    -- 刷新一下城的队列数据，保证科技等是最新的
    local city = logic4city.insCityAndRefresh(self.fleet1:get_cidx())
    city:release()
    city = logic4city.insCityAndRefresh(self.fleet2:get_cidx())
    city:release()
    city = nil

    -- 目标地块
    self.targetMapCell = dbworldmap.instanse(self.fleet1:get_topos())
    self.player1 = dbplayer.instanse(self.fleetVal1.pidx)
    self.player2 = dbplayer.instanse(self.fleetVal2.pidx)

    self.isEndBattle = false
    self.leftUnits = {} -- 左边的战斗单元
    self.rightUnits = {} -- 左边的战斗单元
    self.leftUnitCount = 0
    self.rightUnitCount = 0

    ---@type NetProtoIsland.ST_battleFleetDetail 战斗详情
    self.battleData = {}
    self.battleData.actionQueue = {}
    self.battleData.attackPlayer = logic4player.wrapSimplePlayer(self.player1)
    self.battleData.defensePlayer = logic4player.wrapSimplePlayer(self.player2)
    self.battleData.attackFleet = {}
    self.battleData.attackFleet.idx = fidx1
    self.battleData.attackFleet.name = self.fleetVal1.name
    self.battleData.attackFleet.pidx = self.fleetVal1.pidx
    self.battleData.attackFleet.pname = self.fleetVal1.pname
    self.battleData.attackFleet.formations = {}
    self.battleData.defenseFleet = {}
    self.battleData.defenseFleet.idx = fidx2
    self.battleData.defenseFleet.name = self.fleetVal2.name
    self.battleData.defenseFleet.pidx = self.fleetVal2.pidx
    self.battleData.defenseFleet.pname = self.fleetVal2.pname
    self.battleData.defenseFleet.formations = {}

    ---@type NetProtoIsland.ST_battleresult 战斗结果
    self.result = {}
    self.result.star = 0
    self.result.honor = 0
    self.result.lootRes = {}
    self.result.lootRes.food = 0
    self.result.lootRes.gold = 0
    self.result.lootRes.oil = 0
    self.result.fidx = self.fidx1
    self.result.type = IDConst.BattleType.attackFleet
    self.result.attacker = self.battleData.attackPlayer
    self.result.defender = self.battleData.defensePlayer

    self.result.attackerUsedUnits = {}
    ---@type NetProtoIsland.ST_battleUnitInfor
    local battleUnit
    ---@param v NetProtoIsland.ST_unitInfor
    for i, v in ipairs(self.fleetVal1.units) do
        battleUnit = {}
        battleUnit.id = v.id
        battleUnit.lev = logic4city.getUnitLev(self.player1:get_cityidx(), v.id)
        battleUnit.deadNum = 0
        battleUnit.deployNum = v.num
        battleUnit.type = v.type
        self.result.attackerUsedUnits[v.id] = battleUnit
    end
    self.result.targetUsedUnits = {}
    for i, v in ipairs(self.fleetVal2.units) do
        battleUnit = {}
        battleUnit.id = v.id
        battleUnit.lev = logic4city.getUnitLev(self.player2:get_cityidx(), v.id)
        battleUnit.deadNum = 0
        battleUnit.deployNum = v.num
        battleUnit.type = v.type
        self.result.targetUsedUnits[v.id] = battleUnit
    end

    ------------------------------------
    self.canFixedUpdate = true
    skynet.fork(
        function()
            while self.canFixedUpdate do
                self:FixedUpdate()
                skynet.sleep(ClassFleetBattle.FixedDeltaTime * 100)
            end
        end
    )
end

function ClassFleetBattle:FixedUpdate()
    for idx, unit in pairs(self.leftUnits) do
        if not unit.isDead then
            unit:FixedUpdate()
        end
    end
    for idx, unit in pairs(self.rightUnits) do
        if not unit.isDead then
            unit:FixedUpdate()
        end
    end
end

function ClassFleetBattle:release()
    self.canFixedUpdate = false
    if self.fleet1 == nil then
        return
    end
    self.result = nil
    self.fleet1:release()
    self.fleet1 = nil
    self.fleet2:release()
    self.fleet2 = nil
    if self.player1 and (not self.player1:isEmpty()) then
        self.player1:release()
        self.player1 = nil
    end
    if self.player2 and (not self.player2:isEmpty()) then
        self.player2:release()
        self.player2 = nil
    end

    ---@param u ClassUnit
    for k, u in pairs(self.leftUnits) do
        u:clean()
        UnitPool:retObj(u)
    end
    self.leftUnits = {}

    ---@param u ClassUnit
    for k, u in pairs(self.rightUnits) do
        u:clean()
        UnitPool:retObj(u)
    end
    self.rightUnits = {}
    self.targetMapCell:release()

    self.battleData = nil
    self.result = nil
end

---public 排并布阵
---@param grid Grid
function ClassFleetBattle:doFormation(units, grid, isLeft)
    local gridCells = {}
    if isLeft then
        for x = 0, 7 do
            for y = 0, 9 do
                table.insert(gridCells, grid:GetCellIndex(x, y))
            end
        end
    else
        for x = 2, 9 do
            for y = 9, 0, -1 do
                table.insert(gridCells, grid:GetCellIndex(x, y))
            end
        end
    end

    local idx = isLeft and 1 or 10001
    local pos = 1
    ---@param unitInfor NetProtoIsland.ST_unitInfor
    for i, unitInfor in ipairs(units) do
        if unitInfor.type == IDConst.UnitType.role then
            if unitInfor.id ~= 4 and unitInfor.id ~= 11 then -- 登陆船、暴龙不能加入
                for j = 1, unitInfor.num do
                    --//TODO:  应该要考虑近战与远程的位置排列
                    local unit = UnitPool:borrow()
                    local gindex = gridCells[pos]
                    local position
                    local lev

                    if isLeft then
                        lev = logic4city.getUnitLev(self.player1:get_cityidx(), unitInfor.id)
                        position = self.grid1:GetCellCenterByIndex(gindex)
                    else
                        lev = logic4city.getUnitLev(self.player2:get_cityidx(), unitInfor.id)
                        position = self.grid2:GetCellCenterByIndex(gindex)
                    end
                    unit:init(self, idx, unitInfor.id, lev, isLeft, gindex, position)

                    ---@type NetProtoIsland.ST_unitFormation
                    local formation = {}
                    formation.id = unitInfor.id
                    formation.idx = idx
                    formation.lev = lev
                    formation.pos = gindex
                    formation.type = unitInfor.type

                    if isLeft then
                        self.leftUnits[idx] = unit
                        self.leftUnitCount = self.leftUnitCount + 1
                        table.insert(self.battleData.attackFleet.formations, formation)
                    else
                        self.rightUnits[idx] = unit
                        self.rightUnitCount = self.rightUnitCount + 1
                        table.insert(self.battleData.defenseFleet.formations, formation)
                    end
                    idx = idx + 1
                    pos = pos + 1
                end
            end
        end
    end
end

function ClassFleetBattle:prepare()
    -- 排阵
    self:doFormation(self.fleetVal1.units, self.grid1, true)
    self:doFormation(self.fleetVal2.units, self.grid2)
end

function ClassFleetBattle:start()
    self.fleet1:set_status(IDConst.FleetState.fightingFleet)
    self.fleet2:set_status(IDConst.FleetState.fightingFleet)
    skynet.send(USWorld, "lua", "pushFleetChg", self.fidx1)
    skynet.send(USWorld, "lua", "pushFleetChg", self.fidx2)

    self:prepare()
    self:checkEndBattle()
    if self.isEndBattle then
        return
    end

    self.startTime = dateEx.nowMS()

    ---@param unit ClassUnit
    for k, unit in pairs(self.leftUnits) do
        if not unit.isDead then
            unit:startAttack()
        end
    end
    ---@param unit ClassUnit
    for k, unit in pairs(self.rightUnits) do
        if not unit.isDead then
            unit:startAttack()
        end
    end
end

---@param unit ClassUnit
function ClassFleetBattle:onUnitMoveTo(unit)
    if self.isEndBattle then
        return
    end
    ---@type NetProtoIsland.ST_unitAction
    local action = {}
    action.idx = unit.idx
    action.action = _UnitAction.move
    action.targetVal = unit.target.idx
    action.timeMs = dateEx.nowMS() - self.startTime
    table.insert(self.battleData.actionQueue, action)
end

---@param unit ClassUnit
function ClassFleetBattle:onUnitAttack(unit)
    if self.isEndBattle then
        return
    end
    ---@type NetProtoIsland.ST_unitAction
    local action = {}
    action.idx = unit.idx
    action.action = _UnitAction.attack
    action.targetVal = unit.target.idx
    action.timeMs = dateEx.nowMS() - self.startTime
    table.insert(self.battleData.actionQueue, action)
end

function ClassFleetBattle:onUnitHurt(unit, damage)
    if self.isEndBattle then
        return
    end
    ---@type NetProtoIsland.ST_unitAction
    local action = {}
    action.idx = unit.idx
    action.action = _UnitAction.onHurt
    action.targetVal = damage
    action.timeMs = dateEx.nowMS() - self.startTime
    table.insert(self.battleData.actionQueue, action)
end

---@param unit ClassUnit
function ClassFleetBattle:onUnitDead(unit)
    if self.isEndBattle then
        return
    end

    ---@type NetProtoIsland.ST_unitAction
    local action = {}
    action.idx = unit.idx
    action.action = _UnitAction.dead
    action.timeMs = dateEx.nowMS() - self.startTime
    table.insert(self.battleData.actionQueue, action)

    local fidx
    local map
    if unit.isOffense then
        map = self.result.attackerUsedUnits
        fidx = self.fleet1:get_idx()
        -- self.leftUnits[unit.idx] = nil
        self.leftUnitCount = self.leftUnitCount - 1
    else
        map = self.result.targetUsedUnits
        fidx = self.fleet2:get_idx()
        -- self.rightUnits[unit.idx] = nil
        self.rightUnitCount = self.rightUnitCount - 1
    end
    -- 扣队舰队的单元
    if not logic4fleet.consumeUnit(fidx, unit.id, 1) then
        printe("战斗中扣除舰队的单元失败！！")
    end

    -- 更新战斗单元数据
    local unitId = unit.id
    ---@type NetProtoIsland.ST_battleUnitInfor
    local u = map[unitId]
    if u then
        u.deadNum = (u.deadNum or 0) + 1
        map[unitId] = u
    end

    -- 释放单元
    unit:clean()
    -- UnitPool:retObj(unit)
    self:checkEndBattle()
end

function ClassFleetBattle:borrowBullet()
    return BulletPool:borrow()
end

---@param bullet ClassBullet
function ClassFleetBattle:returnBullet(bullet)
    bullet:clean()
    return BulletPool:retObj(bullet)
end

---@param bullet ClassBullet
function ClassFleetBattle:onBulletHit(bullet)
    if self.isEndBattle then
        return
    end
    local attacker = bullet.attacker
    local target = bullet.target
    local pos = bullet.position
    -- 波及范围内单位
    local DamageAffectRang = attacker.attr.DamageAffectRang / 100
    if DamageAffectRang > 0 then
        -- 波及范围内单位
        local list = self:getTargetsInRange(attacker, pos, DamageAffectRang)
        if list and #list > 0 then
            ---@param unit ClassUnit
            for i, unit in ipairs(list) do
                local damage = attacker:getDamage(unit)
                unit:onHurt(damage, attacker)
            end
        else
            if target and (not target.isDead) then
                local dis = Vector3.Distance(pos, target.position)
                if dis <= 0.5 then
                    -- 半格范围内都算击中目标
                    local damage = attacker:getDamage(target)
                    target:onHurt(damage, attacker)
                end
            end
        end
    else
        if target and (not target.isDead) then
            local dis = Vector3.Distance(pos, target.position)
            if dis <= 0.6 then
                -- 半格范围内都算击中目标
                local damage = attacker:getDamage(target)
                target:onHurt(damage, attacker)
            end
        end
    end
end

---@param attacker ClassUnit
function ClassFleetBattle:searchTarget(attacker)
    local targetList = nil
    if attacker.isOffense then
        targetList = self.rightUnits
    else
        targetList = self.leftUnits
    end

    local minDis, dis = -1, 0
    local target
    ---@param unit ClassUnit
    for k, unit in pairs(targetList) do
        if not unit.isDead then
            dis = Vector3.Distance(unit.position, attacker.position)
            if minDis < 0 or minDis > dis then
                minDis = dis
                target = unit
            end
        end
    end
    return target
end

---public 取得范围内的目标
function ClassFleetBattle:getTargetsInRange(attacker, pos, rang)
    local targetList = nil
    if attacker.isOffense then
        targetList = self.rightUnits
    else
        targetList = self.leftUnits
    end

    local dis = 0
    local targets = {}
    ---@param unit ClassUnit
    for k, unit in pairs(targetList) do
        if not unit.isDead then
            dis = Vector3.Distance(unit.position, pos)
            if dis <= rang then
                table.insert(targets, unit)
            end
        end
    end
    return targets
end

function ClassFleetBattle:checkEndBattle()
    if self.leftUnitCount <= 0 then
        self:endBattle(false)
    elseif self.rightUnitCount <= 0 then
        self:endBattle(true)
    end
end

---public 结束战斗的处理
function ClassFleetBattle:endBattle(isWin)
    if self.isEndBattle then
        return
    end
    self.isEndBattle = true
    self.canFixedUpdate = false

    ------------------------------------
    -- 设置战斗结果（用星来处理）
    self.result.star = isWin and 1 or 0
    ------------------------------------
    -- 改舰队状态、舰队返回或占领港口
    if isWin then
        if self.fleet1:get_task() == IDConst.FleetTask.attack then
            self.fleet1:set_status(IDConst.FleetState.none)
            skynet.call(USWorld, "lua", "doFleetBack", self.fleet1:get_idx())
        elseif self.fleet1:get_task() == IDConst.FleetTask.voyage then
            if (not self.targetMapCell:isEmpty()) and self.targetMapCell:get_type() == IDConst.WorldmapCellType.port then
                self.fleet1:set_status(IDConst.FleetState.docked)
                self.targetMapCell:set_fidx(self.fleet1:get_idx())
                self.targetMapCell:set_cidx(self.fleet1:get_cidx())
                skynet.send(USWorld, "lua", "pushMapCellChg", self.targetMapCell:get_idx(), false)
            else
                self.fleet1:set_status(IDConst.FleetState.none)
                skynet.call(USWorld, "lua", "doFleetBack", self.fleet1:get_idx())
            end
        else
            -- 其它情况不可能会发生战斗
            self.fleet1:set_status(IDConst.FleetState.none)
            skynet.call(USWorld, "lua", "doFleetBack", self.fleet1:get_idx())
        end

        -- 防守方都是直接返航
        if (not self.targetMapCell:isEmpty()) and self.targetMapCell:get_type() == IDConst.WorldmapCellType.port then
            -- 是港口，那返回基地
            self.fleet2:set_status(IDConst.FleetState.docked)
            skynet.call(USWorld, "lua", "doFleetBack", self.fleet2:get_idx())
        else
            -- 其它情况说明是在海面上，注意要把状态改成stay，为了在处理返回时，释放占用地块
            self.fleet2:set_status(IDConst.FleetState.stay)
            skynet.call(USWorld, "lua", "doFleetBack", self.fleet2:get_idx())
        end
    else
        self.fleet1:set_status(IDConst.FleetState.none)
        skynet.call(USWorld, "lua", "doFleetBack", self.fleet1:get_idx())

        if self.fleet2:get_task() == IDConst.FleetTask.voyage then
            if (not self.targetMapCell:isEmpty()) and 
                self.targetMapCell:get_type() == IDConst.WorldmapCellType.port then
                self.fleet2:set_status(IDConst.FleetState.docked)
            else
                self.fleet2:set_status(IDConst.FleetState.stay)
            end
        else
            -- 其它情况不可能会发生战斗
            if (not self.targetMapCell:isEmpty()) and 
                self.targetMapCell:get_type() == IDConst.WorldmapCellType.port then
                self.fleet2:set_status(IDConst.FleetState.docked)
            else
                self.fleet2:set_status(IDConst.FleetState.stay)
            end
        end
    end
    skynet.send(USWorld, "lua", "pushFleetChg", self.fidx1)
    skynet.send(USWorld, "lua", "pushFleetChg", self.fidx2)

    -- 保存战报
    local reportData = {
        -- attacker = self.player1:value2copy(),
        -- target = self.player2:value2copy(),
        -- fleet1 = self.fleetVal1,
        -- fleet2 = self.fleetVal2,
        battleData = self.battleData --[[ 战斗的详细数据
            1.初始舰队阵形、玩家信息
            2.攻击、移动、扣血、死亡的时间节点
            3.实时大图只做简单表现（攻击数据、扣血数据都不需要通知，只通知状态的变化）
        ]]
    }
    local reportIdx = DBUtl.nextVal(DBUtl.Keys.report)
    local report = dbreport.new()
    report:init(
        {
            [dbreport.keys.idx] = reportIdx,
            [dbreport.keys.type] = IDConst.BattleType.attackFleet,
            [dbreport.keys.crttime] = dateEx.nowMS(),
            [dbreport.keys.result] = json.encode(self.result),
            [dbreport.keys.content] = json.encode(reportData)
        },
        true
    )
    report:release()
    ------------------------------------
    -- 发送战报
    utl4mail.sendBattleMail(
        IDConst.BattleType.attackFleet,
        self.player1:get_name(),
        self.player2:get_name(),
        reportIdx,
        {
            self.player1:get_idx(),
            self.player2:get_idx()
        }
    )

    ------------------------------------
    skynet.send(USWorld, "lua", "onFinishBattle", self.fidx1)
end

return ClassFleetBattle
