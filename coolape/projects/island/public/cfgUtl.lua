local skynet = require "skynet"

---@type curve
local curve = require("curve")
---@class cfgUtl
cfgUtl = {}

local curves = nil

function cfgUtl.initCurves()
    curves = {}
    local curveIns = curve.new(1, 0, 1, curve.easing.linear)
    table.insert(curves, curveIns)
    curveIns = curve.new(1, 0, 1, curve.easing.inQuad)
    table.insert(curves, curveIns)
    curveIns = curve.new(1, 0, 1, curve.easing.outQuad)
    table.insert(curves, curveIns)
    curveIns = curve.new(1, 0, 1, curve.easing.inOutQuad)
    table.insert(curves, curveIns)
    curveIns = curve.new(1, 0, 1, curve.easing.outInQuad)
    table.insert(curves, curveIns)
    curveIns = curve.new(1, 0, 1, curve.easing.inCirc)
    table.insert(curves, curveIns)
    curveIns = curve.new(1, 0, 1, curve.easing.outCirc)
    table.insert(curves, curveIns)
    curveIns = curve.new(1, 0, 1, curve.easing.inOutCirc)
    table.insert(curves, curveIns)
    curveIns = curve.new(1, 0, 1, curve.easing.outInCirc)
    table.insert(curves, curveIns)
end

-- 取得常量配置
function cfgUtl.getConstCfg()
    return skynet.call("CLCfg", "lua", "getDataCfg", "DBCFCfgData", 1)
end

-- 取得主基地等级开放
function cfgUtl.getHeadquartersLevsByID(id)
    return skynet.call("CLCfg", "lua", "getDataCfg", "DBCFHeadquartersLevsData", id)
end

-- 取得地块的cfg
function cfgUtl.getTileByID(id)
    return skynet.call("CLCfg", "lua", "getDataCfg", "DBCFTileData", id)
end

-- 取得建筑
function cfgUtl.getBuildingByID(id)
    return skynet.call("CLCfg", "lua", "getDataCfg", "DBCFBuildingData", id)
end

-- 取得成长值
function cfgUtl.getGrowingVal(min, max, curveID, persent)
    if curves == nil then
        cfgUtl.initCurves()
    end
    ---@type curve
    local curveins = curves[curveID]
    local persent = curveins:evaluate(persent)
    return min + (max - min) * persent
end

return cfgUtl
