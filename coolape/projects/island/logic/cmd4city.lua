local skynet = require("skynet")
require("public.include")
require("public.cfgUtl")
require("dbcity")
require("dbtile")
require("dbbuilding")
local math = math
local table = table

local gridSize = 48
local cellSize = 1
---@type Grid
local grid4Building = Grid.new()
grid4Building:init(Vector3.zero, gridSize, gridSize, cellSize)
---@type Grid 地块的网格
local grid4Tile = Grid.new()
grid4Tile:init(Vector3.zero, gridSize / 2, gridSize / 2, cellSize * 2)
-- 网格状态
local gridState4Tile = {}
local gridState4Building = {}
---@class cmd4city
cmd4city = {}

---@type dbcity
local myself
local tiles = {}        -- 地块信息 key=idx
local buildings = {}    -- 建筑信息 key=idx

function cmd4city.new (uidx)
    tiles = {}        -- 地块信息 key=idx
    buildings = {}    -- 建筑信息 key=idx

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
    local building = cmd4city.newBuilding(1, grid4Building:GetCellIndex(numEx.getIntPart(gridSize / 2), numEx.getIntPart(gridSize / 2)), idx)
    if building then
        buildings[building:getidx()] = building
        gridState4Building[building:getpos()] = true
    end

    -- 初始化树
    cmd4city.initTree(myself)

    return myself
end

function cmd4city.canPlaceBuilding(index)
    return (not gridState4Building[index])
end

function cmd4city.canPlaceTile(index)
    return (not gridState4Tile[index])
end

function cmd4city.canPlace(index, is4Building)
    if is4Building then
        return cmd4city.canPlaceBuilding(index)
    else
        return cmd4city.canPlaceTile(index)
    end
end

function getFreeGridIdx(rangeV4, grid, is4Building)
    local x1 = rangeV4.x > rangeV4.z and rangeV4.z or rangeV4.x
    local x2 = rangeV4.x > rangeV4.z and rangeV4.x or rangeV4.z
    local y1 = rangeV4.y > rangeV4.w and rangeV4.w or rangeV4.y
    local y2 = rangeV4.y > rangeV4.w and rangeV4.y or rangeV4.w
    local cells = {}
    for i = x1, x2 do
        for j = y1, y2 do
            table.insert(cells, grid:GetCellIndex(i, j))
        end
    end
    local startIdx = math.random(1, #cells)
    if cmd4city.canPlace(startIdx, is4Building) then
        return startIdx
    end

    local i = startIdx + 1
    while true do
        if i > #cells then
            i = 1
        end
        if i == startIdx then
            break
        end
        if cmd4city.canPlace(cells[i], is4Building) then
            return cells[i]
        end
        i = i + 1
    end
    return -1
end

-- 取得一定范围内可用的地块
---@param rangeV4 Vector4
function cmd4city.getFreeGridIdx4Tile(rangeV4)
    return getFreeGridIdx(rangeV4, grid4Tile)
end

-- 取得一定范围内可用的地块
---@param rangeV4 Vector4
function cmd4city.getFreeGridIdx4Building(rangeV4)
    return getFreeGridIdx(rangeV4, grid4Building, true)
end

-- 初始化树
---@param dbcity
function cmd4city.initTree(city)
    local max = math.random(5, 12)
    for i = 1, max do
        local pos = cmd4city.getFreeGridIdx4Building(Vector4.New(20, 20, 30, 30))
        if pos >= 0 then
            -- attrid 32到36都是树的配制
            local treeAttrid = math.random(32, 36)
            local tree = cmd4city.newBuilding(treeAttrid, pos, city:getidx())
            if tree then
                buildings[tree:getidx()] = tree
                gridState4Building[tree:getpos()] = true
            end
        end
    end
end

-- 初始化地块
---@param city dbcity
function cmd4city.initTiles(city)
    local headquartersLevsAttr = cfgUtl.getHeadquartersLevsByID(city:getlev())
    if headquartersLevsAttr == nil then
        printe("get DBCFHeadquartersLevsData attr is nil. key=" .. city:getlev())
        return nil
    end

    local tileCount = headquartersLevsAttr.Tiles
    --local range = headquartersLevsAttr.Range
    local range = math.ceil(math.sqrt(tileCount))
    local gridCells = grid4Tile:getCells(grid4Tile:GetCellIndex( numEx.getIntPart(gridSize / 4 - 1), numEx.getIntPart(gridSize / 4 - 1)), range)
    for i, v in ipairs(gridCells) do
        if i <= tileCount then
            local tile = cmd4city.newTile(v, 0, city:getidx())
            if tile then
                tiles[tile:getidx()] = tile
                gridState4Tile[tile:getpos()] = true
            end
        else
            break
        end
    end

    cmd4city.setTilesAttr(tiles)
end

-- 设置tile属性
function cmd4city.setTilesAttr(tiles)
    ---@type dbtile
    local tile
    local attrid
    ---@type dbtile
    local left,right,up,down
    for idx, t in pairs(tiles) do
        tile = t
        left = grid4Tile:Left(tile:getpos())
        right = grid4Tile:Right(tile:getpos())
        up = grid4Tile:Up(tile:getpos())
        down = grid4Tile:Down(tile:getpos())
        attrid = cmd4city.getTileAttrWithAround(
                left and left:getattrid() or 0,
                right and right:getattrid() or 0,
                up and up:getattrid() or 0,
                down and down:getattrid() or 0
        )
        tile:setattrid(attrid)
    end
end

function cmd4city.getTileAttrWithAround(leftAttrId, righAttrId, upAttrId, downAttrId)
    local all = {1,2,3,4,5,6,7}
    local ret1 = all
    local ret2 = all
    local ret3 = all
    local ret4 = all
    local attr
    if leftAttrId > 0 then
        attr = cfgUtl.getTileByID(leftAttrId)
        ret1 = attr.Right
    end
    if righAttrId > 0 then
        attr = cfgUtl.getTileByID(righAttrId)
        ret2 = attr.Left
    end
    if upAttrId > 0 then
        attr = cfgUtl.getTileByID(upAttrId)
        ret3 = attr.Down
    end
    if downAttrId > 0 then
        attr = cfgUtl.getTileByID(downAttrId)
        ret3 = attr.Up
    end

    local ret = {}
    for i,v in ipairs(all) do
        if ret1[v] and ret2[v] and ret3[v] and ret4[v] then
            table.insert(ret, v)
        end
    end
    if #ret > 0 then
        return ret[math.random(1, #ret)]
    else
        return 1
    end
end

---@param idx 城的idx
function cmd4city.getSelf(idx)
    -- 取得城数据
    if myself == nil then
        myself = dbcity.instanse(idx)
        if myself:isEmpty() then
            printe("[cmd4city.get].get city data is nil. idx==" .. idx)
            return nil
        end
        -- 设置一次
        cmd4city.setSelfTiles()
        cmd4city.setSelfBuildings()
    end
    return myself
end

-- 新建地块
---@param pos grid地块的idx
---@param cidx 城idx
function cmd4city.newTile(pos, attrid, cidx)
    if not cmd4city.canPlace(pos, false) then
        printe("【cmd4city.newTile】该位置不能放置地块, pos ==" .. pos)
        return nil
    end
    local tile = dbtile.new()
    local t = {}
    t.idx = DBUtl.nextVal(DBUtl.Keys.building) --"唯一标识"
    t.attrid = attrid --"属性id"
    t.cidx = cidx --"主城idx"
    t.pos = pos -- "城所在世界grid的index"
    if tile:init(t) then
        gridState4Tile[pos] = true
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

function cmd4city.setSelfTiles()
    local list = cmd4city.queryTiles(myself:getidx())
    if list == nil then
        printe("[cmd4city.getSelfTiles]:get tiles is nil. cidx=" .. myself:getidx())
        return
    end
    tiles = {}
    ---@type dbtile
    local t
    for i, v in ipairs(list) do
        t = dbtile.new(v)
        tiles[v.idx] = t
        gridState4Tile[t:getpos()] = true
    end
end

function cmd4city.getSelfTiles()
    if myself == nil then
        printe("[cmd4city.getSelfTiles]:the city data is nil")
        return nil
    end
    return tiles
end

-- 新建筑
---@param attrid 建筑的配置id
---@param pos grid地块idx
---@param cidx 城idx
function cmd4city.newBuilding(attrid, pos, cidx)
    if not cmd4city.canPlace(pos, true) then
        printe("该位置不能放置建筑, pos ==" .. pos)
        return nil
    end
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
        gridState4Building[pos] = true
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

function cmd4city.setSelfBuildings()
    if myself == nil then
        printe("[cmd4city.getSelfBuildings]:the city data is nil")
        return
    end
    local list = cmd4city.queryBuildings(myself:getidx())
    if list == nil then
        printe("[cmd4city.getSelfBuildings]:get buildings is nil. cidx=" .. myself:getidx())
        return
    end
    buildings = {}
    ---@type dbbuilding
    local b
    for i, v in ipairs(list) do
        b = dbbuilding.new(v)
        buildings[v.idx] = b
        gridState4Building[b:getpos()] = true
    end
end

function cmd4city.getSelfBuildings()
    if myself == nil then
        printe("[cmd4city.getSelfBuildings]:the city data is nil")
        return nil
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

-- 释放数据
function cmd4city.release()
    ---@type dbbuilding
    local b
    for k, v in pairs(buildings) do
        b = v
        b:release()
    end
    buildings = {}

    ---@type dbtile
    local t
    for k, v in pairs(tiles) do
        t = v
        t:release()
    end
    tiles = {}

    if myself and (not myself:isEmpty()) then
        myself:release()
        myself = nil
    end
    gridState4Tile = {}
    gridState4Building = {}
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
        if not cmd4city.canPlace(m.pos, true) then
            printe("该位置不能放置建筑！pos==" .. m.pos)
            ret.code = Errcode.error
            ret.msg = "该位置不能放置建筑"
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
        gridState4Building[building:getpos()] = true

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
        gridState4Tile[t:getpos()] = nil
        t:setpos(m.pos)
        gridState4Tile[m.pos] = true
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
        -- 先释放之前的网格状态
        gridState4Building[b:getpos()] = nil
        b:setpos(m.pos)
        -- 设置新的网格的状态
        gridState4Building[m.pos] = true
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
