---@class _LocalBattleUnitInfor
---@field id number
---@field type number
---@field fidx number 所属舰队idx
---@field bidx number 所属建筑idx
---@field deployNum number 投放数量
---@field deadNum number 死亡数量

---@class _LocalBattleDeployInfor
---@field unitInfor NetProtoIsland.ST_unitInfor
---@field frames number 投放时的帧数（相较于第一次投入时的帧数增量）
---@field pos NetProtoIsland.ST_vector3 投放坐标（是int，真实值x1000）
---@field fakeRandom number 随机因子
---@field fakeRandom2 number 随机因子
---@field fakeRandom3 number 随机因子

local skynet = require("skynet")
require("public.include")
require("Errcode")
require("dbworldmap")
require("dbcity")
require("dbbuilding")
require("dbplayer")
require("dbunit")
require("dbfleet")
require("dbreport")
require("dbmail")
local IDConst = require("IDConst")
---@type logic4fleet
local logic4fleet = require("logic.logic4fleet")
---@type logic4city
local logic4city = require("logic.logic4city")
---@type NetProtoIsland
local NetProtoIsland = skynet.getenv("NetProtoName")

---@class ClassBattleIsland:ClassBase 战斗处理
local ClassBattleIsland = class("ClassBattleIsland")
local USWorld = "USWorld"
local FixedDeltaTime = 0.02

function ClassBattleIsland:init(fidx)
    self.fidx = fidx -- 舰队id
    self.fleet = dbfleet.instanse(fidx)
    self.fleetVal = logic4fleet.getFleet(fidx)
    self.targetMapCell = dbworldmap.instanse(self.fleet:get_topos())
    self.targetCity = logic4city.insCityAndRefresh(self.targetMapCell:get_cidx())
    self.targetCityVal = self.targetCity:value2copy()
    self.targetPlayer = dbplayer.instanse(self.targetCity:get_pidx())
    self.targetPlayerVal = self.targetPlayer:value2copy()
    self.attackCity = logic4city.insCityAndRefresh(self.fleet:get_cidx())
    self.attackCityVal = self.attackCity:value2copy()
    self.attackPlayer = dbplayer.instanse(self.attackCity:get_pidx())
    self.attackPlayerVal = self.attackPlayer:value2copy()
    ---@type Coroutine
    self.timeLimitCor = nil -- 限时器
    self:refreshDefenseInfor()
    ---@type NetProtoIsland.ST_battleresult
    self.result = {}
    self.result.star = 0
    self.result.exp = 0
    self.result.lootRes = {}
    self.result.lootRes.food = 0
    self.result.lootRes.gold = 0
    self.result.lootRes.oil = 0
    self.result.attacker = self:wrapSimplePlayer(self.attackPlayer)
    self.result.defender = self:wrapSimplePlayer(self.targetPlayer)

    --===============================
    self.deployUnitQueue = {} -- 投放战斗单元时间 list, val=_LocalBattleDeployInfor
    self.offUnitInfor = {} -- 进攻方的战斗单元信息 key = id， val=_LocalBattleUnitInfor
    self.defUnitInfor = {} -- 防守方的战斗单元信息 key = id， val=_LocalBattleUnitInfor
    self.deadBuildings = {}
    self.firstDeployTime = 0 -- 第一次投放战斗单元的时间
end

---@param player dbplayer
function ClassBattleIsland:wrapSimplePlayer(player)
    ---@type NetProtoIsland.ST_playerSimple
    local simplePlayer = {}
    simplePlayer.idx = player:get_idx()
    simplePlayer.name = player:get_name()
    simplePlayer.unionidx = player:get_unionidx()
    simplePlayer.exp = player:get_exp()
    simplePlayer.cityidx = player:get_cityidx()
    simplePlayer.lev = player:get_lev()
    simplePlayer.status = player:get_status()
end

---@public 刷新防守主城的数据
function ClassBattleIsland:refreshDefenseInfor()
    ---@type NetProtoIsland.ST_city
    local targetCityVal = self.targetCity:value2copy()
    targetCityVal.tiles = dbtile.getListBycidx(self.targetCity:get_idx())
    targetCityVal.buildings = dbbuilding.getListBycidx(self.targetCity:get_idx())
    ---@type NetProtoIsland.ST_city
    self.targetCityVal = targetCityVal

    ---@type NetProtoIsland.ST_dockyardShips
    local targetShips = {}
    for idx, building in pairs(targetCityVal.buildings) do
        if building[dbbuilding.keys.attrid] == IDConst.BuildingID.alliance then
            targetShips.buildingIdx = building[dbbuilding.keys.idx]
            targetShips.ships = dbunit.getListBybidx(building[dbbuilding.keys.idx])
            break
        end
    end
    ---@type NetProtoIsland.ST_dockyardShips
    self.targetUnits = targetShips
end

function ClassBattleIsland:release()
    if self.fleet then
        self.fleet:release()
        self.fleet = nil
    end

    if self.timeLimitCor then
        self.timeLimitCor.cancel()
        self.timeLimitCor = nil
    end

    self.targetMapCell:release()
    self.targetMapCell = nil
    self.targetCity:release()
    self.targetCity = nil
    self.targetPlayer:release()
    self.targetPlayer = nil
    self.attackCity:release()
    self.attackCity = nil
    self.attackPlayer:release()
    self.attackPlayer = nil
    self.result = nil
end

---@public 准备战斗（就是舰队航行到目标地的过程）
function ClassBattleIsland:prepare()
    -- 更新玩家的状态
    self.targetPlayer:set_beingattacked(true)
    self.attackPlayer:set_attacking(true)
    -- 通知准备进入攻岛战
    local targetAgent = getPlayerAgent(self.targetPlayer:get_idx())
    local attackAgent = getPlayerAgent(self.attackPlayer:get_idx())

    local pkg =
        pkg4Client(
        {cmd = "sendPrepareAttackIsland"},
        {code = Errcode.ok},
        self.targetPlayer:value2copy(),
        self.targetCityVal,
        self.attackPlayer:value2copy(),
        self.attackCity:value2copy(),
        logic4fleet.getFleet(self.fidx)
    )

    skynet.call(attackAgent, "lua", "sendPackage", pkg)
    if targetAgent then
        skynet.call(targetAgent, "lua", "sendPackage", pkg)
    end
end

---@public 开始
function ClassBattleIsland:start()
    local targetAgent = getPlayerAgent(self.targetPlayer:get_idx())
    local attackAgent = getPlayerAgent(self.attackPlayer:get_idx())

    if attackAgent == nil then
        -- 进攻方不在线，则把舰队状态更改下，直接判断进攻方法失败，且结束战斗
        self:stop()
        return
    end

    local cfg = cfgUtl.getConstCfg()
    local limitSec = cfg.LimitSecBattle
    local pkg =
        pkg4Client(
        {cmd = "sendStartAttackIsland"},
        {code = Errcode.ok},
        self.targetPlayer:value2copy(),
        self.targetCityVal,
        self.targetUnits,
        self.attackPlayer:value2copy(),
        logic4fleet.getFleet(self.fidx),
        dateEx.nowMS() + limitSec * 1000
    )

    skynet.call(attackAgent, "lua", "sendPackage", pkg)
    if targetAgent then
        skynet.call(targetAgent, "lua", "sendPackage", pkg)
    end
    -- 控制战斗的时限
    self.timeLimitCor = timerEx.new(limitSec, ClassBattleIsland.onTimeOut, self)
end

---@param battle ClassBattleIsland
function ClassBattleIsland.onTimeOut(battle)
    -- 超时，结束战斗
    battle.timeLimitCor = nil
    battle:stop()
end

---@public 当投放战斗单元时
---@param data NetProtoIsland.RC_onBattleDeployUnit
function ClassBattleIsland:onDeployUnit(data)
    -- 判断能否投放
    local fleetVal = logic4fleet.getFleet(self.fleet:get_idx())
    for k, v in pairs(fleetVal.units) do
        if v[dbunit.keys.id] == data.unitInfor.id then
            if v[dbunit.keys.num] < data.unitInfor.num then
                return Errcode.unitNotEnough
            end
            break
        end
    end
    if self.firstDeployTime <= 0 then
        self.firstDeployTime = dateEx.now()
    end
    --=======================================
    -- 记录投放兵的信息
    ---@type _LocalBattleDeployInfor
    local deployInfor = {}
    deployInfor.frames = data.frames
    deployInfor.pos = data.vector3
    deployInfor.fakeRandom = data.fakeRandom
    deployInfor.fakeRandom2 = data.fakeRandom2
    deployInfor.fakeRandom3 = data.fakeRandom3
    deployInfor.unitInfor = data.unitInfor
    table.insert(self.deployUnitQueue, deployInfor)
    --=======================================
    -- 记录战斗单元的总信息
    local unitId = data.unitInfor.id
    ---@type _LocalBattleUnitInfor
    local u
    local map
    if data.isOffense then
        map = self.offUnitInfor
    else
        map = self.defUnitInfor
    end
    u = map[unitId] or {}
    u.id = unitId
    u.type = data.unitInfor.type
    u.fidx = data.unitInfor.fidx
    u.bidx = data.unitInfor.bidx
    u.deployNum = (u.deployNum or 0) + data.unitInfor.num
    map[unitId] = u
    --=======================================
    -- 通知防守方，以便可以同步查看
    local targetAgent = getPlayerAgent(self.targetPlayer:get_idx())
    if targetAgent then
        local pkg = pkg4Client({cmd = "sendBattleDeployUnit"}, {code = Errcode.ok}, deployInfor)
        skynet.call(targetAgent, "lua", "sendPackage", pkg)
    end
    return Errcode.ok
end

---@public 当战斗单元死亡时
---@param unitInfor NetProtoIsland.ST_unitInfor
function ClassBattleIsland:onUnitDie(unitInfor)
    if #self.deployUnitQueue == 0 then
        printe("没取得投放兵的数据，却获得了战斗单元死亡数据")
        return
    end
    local map
    if unitInfor.fidx > 0 then
        -- 说明是进攻方
        map = self.offUnitInfor
        if logic4fleet.consumeUnit(unitInfor.fidx, unitInfor.id, unitInfor.num) then
            return Errcode.ok
        else
            return Errcode.unitNotEnough
        end
    else
        -- 防守方， 说明是扣除建筑上的战斗单元
        map = self.defUnitInfor
        local units = dbunit.getListBybidx(unitInfor.bidx)
        for i, v in ipairs(units) do
            if v[dbunit.keys.id] == unitInfor.id then
                if v[dbunit.keys.num] >= unitInfor.num then
                    local u = dbunit.instanse(v[dbunit.keys.idx])
                    u:set_num(u:get_num() - unitInfor.num)
                    u:release()
                    return Errcode.ok
                else
                    return Errcode.unitNotEnough
                end
            end
        end
        return Errcode.unitNotEnough
    end
    -- 更新战斗单元数据
    local unitId = unitInfor.id
    ---@type _LocalBattleUnitInfor
    local u = map[unitId]
    if u then
        u.deadNum = (u.deadNum or 0) + unitInfor.num
        map[unitId] = u
    end
end

---@public 当建筑死亡时
function ClassBattleIsland:onBuildingDie(bidx)
    if #self.deployUnitQueue == 0 then
        printe("没取得投放兵的数据，却获得了建筑死亡数据")
        return
    end
    ---------------------------------------------------
    -- 设置建筑的恢复时间(注意：建筑正在升级或者正在建造舰船都会被取消)
    local b = dbbuilding.instanse(bidx)
    local v = {}
    local attr = cfgUtl.getBuildingByID(b:get_attrid())
    if attr.RegenTime > 0 and b:get_state() ~= IDConst.BuildingState.upgrade then
        -- 正在升级的建筑不能设置成修复状态
        v[dbbuilding.keys.starttime] = dateEx.nowMS()
        v[dbbuilding.keys.endtime] = dateEx.nowMS() + attr.RegenTime * 60 * 1000
        v[dbbuilding.keys.state] = IDConst.BuildingState.renew
        b:refreshData(v)
    end
    ---------------------------------------------------
    -- 获得经验
    self.result.exp = self.result.exp + attr.DestructionXP
    -- 战斗结果星级判断
    if b:get_attrid() == IDConst.BuildingID.headquarters then
        -- 主基地被爆了，至少得一星
        self.result.star = 1
    end
    table.insert(self.deadBuildings, bidx)
    ---------------------------------------------------
    b:release()
    return Errcode.ok
end

---@public 当掠夺到资源时
---@param map NetProtoIsland.RC_onBattleLootRes
function ClassBattleIsland:onLootRes(map)
    if #self.deployUnitQueue == 0 then
        printe("没取得投放兵的数据，却获得了掠夺到资源数据")
        return
    end
    local b = dbbuilding.instanse(map.buildingIdx)
    local retCode = Errcode.ok
    if b:isEmpty() then
        retCode = Errcode.buildingIsNil
        return retCode
    end
    local resVal = map.val
    local attr = cfgUtl.getBuildingByID(b:get_attrid())
    if
        attr.ID == IDConst.BuildingID.goldStorage or attr.ID == IDConst.BuildingID.foodStorage or
            attr.ID == IDConst.BuildingID.oildStorage
     then
        -- 仓库，直接扣除资源
        if b:get_val() >= map.val then
            -- 扣除建筑的资源
            b:set_val(b:get_val() - map.val)
        else
            retCode = Errcode.resNotEnough
        end
    elseif
        attr.ID == IDConst.BuildingID.foodFactory or attr.ID == IDConst.BuildingID.goldMine or
            attr.ID == IDConst.BuildingID.oilWell
     then
        if b:get_state() == IDConst.BuildingState.normal or b:get_state() == IDConst.BuildingState.working then
            b:set_starttime(b:get_starttime() + map.val * 60 * 1000)

            local maxLev = attr.MaxLev
            local persent = b:get_lev() / maxLev
            -- 每分钟产量
            local yieldsPerMinutes = cfgUtl.getGrowingVal(attr.ComVal1Min, attr.ComVal1Max, attr.ComVal1Curve, persent)
            resVal = map.val * yieldsPerMinutes
        else
            printe("retCode==", retCode, b:get_idx())
            retCode = Errcode.buildingIsBusy
        end
    elseif attr.ID == IDConst.BuildingID.headquarters then
        -- 主基地
        if map.resType == IDConst.ResType.food then
            if b:get_val() >= map.val then
                -- 扣除建筑的资源
                b:set_val(b:get_val() - map.val)
            else
                retCode = Errcode.resNotEnough
            end
        elseif map.resType == IDConst.ResType.gold then
            if b:get_val2() >= map.val then
                -- 扣除建筑的资源
                b:set_val2(b:get_val2() - map.val)
            else
                retCode = Errcode.resNotEnough
            end
        elseif map.resType == IDConst.ResType.oil then
            if b:get_val3() >= map.val then
                -- 扣除建筑的资源
                b:set_val3(b:get_val3() - map.val)
            else
                retCode = Errcode.resNotEnough
            end
        end
    end
    -- 记录掠夺到的资源
    if retCode == Errcode.ok then
        if map.resType == IDConst.ResType.food then
            self.result.lootRes.food = (self.result.lootRes.food or 0) + resVal
        elseif map.resType == IDConst.ResType.gold then
            self.result.lootRes.gold = (self.result.lootRes.gold or 0) + resVal
        elseif map.resType == IDConst.ResType.oil then
            self.result.lootRes.oil = (self.result.lootRes.oil or 0) + resVal
        end
    end
    b:release()
    return retCode
end

---@public 结束战斗
function ClassBattleIsland:stop()
    if self.timeLimitCor then
        self.timeLimitCor.cancel()
        self.timeLimitCor = nil
    end
    ------------------------------------------------------------------
    -- 更新玩家的状态
    self.targetPlayer:set_beingattacked(false)
    self.attackPlayer:set_attacking(false)
    if self.result.star > 0 then
        -- 根据战斗结果给被攻击玩家岛屿设置保护时间
        local protecttime = dateEx.nowMS() + IDConst.ProtectLev[self.result.star] * 60 * 1000
        local city = {}
        city[dbcity.keys.protectEndTime] = protecttime
        city[dbcity.keys.status] = IDConst.CityState.protect
        self.targetCity:refreshData(city) -- 这样处理，以免多次推送
    end
    ------------------------------------------------------------------
    -- 计算战斗结果
    self.result.attackerUsedUnits = self.offUnitInfor
    self.result.targetUsedUnits = self.defUnitInfor
    self.result.fidx = self.fleet:get_idx()
    local buildings = {}
    for i, v in ipairs(self.targetCityVal.buildings) do
        local attrid = v[dbbuilding.keys.attrid]
        local attr = cfgUtl.getBuildingByID(attrid)
        if
            not (attr.GID == IDConst.BuildingGID.trap or attr.GID == IDConst.BuildingGID.tree or
                attr.GID == IDConst.BuildingGID.decorate or
                v[dbbuilding.keys.state] == IDConst.BuildingState.renew)
         then
            table.insert(buildings, v)
        end
    end
    local persent = #self.deadBuildings / #buildings
    if persent > 0.9 then
        self.result.star = self.result.star + 2
    elseif persent > 0.5 then
        self.result.star = self.result.star + 1
    end
    print(CLUtl.dump(self.result))
    ------------------------------------------------------------------
    if #(self.deployUnitQueue) == 0 then
        -- //TODO:说明没有真正开战(这种情况要对进攻方有所惩罚)
    elseif self.result.star == 0 then
    -- //TODO:零星，对进攻方有所惩罚
    end
    ------------------------------------------------------------------
    -- 计算进攻方掠夺到的资源
    logic4city.consumeRes(
        self.attackCity:get_idx(),
        -self.result.lootRes.food,
        -self.result.lootRes.gold,
        -self.result.lootRes.oil
    )
    ------------------------------------------------------------------
    -- 推送客户端战斗结束
    local pkg = pkg4Client({cmd = "sendEndAttackIsland"}, {code = Errcode.ok}, self.result)
    local targetAgent = getPlayerAgent(self.targetPlayer:get_idx())
    local attackAgent = getPlayerAgent(self.attackPlayer:get_idx())
    if attackAgent then
        skynet.call(attackAgent, "lua", "sendPackage", pkg)
    end
    if targetAgent then
        skynet.call(targetAgent, "lua", "sendPackage", pkg)
    end
    ------------------------------------------------------------------
    -- if logic4fleet.isEmpty(self.fidx) then
    -- -- 舰队已经为空，说明舰队战斗单元已经全部消耗（本打算清除舰队，但是因为比如萌宠之类的还要带回主城）
    -- end
    ------------------------------------------------------------------
    -- 记录战报 //TODO:可能需要zip下，压缩下应该会小很多
    --[[
        玩家双方信息，主城信息（建筑及战斗单元），进攻方投放信息，战斗结算
    ]]
    local reportIdx = 0
    if #(self.deployUnitQueue) > 0 then
        local diffSec = dateEx.now() - self.firstDeployTime
        local endFrames = numEx.getIntPart(diffSec/FixedDeltaTime)
        -- 未投放过任务一个兵
        local reportData = {
            attacker = self.attackPlayerVal,
            attackerCity = self.attackCityVal,
            target = self.targetPlayerVal,
            targetCity = self.targetCityVal,
            targetUnits = self.targetUnits,
            fleet = self.fleetVal,
            deployQueue = self.deployUnitQueue,
            endFrames = endFrames
        }
        reportIdx = DBUtl.nextVal(DBUtl.Keys.report)
        local report = dbreport.new()
        report:init(
            {
                [dbreport.keys.idx] = reportIdx,
                [dbreport.keys.type] = IDConst.BattleType.attackIsland,
                [dbreport.keys.crttime] = dateEx.nowMS(),
                [dbreport.keys.result] = json.encode(self.result),
                [dbreport.keys.content] = json.encode(reportData)
            },
            true
        )
        report:release()
    end
    ------------------------------------------------------------------
    -- 发送战报
    local mailServer = skynet.newservice("cmd4mail")

    local params = {attacker = self.attackPlayer:get_name(), target = self.targetPlayer:get_name()}
    local mailContent = {
        [dbmail.keys.parent] = 0, -- 父idx(其实就是邮件的idx，回复的邮件指向的主邮件的idx)
        [dbmail.keys.type] = IDConst.MailType.report, -- 类型，1：系统，2：战报；3：私信，4:联盟，5：客服
        [dbmail.keys.fromPidx] = IDConst.sysPidx, -- 发件人
        [dbmail.keys.toPidx] = 0, -- 收件人
        [dbmail.keys.titleKey] = "BattleReportTitle", -- 标题key
        [dbmail.keys.titleParams] = json.encode(params), -- 标题的参数(json的map)
        [dbmail.keys.contentKey] = "", -- 内容key
        [dbmail.keys.contentParams] = "", -- 内容参数(json的map)
        [dbmail.keys.rewardIdx] = 0, -- 奖励idx
        [dbmail.keys.comIdx] = reportIdx, -- 通用ID,可以关联到比如战报id等
        [dbmail.keys.backup] = "" -- 备用
    }
    local toPlayers = {self.attackPlayer:get_idx(), self.targetPlayer:get_idx()}
    skynet.call(mailServer, "lua", "doSendMail", mailContent, toPlayers)
    skynet.kill(mailServer)
    ------------------------------------------------------------------
    -- 重置舰队死亡时间
    self.fleet:set_deadtime(dateEx.nowMS() + cfgUtl.getConstCfg().FleetTimePerOnce * 60 * 1000)
    ------------------------------------------------------------------
    -- 舰队返回
    skynet.call(USWorld, "lua", "doFleetBack", self.fidx)
    ------------------------------------------------------------------
    -- 结束战场
    skynet.call(USWorld, "lua", "onFinishBattle", self.fidx)
end

return ClassBattleIsland
