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
    ---@type ClassBattleIsland
    local b = poolBattleIsland:borrow()
    b:init(fidx)
    battles[fidx] = b
    b:prepare()
end

---@public 开始进入舰队vs攻岛
---@param fidx number 舰队idx
logic4battle.startAttackIsland = function(fidx)
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

---@public 结束攻岛战斗
logic4battle.stopBattle4Island = function(fidx)
    ---@type ClassBattleIsland
    local b = battles[fidx]
    if b == nil then
        -- 因为有可以重启服务器时，要处理之前在战斗状态的舰队
        b = poolBattleIsland:borrow()
        b:init(fidx)
        battles[fidx] = b
    end

    if b then
        b:stop()
    end
end

---@public 当战斗结束
logic4battle.onFinishBattle = function(fidx)
    ---@type ClassBattleIsland
    local b = battles[fidx]
    if b then
        b:release()
        poolBattleIsland:retObj(b)
        battles[fidx] = nil
    end
end

---@public 有玩家离线了
logic4battle.onPlayerOffline = function(pidx)
    local player = dbplayer.instanse(pidx)
    if player:isEmpty() then
        printe("这种情况应该不会发生")
        return
    end
    if player:get_attacking() then
        -- 如果玩家正在战斗中时，需要处理相关的释放
        local fleets = dbfleet.getListBycidx(player:get_cityidx())
        if fleets then
            for i, v in ipairs(fleets) do
                if v[dbfleet.keys.status] == IDConstVals.FleetState.fightingIsland then
                    logic4battle.stopBattle4Island(v[dbfleet.keys.idx])
                end
            end
        end
    end
    player:release()
    player = nil
end
return logic4battle
