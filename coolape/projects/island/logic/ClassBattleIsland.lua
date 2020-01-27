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
    self.targetMapCell = dbworldmap.instanse(self.fleet:get_curpos())
    self.targetCity = dbcity.instanse(self.targetMapCell:get_cidx())
    self.targetPlayer = dbplayer.instanse(self.targetCity:get_pidx())
    self.attackCity = dbcity.instanse(self.fleet:get_cidx())
    self.attackPlayer = dbplayer.instanse(self.attackCity:get_pidx())

    self:refreshDefenseInfor()
    ---@type NetProtoIsland.ST_battleresult
    self.result = {}
    self.result.iswin = false
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
    self.targetMapCell:release()
    self.targetCity:release()
    self.targetPlayer:release()
    self.attackCity:release()
    self.attackPlayer:release()
end

---@public 准备战斗（就是舰队航行到目标地的过程）
function ClassBattleIsland:prepare()
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
    printw("=============================================")

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
        -- //TODO:进攻方不在线，则把舰队状态更改下，直接判断进攻方法失败，且结束战斗
        self:stop()
        return
    end

    local pkg =
        pkg4Client(
        {cmd = "sendStartAttackIsland"},
        {code = Errcode.ok},
        self.targetPlayer:value2copy(),
        self.targetCityVal,
        self.targetShips,
        logic4fleet.getFleet(self.fidx)
    )
    skynet.call(attackAgent, "lua", "sendPackage", pkg)

    if targetAgent then
        skynet.call(targetAgent, "lua", "sendPackage", pkg)
    end
end

function ClassBattleIsland:onDeployUnity(idx)
end

function ClassBattleIsland:stop()
    skynet.call(LDSWorld, "lua", "doFleetBack", self.fidx)
    skynet.call(LDSWorld, "lua", "onFinishBattle", self.fidx)
end

return ClassBattleIsland
