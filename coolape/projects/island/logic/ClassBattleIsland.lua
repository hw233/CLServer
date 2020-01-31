local skynet = require("skynet")
require("public.include")
require("Errcode")
require("dbworldmap")
require("dbcity")
require("dbbuilding")
require("dbplayer")
require("dbunit")
require("dbfleet")
local IDConstVals = require("IDConstVals")
---@type logic4fleet
local logic4fleet = require("logic.logic4fleet")
---@type NetProtoIsland
local NetProtoIsland = skynet.getenv("NetProtoName")

---@class ClassBattleIsland:ClassBase 战斗处理
local ClassBattleIsland = class("ClassBattleIsland")
local LDSWorld = "LDSWorld"

function ClassBattleIsland:init(fidx)
    self.fidx = fidx -- 舰队id
    self.fleet = dbfleet.instanse(fidx)
    self.targetMapCell = dbworldmap.instanse(self.fleet:get_topos())
    self.targetCity = dbcity.instanse(self.targetMapCell:get_cidx())
    self.targetPlayer = dbplayer.instanse(self.targetCity:get_pidx())
    self.attackCity = dbcity.instanse(self.fleet:get_cidx())
    self.attackPlayer = dbplayer.instanse(self.attackCity:get_pidx())
    ---@type Coroutine
    self.timeLimitCor = nil -- 限时器
    self:refreshDefenseInfor()
    ---@type NetProtoIsland.ST_battleresult
    self.result = {}
    self.result.iswin = false
    self.result.star = 0
    self.result.exp = 0
    self.result.lootRes = {}
end

---@public 刷新防守主的数据
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
        if building[dbbuilding.keys.attrid] == IDConstVals.AllianceID then
            targetShips.buildingIdx = building[dbbuilding.keys.idx]
            targetShips.ships = dbunit.getListBybidx(building[dbbuilding.keys.idx])
            break
        end
    end
    ---@type NetProtoIsland.ST_dockyardShips
    self.targetShips = targetShips
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
        self.targetShips,
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

---@public 控制战斗的时限
function ClassBattleIsland:setBattleTimeLimit()
end

---@param battle ClassBattleIsland
function ClassBattleIsland.onTimeOut(battle)
    -- 超时，结束战斗
    battle.timeLimitCor = nil
    battle:stop()
end

---@public 当投放战斗单元时
function ClassBattleIsland:onDeployUnit(idx, num)
end
---@public 当战斗单元死亡时
function ClassBattleIsland:onUnitDie()
end
---@public 当建筑死亡时
function ClassBattleIsland:onBuildingDie()
end
---@public 当掠夺到资源时
function ClassBattleIsland:onLootRes()
end

---@public 结束战斗
function ClassBattleIsland:stop()
    if self.timeLimitCor then
        self.timeLimitCor.cancel()
        self.timeLimitCor = nil
    end
    -- 更新玩家的状态
    self.targetPlayer:set_beingattacked(false)
    self.attackPlayer:set_attacking(false)
    if self.result.star > 0 then
        -- 根据战斗结果给被攻击玩家岛屿设置保护时间
        local protecttime = dateEx.nowMS() + IDConstVals.ProtectLev[self.result.star] * 60 * 1000
        local city = {}
        city[dbcity.keys.protectEndTime] = protecttime
        city[dbcity.keys.status] = IDConstVals.CityState.protect
        self.targetCity:refreshData(city) -- 这样处理，以免多次推送
    end

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
    if logic4fleet.isEmpty(self.fidx) then
    -- 舰队已经为空，说明舰队战斗单元已经全部消耗（本打算清除舰队，但是因为比如萌宠之类的还要带回主城）
    end
    -- 重设置死亡时间
    self.fleet:set_deadtime(dateEx.nowMS() + cfgUtl.getConstCfg().FleetTimePerOnce * 60 * 1000)
    skynet.call(LDSWorld, "lua", "doFleetBack", self.fidx)
    skynet.call(LDSWorld, "lua", "onFinishBattle", self.fidx)
end

return ClassBattleIsland
