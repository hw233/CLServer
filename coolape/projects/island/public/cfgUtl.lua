local skynet = require "skynet"

---@type curve
local curve = require("curve")
local numEx = require("numEx")
---@class cfgUtl
cfgUtl = {}

local curves = nil

function cfgUtl.initCurves()
    curves = {}
    local curveIns = curve.new(1, 0, 1, curve.easing.linear)
    table.insert(curves, curveIns)
    --curveIns = curve.new(1, 0, 1, curve.easing.inQuad)
    --table.insert(curves, curveIns)
    --curveIns = curve.new(1, 0, 1, curve.easing.outQuad)
    --table.insert(curves, curveIns)
    --curveIns = curve.new(1, 0, 1, curve.easing.inOutQuad)
    --table.insert(curves, curveIns)
    --curveIns = curve.new(1, 0, 1, curve.easing.outInQuad)
    --table.insert(curves, curveIns)
    curveIns = curve.new(1, 0, 1, curve.easing.inCirc)
    table.insert(curves, curveIns)
    curveIns = curve.new(1, 0, 1, curve.easing.outCirc)
    table.insert(curves, curveIns)
    curveIns = curve.new(1, 0, 1, curve.easing.inOutCirc)
    table.insert(curves, curveIns)
    curveIns = curve.new(1, 0, 1, curve.easing.outInCirc)
    table.insert(curves, curveIns)

    curveIns = curve.new(1,0,1, curve.easing.inExpo)
    table.insert(curves, curveIns)
    curveIns = curve.new(1,0,1, curve.easing.outExpo)
    table.insert(curves, curveIns)
    curveIns = curve.new(1,0,1, curve.easing.inOutExpo)
    table.insert(curves, curveIns)
    curveIns = curve.new(1,0,1, curve.easing.outInExpo)
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

---@public 取得成长值
---@param min 基础值
---@param max 最大值
---@param curveID 曲线id
---@param persent 百分比
---@param precision 小数点后几位
function cfgUtl.getGrowingVal(min, max, curveID, persent, precision)
    if curves == nil then
        cfgUtl.initCurves()
    end

    ---@type curve
    local curveins = curves[curveID]
    if curveins == nil then
        return 0
    end
    local persent = curveins:evaluate(persent)
    local val = min + (max - min) * persent

    if precision == nil or precision == 0 then
        return math.ceil(val)
    else
        return numEx.getPreciseDecimal(val, precision)
    end
end

return cfgUtl
