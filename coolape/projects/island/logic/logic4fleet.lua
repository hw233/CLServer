---@class logic4fleet
local logic4fleet = {}
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
---@type logic4city
local logic4city = require("logic.logic4city")

local CMD = {}
local moveSpeed
local constDeadMs
local _fleetCruPos = {}

---public 从造舰厂里扣除舰船
---@param agent agent
---@return boolean 是否成功
local deductShipsInDockyard = function(id, num, agent)
    local cityServer = skynet.call(agent, "lua", "getLogic", "cmd4city")
    local success = skynet.call(cityServer, "lua", "deductShipsInDockyard", id, num)
    if not success then
        loge(agent, "从造舰厂里扣除舰船失败: shipid=[" .. id .. "] num=[" .. num .. "]")
    end
    return success
end

logic4fleet.init = function()
    moveSpeed = cfgUtl.getConstCfg().FleetMoveSpeed * 1000
    constDeadMs = cfgUtl.getConstCfg().FleetTimePerOnce * 60 * 1000
end

---public 舰队是否自己的
logic4fleet.isMyFleet = function(session, fidx)
    if fidx == nil or fidx <= 0 then
        return false
    end
    local pidx = getPlayerIdx(session)
    if not pidx then
        return false
    end
    local player = dbplayer.instanse(pidx)
    if player:isEmpty() then
        player:release()
        return false
    end
    local cidx = player:get_cityidx()
    local fleet = dbfleet.instanse(fidx)
    local ret = false
    if fleet:get_cidx() == cidx then
        ret = true
    else
        ret = false
    end
    player:release()
    fleet:release()
    return ret
end

---public 判断舰队是否为空
logic4fleet.isEmpty = function(fidx)
    local fleet = dbfleet.instanse(fidx)
    local units = dbunit.getListByfidx(fidx)
    if #units == 0 then
        return true
    end
    for i, v in ipairs(units) do
        if v[dbunit.keys.num] > 0 then
            -- 说明至少有一种战斗单元的数量大于0
            return false
        end
    end
    return true
end

---public 新建筑舰队
---@return dbfleet
logic4fleet.new = function(name, cidx, pos)
    local fleet = dbfleet.new()
    local idx = DBUtl.nextVal(DBUtl.Keys.fleet)
    local fleetData = {}
    fleetData[dbfleet.keys.idx] = idx
    fleetData[dbfleet.keys.name] = CLUtl.isNilOrEmpty(name) and "new fleets" .. idx or name
    fleetData[dbfleet.keys.cidx] = cidx
    fleetData[dbfleet.keys.name] = name
    fleetData[dbfleet.keys.curpos] = pos
    fleetData[dbfleet.keys.task] = IDConst.FleetTask.idel
    fleetData[dbfleet.keys.status] = IDConst.FleetState.none
    fleet:init(fleetData)
    return fleet
end

---@param v3Pos Vector3
logic4fleet.setFleetCurPos = function(fidx, v3Pos)
    _fleetCruPos[fidx] = v3Pos
end

---public 更新舰队的舰船信息
logic4fleet.refreshUnits = function(idx, units, agent)
    local fleet = dbfleet.instanse(idx)

    local oldShips = {}
    local _oldShips = dbunit.getListByfidx(fleet:get_idx()) or {}
    for i, v in ipairs(_oldShips) do
        oldShips[v[dbunit.keys.id]] = dbunit.instanse(v[dbunit.keys.idx])
    end

    -- 设置舰船数据
    ---@param v NetProtoIsland.ST_unitInfor
    for i, v in ipairs(units) do
        ---@type dbunit
        local unit = oldShips[v.id]
        if unit then
            local diff = v.num - unit:get_num()
            if diff > 0 then
                -- 从造舰厂里扣除舰船,只能在idle状态时才可以增加舰船数量
                if fleet:get_task() == IDConst.FleetTask.idel and deductShipsInDockyard(v.id, diff, agent) then
                    unit:set_num(v.num)
                end
            elseif diff < 0 then
                -- 丢弃掉多的舰船
                unit:set_num(v.num)
            end
            unit:release()
            oldShips[v.id] = nil
        else
            -- 说明是新加入的舰船数据,只能在idle状态时才可以增加舰船数量
            if fleet:get_task() == IDConst.FleetTask.idel and deductShipsInDockyard(v.id, v.num, agent) then
                v[dbunit.keys.idx] = DBUtl.nextVal(DBUtl.Keys.unit)
                v[dbunit.keys.fidx] = fleet:get_idx()
                dbunit.new(v):release()
            end
        end
    end
    ---@param v dbunit
    for k, v in pairs(oldShips) do
        -- 剩下的就是需要删除的
        v:delete()
    end
    fleet:release()
end

---public 消耗战斗单元
---@param fidx number 舰队idx
---@param unitId number 战斗单元
---@return boolean 成功？
logic4fleet.consumeUnit = function(fidx, unitId, num)
    local fleet = logic4fleet.getFleet(fidx)
    for i, unit in ipairs(fleet.units) do
        if unit[dbunit.keys.id] == unitId then
            if unit[dbunit.keys.num] >= num then
                local u = dbunit.instanse(unit[dbunit.keys.idx])
                u:set_num(u:get_num() - num)
                if u:get_num() <= 0 then
                    u:delete()
                else
                    u:release()
                end
                return true
            else
                return false
            end
        end
    end
    return false
end

---public 取得舰队的信息
---@return NetProtoIsland.ST_fleetinfor
logic4fleet.getFleet = function(idx)
    local fleet = dbfleet.instanse(idx)
    local units = dbunit.getListByfidx(idx)
    ---@type NetProtoIsland.ST_fleetinfor
    local result = fleet:value2copy()
    result.units = units
    ---@type Vector3
    local fromPos = _fleetCruPos[idx]
    if fromPos then
        ---@type NetProtoIsland.ST_vector3
        local v3 = {}
        v3.x = numEx.getIntPart(fromPos.x * 1000)
        v3.y = numEx.getIntPart(fromPos.y * 1000)
        v3.z = numEx.getIntPart(fromPos.z * 1000)
        result.fromposv3 = v3
    end
    local city = dbcity.instanse(fleet:get_cidx())
    local player = dbplayer.instanse(city:get_pidx())
    -- 设置玩家名
    result.pidx = player:get_idx()
    result.pname = player:get_name()
    city:release()
    player:release()
    fleet:release()
    return result
end

---public 取得玩的pidx
logic4fleet.getPlayerIdx = function(fidx)
    local fleet = dbfleet.instanse(fidx)
    if fleet:isEmpty() then
        fleet:release()
        return
    end
    local city = dbcity.instanse(fleet:get_cidx())
    if city:isEmpty() then
        fleet:release()
        city:release()
        return
    end
    local pidx = city:get_pidx()
    fleet:release()
    city:release()
    return pidx
end

---public 删除舰队
logic4fleet.delete = function(idx)
    local fleet = dbfleet.instanse(idx)
    if fleet:isEmpty() then
        fleet:release()
        return
    end

    if fleet:get_task() ~= IDConst.FleetTask.idel then
        if fleet:get_status() == IDConst.FleetState.docked or fleet:get_status() == IDConst.FleetState.stay then
            local tile = dbworldmap.instanse(fleet:get_curpos())
            if not tile:isEmpty() then
                tile:delete()
                skynet.call("USWorld", "lua", "pushMapCellChg", fleet:get_curpos())
            end
        end
    end

    local units = dbunit.getListByfidx(idx)
    for i, v in ipairs(units) do
        local unit = dbunit.instanse(v[dbunit.keys.idx])
        if not unit:isEmpty() then
            unit:delete()
        end
    end
    fleet:delete()
end

return logic4fleet
