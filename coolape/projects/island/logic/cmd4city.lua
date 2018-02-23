require("DBUtl")
require("CLGlobal")
require("public.cfgUtl")
require("dbcity")
require("dbtile")
require("dbbuilding")

local gridSize = 50
local cellSize = 1
---@type Grid
local grid = require("Grid")
grid.init(Vector3.zero, gridSize, gridSize, cellSize)

---@class cmd4city
cmd4city = {}

---@type dbcity
local myself
local tiles = {}        -- 地块信息
local buildings = {}    -- 建筑信息

function cmd4city.new (uidx)
    local idx = DBUtl.nextVal(DBUtl.Keys.city)
    myself = dbcity.new()
    local d = {}
    d.idx = idx
    d.name = "new city"
    d.pidx = uidx
    d.pos = skynet.call("LDSWorld", "lua", "getIdleIdx")
    d.status = 1
    d.lev = 1
    myself:init(d)
    --初始化地块
    cmd4city.initTiles(myself)

    --TODO: 初始化建筑
    -- add base buildings
    local building = cmd4city.newBuilding(1, 50050, idx)
    if building then
        buildings[building:getidx()] = building
    end
    return myself
end

-- 初始化地块
---@param city dbcity
function cmd4city.initTiles(city)
    local cfg = cfgUtl.getHeadquartersLevsByID(city:getlev())
    if cfg == nil then
        printe("get DBCFHeadquartersLevsData attr is nil. key=" .. city:getlev())
        return nil
    end
    local tileCount = cfg.Tiles
end

function cmd4city.getSelf(idx)
    -- 取得城数据
    if myself == nil then
        myself = dbcity.instanse(idx)
        if myself:isEmpty() then
            printe("[cmd4city.get].get city data is nil. idx==" .. idx)
            return nil
        end
        -- 设置一次
        cmd4city.getSelfTiles()
        cmd4city.getSelfBuildings()
    end
    return myself
end

function cmd4city.newTile(pos, cidx)
    local tile = dbtile.new()
    local t = {}
    t.idx = DBUtl.nextVal(DBUtl.Keys.building) --"唯一标识"
    t.attrid = 1 --"属性id"
    t.cidx = cidx --"主城idx"
    t.pos = pos -- "城所在世界grid的index"
    if tile:init(t) then
        return tile
    else
        printe("[cmd4city.newTile]==" .. CLUtl.dump(t))
        return nil
    end
end

function cmd4city.queryTiles(cidx)
    return dbtile.getList(cidx)
end

function cmd4city.getSelfTile(idx)
    -- 取得建筑
    if myself == nil then
        printe("主城为空")
        return nil
    end
    if tiles == nil or #tiles == 0 then
        printe("地块信息列表为空")
        return nil
    end
    ---@type dbbuilding
    local t = tiles[idx]
    if t == nil then
        printe("取得地块为空")
        return nil
    end
    return t
end

function cmd4city.getSelfTiles()
    if myself == nil then
        printe("[cmd4city.getSelfTiles]:the city data is nil")
        return nil
    end
    if tiles and #tiles > 0 then
        return tiles
    end
    local list = cmd4city.queryTiles(myself:getidx())
    if list == nil then
        printe("[cmd4city.getSelfTiles]:get tiles is nil. cidx=" .. myself:getidx())
        return nil
    end
    tiles = {}
    ---@type dbbuilding
    local t
    for i, v in ipairs(list) do
        t = dbtile.new(v)
        tiles[v.idx] = t
    end
    return tiles
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
        printe("[cmd4city.newBuilding] new building error. attrid=" .. attrid .. "  pos==" .. pos .. "  cidx==" .. cidx)
        return nil
    end
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
        printe("[cmd4city.getSelfBuildings]:the city data is nil")
        return nil
    end
    if buildings and #buildings > 0 then
        return buildings
    end
    local list = cmd4city.queryBuildings(myself:getidx())
    if list == nil then
        printe("[cmd4city.getSelfBuildings]:get buildings is nil. cidx=" .. myself:getidx())
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

function cmd4city.getSelfBuilding(idx)
    -- 取得建筑
    if myself == nil then
        printe("主城为空")
        return nil
    end
    if buildings == nil or #buildings == 0 then
        printe("建筑信息列表为空")
        return nil
    end
    ---@type dbbuilding
    local b = buildings[idx]
    if b == nil then
        printe("取得建筑为空")
        return nil
    end
    return b
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

--＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝
--＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝
cmd4city.CMD = {
    newBuilding = function(m, fd)
        -- 新建筑
        local ret = {}
        if myself == nil then
            printe("主城数据为空！")
            ret.code = Errcode.error
            ret.msg = "主城数据为空"
            return NetProto.send.newBuilding(ret, nil)
        end
        local building = cmd4city.newBuilding(m.attrid, m.pos, myself:getidx())
        if building == nil then
            printe("新建建筑失败")
            ret.code = Errcode.error
            ret.msg = "新建建筑失败"
            return NetProto.send.newBuilding(ret, nil)
        end
        buildings[building:getidx()] = building

        ret.code = Errcode.ok
        return NetProto.send.newBuilding(ret, building:value2copy())
    end,
    getBuilding = function(m, fd)
        -- 取得建筑
        local ret = {}
        local b = cmd4city.getSelfBuilding(m.idx)
        if b == nil then
            ret.code = Errcode.error
            ret.msg = "取得建筑为空"
            return NetProto.send.getBuilding(ret, nil)
        end
        ret.code = Errcode.ok
        return NetProto.send.getBuilding(ret, b:value2copy())
    end,
    moveTile = function(m, fd)
        -- 移动地块
        local ret = {}
        ---@type dbtile
        local t = cmd4city.getSelfTile(m.idx)
        if t == nil then
            ret.code = Errcode.error
            ret.msg = "取得地块为空"
            return NetProto.send.moveTile(ret, nil)
        end
        t:setpos(m.pos)
        ret.code = Errcode.ok
        return NetProto.send.moveTile(ret, t:value2copy())
    end,
    moveBuilding = function(m, fd)
        -- 移动建筑
        local ret = {}
        ---@type dbbuilding
        local b = cmd4city.getSelfBuilding(m.idx)
        if b == nil then
            ret.code = Errcode.error
            ret.msg = "取得建筑为空"
            return NetProto.send.moveBuilding(ret, nil)
        end
        b:setpos(m.pos)
        ret.code = Errcode.ok
        return NetProto.send.moveBuilding(ret. b:value2copy())
    end,
    upLevBuilding = function(m, fd)
        -- 建筑升级
        local ret = {}
        local b = cmd4city.getSelfBuilding(m.idx)
        if b == nil then
            ret.code = Errcode.error
            ret.msg = "取得建筑为空"
            return NetProto.send.upLevBuilding(ret, nil)
        end
        --TODO: check max lev
        b:setlev(b:getlev() + 1)
        ret.code = Errcode.ok
        return NetProto.send.upLevBuilding(ret)
    end,
}

return cmd4city
