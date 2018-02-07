require("dbcity")
require("dbbuilding")
require("DBUtl")

---@class cmd4city
cmd4city = {}

---@type dbcity
local myself
local buildings = {}

function cmd4city.new (uidx)
    local idx = DBUtl.nextVal(DBUtl.Keys.city)
    myself = dbcity.new()
    local d = {}
    d.idx = idx
    d.name = "new city"
    d.pidx = uidx
    d.pos = 0
    d.status = 1
    d.lev = 0
    myself:init(d)
    -- 初始化建筑
    -- add base buildings
    local building = cmd4city.newBuilding(1, 50050, idx)
    if building then
        buildings[building:getidx()] = building 
    end
    return myself
end

-- 新建筑
function cmd4city.newBuilding(attrid, pos, cidx)
    local building = dbbuilding.new()
    local b = {}
    b.idx = DBUtl.nextVal(DBUtl.Keys.building) -- 唯一标识
    b.cidx = cidx -- 主城idx
    b.pos = pos -- 位置，即在城的gird中的index
    b.attrid = attrid -- 属性配置id
    b.lev = 1 -- 等级
    b.val = 0 -- 值。如:产量，仓库的存储量等
    b.val2 = 0 -- 值。如:产量，仓库的存储量等
    b.val3 = 0 -- 值。如:产量，仓库的存储量等
    b.val4 = 0 -- 值。如:产量，仓库的存储量等

    if building:init(b) then
        return building
    else
        skynet.error("[cmd4city.newBuilding] new building error. attrid=" .. attrid .. "  pos==" .. pos .. "  cidx==" .. cidx)
        return nil
    end
end

function cmd4city.getSelf(idx)
    -- 取得城数据
    if myself == nil then
        myself = dbcity.instanse(idx)
        if myself:isEmpty() then
            skynet.error("[cmd4city.get].get city data is nil. idx==" .. idx)
            return nil
        end
        -- 设置一次
        cmd4city.getBuildings()
    end
    return myself
end

function cmd4city.query(idx)
    -- 取得城数据
    local city = dbcity.instanse(idx)
    if city:isEmpty() then
        return nil
    end
    local ret = city:value2copy()
    city:release()
    return ret
end

function cmd4city.queryBuildings(cidx)
    return dbbuilding.getList(cidx)
end

function cmd4city.getSelfBuildings()
    if myself == nil then
        skynet.error("[cmd4city.getBuildings]:the city data is nil")
        return nil
    end
    local list = cmd4city.queryBuildings(myself:getidx())
    if list == nil then
        skynet.error("[cmd4city.getBuildings]:get buildings is nil. cidx=" .. myself:getidx())
        return nil
    end
    buildings = {}
    ---@type dbbuilding
    local b
    for i, v in ipairs(list) do
        b = dbbuilding.new(v)
        buildings[v.idx] = b
    end
    return buildings
end

function cmd4city.release()
    ---@type dbbuilding
    local b
    for k, v in pairs(buildings) do
        b = v
        b:release()
    end
    buildings = {}

    if myself then
        myself:release()
        myself = nil
    end
end

return cmd4city
