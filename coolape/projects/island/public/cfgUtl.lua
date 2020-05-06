local skynet = require "skynet"

---@type curve
local curve = require("curve")
local numEx = require("numEx")
---@class cfgUtl
cfgUtl = {}

local curves = nil

---public 初始化曲线
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

---public 取得常量配置
---@return DBCFCfgData
function cfgUtl.getConstCfg()
    return skynet.call("CLCfg", "lua", "getDataCfg", "DBCFCfgData", 1)
end

---public 通用取得配置数据列表
function cfgUtl.getCfgDatas(cfgName)
    return skynet.call("CLCfg", "lua", "getDataCfg", cfgName)
end

---public 通用取得配置数据by id
function cfgUtl.getCfgDataById(id, cfgName)
    return skynet.call("CLCfg", "lua", "getDataCfg", cfgName, id)
end

---public 取得主基地等级开放
---@return DBCFHeadquartersLevsData
function cfgUtl.getHeadquartersLevsByID(id)
    return skynet.call("CLCfg", "lua", "getDataCfg", "DBCFHeadquartersLevsData", id)
end

---public 取得地块的cfg
---@return DBCFTileData
function cfgUtl.getTileByID(id)
    return skynet.call("CLCfg", "lua", "getDataCfg", "DBCFTileData", id)
end

---public 取得建筑
---@return DBCFBuildingData
function cfgUtl.getBuildingByID(id)
    return skynet.call("CLCfg", "lua", "getDataCfg", "DBCFBuildingData", id)
end

---public 取得兵种数据
---@return DBCFRoleData
function cfgUtl.getRoleByID(id)
    return skynet.call("CLCfg", "lua", "getDataCfg", "DBCFRoleData", id)
end

---public 取得大地图地块数据
---@return DBCFMapTileData
function cfgUtl.getMapTileByID(id)
    return skynet.call("CLCfg", "lua", "getDataCfg", "DBCFMapTileData", id)
end

---public 取得道具
---@return DBCFItemData
function cfgUtl.getItemByID(id)
    return skynet.call("CLCfg", "lua", "getDataCfg", "DBCFItemData", id)
end

---public 取得成长值
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
    local persentVal = curveins:evaluate(persent)
    local val = min + (max - min) * persentVal

    if precision == nil or precision == 0 then
        return math.ceil(val)
    else
        return numEx.getPreciseDecimal(val, precision)
    end
end

---public 分钟转宝石
function cfgUtl.minutes2Diam(val)
    local cfg = cfgUtl.getConstCfg()
    local ret = numEx.getIntPart(val * cfg.Minute2DiamRate / 100)
    return ret > 0 and ret or 1
end


---public 资源转钻石
function cfgUtl.res2Diam(val)
    return math.ceil(val/100)
end

return cfgUtl
