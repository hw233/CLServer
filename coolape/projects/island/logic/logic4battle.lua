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
local IDConst = require("IDConst")

---@type logic4fleet
local logic4fleet = require("logic.logic4fleet")
---@type NetProtoIsland
local NetProtoIsland = skynet.getenv("NetProtoName")
---@type ClassBattleIsland
local ClassBattleIsland = require("battle.ClassBattleIsland")
---@type ClassFleetBattle
local ClassFleetBattle = require("battle.ClassFleetBattle")
---@type CLLPool
local poolBattleIsland = CLLPool.new(ClassBattleIsland)
---@type CLLPool
local poolFleetBattle = CLLPool.new(ClassFleetBattle)
local battles = {} --
local battles4Attacker = {} -- 进攻方玩家的战场（必须分开，因为可能我正在攻击其它人时，其它玩家正好也来进攻我）
local battles4Defener = {} -- 防守方玩家的战场（必须分开，因为可能我正在攻击其它人时，其它玩家正好也来进攻我）

logic4battle.newBattle = function(fidx)
    ---@type ClassBattleIsland
    local b = poolBattleIsland:borrow()
    b:init(fidx)
    battles[fidx] = b
    battles4Defener[b.targetPlayer:get_idx()] = b
    battles4Attacker[b.attackPlayer:get_idx()] = b
    return b
end

logic4battle.newBattleFleet = function(fidx1, fidx2)
    ---@type ClassFleetBattle
    local b = poolFleetBattle:borrow()
    b:init(fidx1, fidx2)
    battles[fidx1] = b
    return b
end

---public 取得进攻方的战场
logic4battle.getBattleOfAttacker = function(pidx)
    return battles4Attacker[pidx]
end
---public 取得防守方的战场
logic4battle.getBattleOfDefener = function(pidx)
    return battles4Defener[pidx]
end

logic4battle.prepareAttackIsland = function(fidx)
    local b = logic4battle.newBattle(fidx)
    b:prepare()
end

---public 开始进入舰队vs攻岛
---@param fidx number 舰队idx
logic4battle.startAttackIsland = function(fidx)
    ---@type ClassBattleIsland
    local b = battles[fidx]
    if b then
        b:start()
    end
end

---public 开始进入舰队vs舰队
---@param atkFidx number 进攻方舰队idx
---@param defFidx number 舰队idx
logic4battle.startAttackFleet = function(atkFidx, defFidx)
    local b = logic4battle.newBattleFleet(atkFidx, defFidx)
    b:start()
end

---@param map NetProtoIsland.RC_onBattleDeployUnit
logic4battle.onBattleDeployUnit = function(map, fd, agent)
    ---@type NetProtoIsland.ST_retInfor
    local ret = {}
    local fidx = map.battleFidx
    ---@type ClassBattleIsland
    local b = battles[fidx]
    if b then
        ret.code = b:onDeployUnit(map)
    else
        ret.code = Errcode.error
    end
    return pkg4Client(map, ret)
end
---@param map NetProtoIsland.RC_onBattleUnitDie
logic4battle.onBattleUnitDie = function(map, fd, agent)
    ---@type NetProtoIsland.ST_retInfor
    local ret = {}
    local fidx = map.battleFidx
    ---@type ClassBattleIsland
    local b = battles[fidx]
    if b then
        ret.code = b:onUnitDie(map.unitInfor)
    else
        ret.code = Errcode.error
    end
    return pkg4Client(map, ret)
end
---@param map NetProtoIsland.RC_onBattleBuildingDie
logic4battle.onBattleBuildingDie = function(map, fd, agent)
    local fidx = map.battleFidx
    ---@type NetProtoIsland.ST_retInfor
    local ret = {}
    ---@type ClassBattleIsland
    local b = battles[fidx]
    if b then
        ret.code = b:onBuildingDie(map.bidx)
    else
        ret.code = Errcode.error
    end
    return pkg4Client(map, ret)
end
---@param map NetProtoIsland.RC_onBattleLootRes
logic4battle.onBattleLootRes = function(map, fd, agent)
    local fidx = map.battleFidx
    ---@type NetProtoIsland.ST_retInfor
    local ret = {}
    ---@type ClassBattleIsland
    local b = battles[fidx]
    if b then
        ret.code = b:onLootRes(map)
    else
        ret.code = Errcode.error
    end
    return pkg4Client(map, ret)
end

---public 结束攻岛战斗
logic4battle.stopBattle4Island = function(fidx)
    ---@type ClassBattleIsland
    local b = battles[fidx]
    if b == nil then
        -- 因为有可以重启服务器时，要处理之前在战斗状态的舰队
        b = logic4battle.newBattle(fidx)
    end

    if b then
        b:stop()
    end
end

---public 当战斗结束
logic4battle.onFinishBattle = function(fidx)
    ---@type ClassBattleIsland
    local b = battles[fidx]
    if b then
        if b.type == IDConst.BattleType.attackFleet then
            b:release()
            poolFleetBattle:retObj(b)
        else
            battles4Defener[b.targetPlayer:get_idx()] = nil
            battles4Attacker[b.attackPlayer:get_idx()] = nil
            b:release()
            poolBattleIsland:retObj(b)
        end
        battles[fidx] = nil
        b = nil
    end
end

---public 有玩家离线了
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
                if v[dbfleet.keys.status] == IDConst.FleetState.fightingIsland then
                    logic4battle.stopBattle4Island(v[dbfleet.keys.idx])
                end
            end
        end
    end
    player:release()
    player = nil
end
return logic4battle
