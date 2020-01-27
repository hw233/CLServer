---@class logic4battle
local logic4battle = {}
local skynet = require("skynet")
require "skynet.manager" -- import skynet.register
require("public.include")
require("Errcode")
require("dbworldmap")
require("dbcity")
require("dbtile")
require("dbbuilding")
require("dbplayer")
require("dbunit")
require("dbfleet")
local IDConstVals = require("IDConstVals")

---@type logic4fleet
local logic4fleet = require("logic.logic4fleet")
---@type NetProtoIsland
local NetProtoIsland = skynet.getenv("NetProtoName")
---@type ClassBattleIsland
local ClassBattleIsland = require("logic.ClassBattleIsland")
---@type CLLPool
local poolBattleIsland = CLLPool.new(ClassBattleIsland)
local battles = {}

logic4battle.prepareAttackIsland = function(fidx)
    printw("logic4battle.prepareAttackIsland=====================")
    ---@type ClassBattleIsland
    local b = poolBattleIsland:borrow()
    b:init(fidx)
    battles[fidx] = b
    b:prepare()
end

---@public 开始进入舰队vs攻岛
---@param fidx number 舰队idx
logic4battle.startAttackIsland = function(fidx)
    printw("logic4battle.startAttackIsland=====================")
    ---@type ClassBattleIsland
    local b = battles[fidx]
    if b then
        b:start()
    end
end

---@public 开始进入舰队vs舰队
---@param fidx number 舰队idx
logic4battle.startAttackFleet = function(fidx)
    -- //TODO:
end

---@public 当战斗结束
logic4battle.onFinishBattle = function(fidx)
    local b = battles[fidx]
    if b then
        b:release()
        poolBattleIsland:retObj(b)
        battles[fidx] = nil
    end
end

return logic4battle
