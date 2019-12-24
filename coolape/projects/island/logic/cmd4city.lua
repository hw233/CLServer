---@class cmd4city
local cmd4city = {}
local skynet = require("skynet")
require("public.include")
require("public.cfgUtl")
require("dbcity")
require("dbtile")
require("dbbuilding")
require("dbplayer")
require("dbunit")
require("Errcode")
require("timerQueue")
local timerEx = require("timerEx")
local IDConstVals = require("IDConstVals")
local CMD = {}
local math = math
local table = table

local constCfg  -- 常量配置
local gridSize  -- 网格size
local cellSize = 1
local tileSize = 2

local NetProtoIsland = skynet.getenv("NetProtoName")
---@type Grid
local grid

-- 网格状态
local gridState4Tile = {}
local gridState4Building = {}
local agent

---@type dbcity
local myself
local tiles = {} -- 地块信息 key=idx, val=dbtile
local buildings = {} -- 建筑信息 key=idx, val=dbbuilding
---@type dbbuilding
local headquarters  -- 主基地
local buildingCountMap = {} -- key=buildingAttrid;value=count
local hadTileCount = 0 -- 地块总量

--======================================================
--======================================================
cmd4city.new = function(uidx)
    tiles = {} -- 地块信息 key=idx
    buildings = {} -- 建筑信息 key=idx

    local idx = DBUtl.nextVal(DBUtl.Keys.city)

    local attrid = 7
    -- 分配一个世界坐标
    local mapcell = skynet.call("LDSWorld", "lua", "occupyMapCell", idx, IDConstVals.WorldmapCellType.user, attrid)
    myself = dbcity.new()
    local d = {}
    d.idx = idx
    d.name = "new city"
    d.pidx = uidx
    d.pos = mapcell.idx
    d.status = 1
    d.lev = 1
    myself:init(d, true)
    myself:setTrigger(skynet.self(), "onMyselfCityChg")

    --TODO: 初始化建筑
    -- add base buildings
    ---@type dbbuilding
    local building =
        cmd4city.newBuilding(
        1,
        grid:GetCellIndex(numEx.getIntPart(gridSize / 2 - 1), numEx.getIntPart(gridSize / 2 - 1)),
        idx
    )
    if building then
        building:refreshData(
            {
                [dbbuilding.keys.lev] = 1, -- 初始成一级
                [dbbuilding.keys.val] = IDConstVals.baseRes, -- 粮
                [dbbuilding.keys.val2] = IDConstVals.baseRes, -- 金
                [dbbuilding.keys.val3] = IDConstVals.baseRes -- 油
            }
        )
        buildings[building:get_idx()] = building
        headquarters = building
    end

    --初始化地块
    cmd4city.initTiles(myself)

    -- 初始化树
    --cmd4city.initTree(myself, v4)

    return myself
end

---@param building dbbuilding
cmd4city.placeBuilding = function(building)
    local center = building:get_pos()
    local attr = cfgUtl.getBuildingByID(building:get_attrid())
    local size = attr.Size
    local indexs = grid:getCells(center, size)
    for i, index in ipairs(indexs) do
        gridState4Building[index] = true
    end
end

---@param building dbbuilding
cmd4city.unPlaceBuilding = function(building)
    local center = building:get_pos()
    local attr = cfgUtl.getBuildingByID(building:get_attrid())
    local size = attr.Size
    local indexs = grid:getCells(center, size)
    for i, index in ipairs(indexs) do
        gridState4Building[index] = nil
    end
end

---@param tile dbtile
cmd4city.placeTile = function(tile)
    local center = tile:get_pos()

    local indexs = grid:getCells(center, tileSize)
    for i, index in ipairs(indexs) do
        gridState4Tile[index] = true
    end
end
---@param tile dbtile
cmd4city.unPlaceTile = function(tile)
    local center = tile:get_pos()
    local indexs = grid:getCells(center, tileSize)
    for i, index in ipairs(indexs) do
        gridState4Tile[index] = nil
    end
end

cmd4city.canPlaceBuilding = function(index, id)
    if id then
        local attr = cfgUtl.getBuildingByID(id)
        local size = attr.Size
        local indexs = grid:getCells(index, size)
        for i, v in ipairs(indexs) do
            if (not grid:IsInBounds(v)) or gridState4Building[v] then
                return false
            end
        end
        return true
    else
        return (not gridState4Building[index])
    end
end

cmd4city.canPlaceTile = function(index)
    local indexs = grid:getCells(index, tileSize)
    for i, v in ipairs(indexs) do
        if (not grid:IsInBounds(v)) or gridState4Tile[v] then
            return false
        end
    end

    return true
end

cmd4city.canPlace = function(index, is4Building, attrid)
    if is4Building then
        return cmd4city.canPlaceBuilding(index, attrid)
    else
        return cmd4city.canPlaceTile(index)
    end
end

---@param grid Grid
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
    if cmd4city.canPlace(cells[startIdx], is4Building) then
        return cells[startIdx]
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
cmd4city.getFreeGridIdx4Tile = function(rangeV4)
    return getFreeGridIdx(rangeV4, grid)
end

-- 取得一定范围内可用的地块
---@param rangeV4 Vector4
cmd4city.getFreeGridIdx4Building = function(rangeV4)
    return getFreeGridIdx(rangeV4, grid, true)
end

-- 初始化树
---@param dbcity
cmd4city.initTree = function(city, rangeV4)
    local max = math.random(5, 12)
    for i = 1, max do
        local pos = cmd4city.getFreeGridIdx4Building(rangeV4)
        if pos >= 0 then
            -- attrid 32到36都是树的配制
            local treeAttrid = math.random(30, 34)
            local tree = cmd4city.newBuilding(treeAttrid, pos, city:get_idx())
        end
    end
end

-- 取得主城的等级，其实就是主基地的等级
cmd4city.getCityLev = function()
    if headquarters and (not headquarters:isEmpty()) then
        return headquarters:get_lev()
    else
        return 1
    end
end

-- 初始化地块
---@param city dbcity
cmd4city.initTiles = function(city)
    local headquartersLevsAttr = cfgUtl.getHeadquartersLevsByID(1)
    if headquartersLevsAttr == nil then
        printe("get DBCFHeadquartersLevsData attr is nil. key=" .. cmd4city.getCityLev())
        return nil
    end

    local tileCount = headquartersLevsAttr.Tiles
    --local range = headquartersLevsAttr.Range
    local range = math.ceil(math.sqrt(tileCount * 4))
    local gridCells =
        grid:getCells(grid:GetCellIndex(numEx.getIntPart(gridSize / 2 - 1), numEx.getIntPart(gridSize / 2 - 1)), range)
    local counter = 0
    local treeCounter = 0
    local maxTree = math.random(10, 20)
    for i, index in ipairs(gridCells) do
        if counter < tileCount then
            local tile = cmd4city.newTile(index, 0, city:get_idx())
            if tile then
                counter = counter + 1

                -- 初始化树
                if treeCounter < maxTree then
                    local tileCells = grid:getCells(index, tileSize)
                    for i, index2 in ipairs(tileCells) do
                        if numEx.nextBool() then
                            -- attrid 32到36都是树的配制
                            local treeAttrid = math.random(32, 36)
                            local tree = cmd4city.newBuilding(treeAttrid, index2, city:get_idx())
                            if tree then
                                --tree:set_lev(1)
                                treeCounter = treeCounter + 1
                            end
                        end
                    end
                end
            end
        else
            break
        end
    end

    cmd4city.setTilesAttr(tiles)
    return rangeV4
end

-- 设置tile属性
cmd4city.setTilesAttr = function(tiles)
    ---@type dbtile
    local tile
    local attrid
    ---@type dbtile
    local left, right, up, down
    for idx, t in pairs(tiles) do
        tile = t
        left = grid:Left(tile:get_pos())
        left = tiles[left]
        right = grid:Right(tile:get_pos())
        right = tiles[right]
        up = grid:Up(tile:get_pos())
        up = tiles[up]
        down = grid:Down(tile:get_pos())
        down = tiles[down]
        attrid =
            cmd4city.getTileAttrWithAround(
            left and left:get_attrid() or 0,
            right and right:get_attrid() or 0,
            up and up:get_attrid() or 0,
            down and down:get_attrid() or 0
        )
        tile:set_attrid(attrid)
    end
end

cmd4city.getTileAttrWithAround = function(leftAttrId, righAttrId, upAttrId, downAttrId)
    local all = {1, 2, 3, 4, 5, 6, 7}
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
    for i, v in ipairs(all) do
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
cmd4city.getSelf = function(idx)
    -- 取得城数据
    if myself == nil then
        myself = dbcity.instanse(idx)
        if myself:isEmpty() then
            printe("[cmd4city.get].get city data is nil. idx==" .. idx)
            return nil
        end
        --设置触发器
        myself:setTrigger(skynet.self(), "onMyselfCityChg")
        -- 设置一次
        cmd4city.setSelfTiles()
        cmd4city.setSelfBuildings()
    end
    return myself
end

-- 新建地块
---@param pos grid地块的idx
---@param cidx 城idx
cmd4city.newTile = function(pos, attrid, cidx)
    local headquartersOpen = cfgUtl.getHeadquartersLevsByID(headquarters:get_lev())
    local maxNum = headquartersOpen.Tiles
    if hadTileCount >= maxNum then
        printe("地块数量已经达上限！")
        return nil, Errcode.maxNumber
    end

    if not cmd4city.canPlace(pos, false) then
        printe("【cmd4city.newTile】该位置不能放置地块, pos ==" .. pos)
        return nil, Errcode.cannotPlace
    end
    local tile = dbtile.new()
    local t = {}
    t.idx = DBUtl.nextVal(DBUtl.Keys.building) --"唯一标识"
    t.attrid = attrid --"属性id"
    t.cidx = cidx --"主城idx"
    t.pos = pos -- "城所在世界grid的index"
    if tile:init(t, true) then
        cmd4city.placeTile(tile)

        tiles[tile:get_idx()] = tile
        hadTileCount = hadTileCount + 1
        return tile
    else
        printe("[cmd4city.newTile]==" .. CLUtl.dump(t))
        return nil, Errcode.error
    end
end

cmd4city.queryTiles = function(cidx)
    return dbtile.getListBycidx(cidx)
end

cmd4city.getSelfTile = function(idx)
    -- 取得建筑
    if myself == nil then
        printe("主城为空")
        return nil
    end
    if tiles == nil then
        printe("地块信息列表为空")
        return nil
    end
    ---@type dbbuilding
    local t = tiles[idx]
    if t == nil then
        printe("取得地块为空" .. idx)
        return nil
    end
    return t
end

cmd4city.delSelfBuilding = function(idx)
    -- 取得建筑
    if myself == nil then
        printe("主城为空")
        return Errcode.cityIsNil
    end
    if buildings == nil then
        printe("地块信息列表为空")
        return Errcode.buildingListIsNil
    end
    ---@type dbtile
    local b = buildings[idx]
    if b == nil then
        printe("取得建筑为空==" .. idx)
        return Errcode.buildingIsNil
    end

    buildingCountMap[b:get_attrid()] = (buildingCountMap[b:get_attrid()] or 0) - 1
    cmd4city.unPlaceBuilding(b)
    b:unsetTrigger(skynet.self(), "onBuildingChg")
    b:delete()

    buildings[idx] = nil
    return Errcode.ok
end

cmd4city.delSelfTile = function(idx)
    -- 取得建筑
    if myself == nil then
        printe("主城为空")
        return Errcode.cityIsNil
    end
    if tiles == nil then
        printe("地块信息列表为空")
        return Errcode.tileListIsNil
    end
    ---@type dbtile
    local t = tiles[idx]
    if t == nil then
        printe("取得地块为空")
        return Errcode.tileIsNil
    end

    cmd4city.unPlaceTile(t)
    hadTileCount = hadTileCount - 1
    t:delete()
    tiles[idx] = nil
    return Errcode.ok
end

cmd4city.setSelfTiles = function()
    local list = cmd4city.queryTiles(myself:get_idx())
    if list == nil then
        printe("[cmd4city.setSelfTiles]:get tiles is nil. cidx=" .. myself:get_idx())
        return
    end
    tiles = {}
    ---@type dbtile
    local t
    for i, v in ipairs(list) do
        t = dbtile.new(v)
        tiles[v.idx] = t
        hadTileCount = hadTileCount + 1
        cmd4city.placeTile(t)
    end
end

cmd4city.getSelfTiles = function()
    if myself == nil then
        printe("[cmd4city.getSelfTiles]:the city data is nil")
        return nil
    end
    return tiles
end

---@public 取得当前等级建筑的最大数量
cmd4city.getBuildingCountAtCurrLev = function(buildingAttrId)
    if headquarters == nil then
        return 1
    end
    local headquartersOpen = cfgUtl.getHeadquartersLevsByID(headquarters:get_lev())
    return headquartersOpen["Building" .. buildingAttrId] or 1
end

---@public 新建筑
---@param attrid 建筑的配置id
---@param pos grid地块idx
---@param cidx 城idx
cmd4city.newBuilding = function(attrid, pos, cidx)
    -- 数量判断
    local hadNum = (buildingCountMap[attrid] or 0)
    if attrid ~= IDConstVals.headquartersBuildingID then
        local maxNum = cmd4city.getBuildingCountAtCurrLev(attrid)
        if hadNum >= maxNum then
            printe("已经达到建筑最大数量！")
            return nil, Errcode.maxNumber
        end
    end

    if not cmd4city.canPlace(pos, true, attrid) then
        printe("该位置不能放置建筑, pos ==" .. pos)
        return nil, Errcode.cannotPlace
    end
    local building = dbbuilding.new()
    local b = {}
    b.idx = DBUtl.nextVal(DBUtl.Keys.building) -- 唯一标识
    b.cidx = cidx -- 主城idx
    b.pos = pos -- 位置，即在城的gird中的index
    b.attrid = attrid -- 属性配置id
    b.lev = 0 -- 等级
    b.val = 0 -- 值。如:产量，仓库的存储量等
    b.val2 = 0 -- 值。如:产量，仓库的存储量等
    b.val3 = 0 -- 值。如:产量，仓库的存储量等
    b.val4 = 0 -- 值。如:产量，仓库的存储量等

    if building:init(b, true) then
        buildings[b.idx] = building
        buildingCountMap[building:get_attrid()] = (buildingCountMap[building:get_attrid()] or 0) + 1
        cmd4city.placeBuilding(building)
        building:setTrigger(skynet.self(), "onBuildingChg")
        return building
    else
        printe("[cmd4city.newBuilding] new building error. attrid=" .. attrid .. "  pos==" .. pos .. "  cidx==" .. cidx)
        return nil, Errcode.error
    end
end

cmd4city.query = function(idx)
    -- 取得城数据
    local city = dbcity.instanse(idx)
    if city:isEmpty() then
        return nil
    end
    local ret = city:value2copy()
    city:release()
    return ret
end

cmd4city.queryBuildings = function(cidx)
    return dbbuilding.getListBycidx(cidx)
end

cmd4city.setSelfBuildings = function()
    if myself == nil then
        printe("[cmd4city.getSelfBuildings]:the city data is nil")
        return
    end
    local list = cmd4city.queryBuildings(myself:get_idx())
    if list == nil then
        printe("[cmd4city.getSelfBuildings]:get buildings is nil. cidx=" .. myself:get_idx())
        return
    end
    buildings = {}
    ---@type dbbuilding
    local b
    for i, v in ipairs(list) do
        b = dbbuilding.new(v)
        buildings[v.idx] = b
        b:setTrigger(skynet.self(), "onBuildingChg")
        buildingCountMap[b:get_attrid()] = (buildingCountMap[b:get_attrid()] or 0) + 1

        if b:get_state() == IDConstVals.BuildingState.upgrade then
            if b:get_endtime() <= dateEx.nowMS() then
                cmd4city.onFinishBuildingUpgrade(b)
            else
                timerQueue.addtimerQueue(b, cmd4city.onFinishBuildingUpgrade)
            end
        elseif b:get_state() == IDConstVals.BuildingState.working then
            -- 正生产
            if b:get_attrid() == IDConstVals.dockyardBuildingID then
                -- 造船厂
                cmd4city.procDockyardBuildShip(b)
            end
        end

        if v.attrid == 1 then
            -- 说明是主基地
            headquarters = b
        end
        cmd4city.placeBuilding(b)
    end
end

cmd4city.getSelfBuildings = function()
    if myself == nil then
        printe("[cmd4city.getSelfBuildings]:the city data is nil")
        return nil
    end
    return buildings
end

cmd4city.getSelfBuilding = function(idx)
    -- 取得建筑
    if myself == nil then
        printe("主城为空")
        return nil
    end
    if buildings == nil then
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

local getResTypeByBuildingAttrID = function(attrid)
    local resType
    if attrid == 6 or attrid == 7 then
        resType = IDConstVals.ResType.food
    elseif attrid == 8 or attrid == 9 then
        resType = IDConstVals.ResType.oil
    elseif attrid == 10 or attrid == 11 then
        resType = IDConstVals.ResType.gold
    end
    return resType
end

---@class _ParamResInfor
---@field public type number IDConstVals.ResType
---@field stored number 当前存储的量
---@field maxstore number 最大存储量

---@public 取得某种资源的信息
---@param resType IDConstVals.ResType
---@return _ParamResInfor
cmd4city.getResInforByType = function(resType)
    local attrid = 0
    local hadRes = 0 -- 已有资源
    local maxstore = 0
    if resType == IDConstVals.ResType.food then
        attrid = IDConstVals.foodStorageBuildingID
        hadRes = headquarters:get_val()
    elseif resType == IDConstVals.ResType.gold then
        attrid = IDConstVals.goldStorageBuildingID
        hadRes = headquarters:get_val2()
    elseif resType == IDConstVals.ResType.oil then
        attrid = IDConstVals.oildStorageBuildingID
        hadRes = headquarters:get_val3()
    end
    if attrid > 0 then
        local _, stored, _maxstore = cmd4city.getStoreBuildings(attrid)
        hadRes = hadRes + stored
        maxstore = _maxstore + IDConstVals.baseRes
    end
    return {type = resType, stored = hadRes, maxstore = maxstore}
end

---@public 取得仓库建筑列表
---@param attrid 建筑配置id
---@return list 建筑列表
---@return totalStore 总存储量
---@return maxStore 最大存储空间
cmd4city.getStoreBuildings = function(attrid)
    ---@type dbbuilding
    local b, list, totalStore, attr, maxStore, emptySpace
    list = {}
    totalStore = 0
    maxStore = 0
    emptySpace = 0
    for k, v in pairs(buildings) do
        b = v
        if b:get_attrid() == attrid then
            table.insert(list, v)
            totalStore = totalStore + b:get_val()

            if attr == nil then
                attr = cfgUtl.getBuildingByID(b:get_attrid())
            end
            maxStore =
                maxStore +
                cfgUtl.getGrowingVal(attr.ComVal1Min, attr.ComVal1Max, attr.ComVal1Curve, b:get_lev() / attr.MaxLev)
        end
    end

    return list, totalStore, maxStore
end

---@public 处理其中一种资源变化
local consumeOneRes = function(val, list)
    ---@type dbbuilding
    local b
    local attr, maxStore, tmpval
    if val ~= 0 then
        for i, v in ipairs(list) do
            b = v
            tmpval = b:get_val() - val
            if tmpval < 0 then
                -- 通知服务器建筑有变化，已经增加了触发器
                --cmd4city.CMD.onBuildingChg(b:value2copy())
                -- 说明是扣除
                b:set_val(0)
                val = -tmpval
            else
                -- 说明是存储
                if attr == nil then
                    attr = cfgUtl.getBuildingByID(b:get_attrid())
                end
                maxStore =
                    cfgUtl.getGrowingVal(attr.ComVal1Min, attr.ComVal1Max, attr.ComVal1Curve, b:get_lev() / attr.MaxLev)
                if tmpval > maxStore then
                    -- 通知服务器建筑有变化，已经增加了触发器
                    --cmd4city.CMD.onBuildingChg(b:value2copy())
                    b:set_val(maxStore)
                    val = maxStore - tmpval
                else
                    b:set_val((tmpval))
                    -- 通知服务器建筑有变化，已经增加了触发器
                    --cmd4city.CMD.onBuildingChg(b:value2copy())
                    break
                end
            end
        end
    end
end

---@public 处理主基地的资源
cmd4city.consumeRes4Base = function(food, gold, oil)
    local val = food
    if val ~= 0 then
        local tmpval = headquarters:get_val() - val
        if tmpval < 0 then
            -- 说明是扣除
            headquarters:set_val(0)
            val = -tmpval
        else
            -- 说明是存储
            if tmpval > IDConstVals.baseRes then
                headquarters:set_val(IDConstVals.baseRes)
                val = IDConstVals.baseRes - tmpval
            else
                headquarters:set_val((tmpval))
                val = 0
            end
        end
    end
    food = val
    ------------------------------------------
    val = gold
    if val ~= 0 then
        local tmpval = headquarters:get_val2() - val
        if tmpval < 0 then
            -- 说明是扣除
            headquarters:set_val2(0)
            val = -tmpval
        else
            -- 说明是存储
            if tmpval > IDConstVals.baseRes then
                headquarters:set_val2(IDConstVals.baseRes)
                val = IDConstVals.baseRes - tmpval
            else
                headquarters:set_val2((tmpval))
                val = 0
            end
        end
    end
    gold = val
    ------------------------------------------
    val = oil
    if val ~= 0 then
        local tmpval = headquarters:get_val3() - val
        if tmpval < 0 then
            -- 说明是扣除
            headquarters:set_val3(0)
            val = -tmpval
        else
            -- 说明是存储
            if tmpval > IDConstVals.baseRes then
                headquarters:set_val3(IDConstVals.baseRes)
                val = IDConstVals.baseRes - tmpval
            else
                headquarters:set_val3((tmpval))
                val = 0
            end
        end
    end
    oil = val

    -- 通知服务器建筑有变化，已经增加了触发器
    -- cmd4city.CMD.onBuildingChg(headquarters:value2copy())
    ------------------------------------------
    return food, gold, oil
end

cmd4city.consumeRes2 = function(data)
    if data == nil then
        return
    end
    local food = data[IDConstVals.ResType.food] or 0
    local oil = data[IDConstVals.ResType.oil] or 0
    local gold = data[IDConstVals.ResType.gold] or 0
    cmd4city.consumeRes(food, gold, oil)
end

---@public 消耗资源。注意：负数时就是增加资源
---@param food 粮
---@param gold 金
---@param oil 油
---@return boolean 是否扣除成功
cmd4city.consumeRes = function(food, gold, oil)
    local list1, total1 = cmd4city.getStoreBuildings(IDConstVals.foodStorageBuildingID)
    if food > total1 + headquarters:get_val() then
        return false, Errcode.resNotEnough
    end

    local list2, total2 = cmd4city.getStoreBuildings(IDConstVals.goldStorageBuildingID)
    if gold > total2 + headquarters:get_val2() then
        return false, Errcode.resNotEnough
    end

    local list3, total3 = cmd4city.getStoreBuildings(IDConstVals.oildStorageBuildingID)
    if oil > total3 + headquarters:get_val3() then
        return false, Errcode.resNotEnough
    end
    food, gold, oil = cmd4city.consumeRes4Base(food, gold, oil)
    consumeOneRes(food, list1)
    consumeOneRes(gold, list2)
    consumeOneRes(oil, list3)
    return true
end

---@public 最大的工人数
cmd4city.maxtimerQueue = function()
    if headquarters == nil then
        return 1
    end
    local headquartersOpen = cfgUtl.getHeadquartersLevsByID(headquarters:get_lev())
    return headquartersOpen.Workers
end

---@public 当建筑升级完成时
---@param b dbbuilding
cmd4city.onFinishBuildingUpgrade = function(b)
    --移除升级队列
    timerQueue.removetimerQueue(b)
    local v = {}
    v[dbbuilding.keys.state] = IDConstVals.BuildingState.normal
    v[dbbuilding.keys.lev] = b:get_lev() + 1
    v[dbbuilding.keys.starttime] = b:get_endtime()
    b:refreshData(v) -- 这样处理的目的是保证不会多次触发通知客户端

    -- 通知客户端
    CMD.onBuildingChg(b:value2copy(), "onFinishBuildingUpgrade")
end

---@public 当完成造船时
---@param b dbbuilding
---@param shipAttrid number 舰船的配置id
---@param num number 已经造好的船的数量
cmd4city.onChgShipInDockyard = function(b, shipAttrid, num)
    local shipsMap
    local ships = dbunit.getListBybidx(b:get_idx())
    local isRemoved = false
    ---@type dbunit
    local unit = nil
    for i, v in ipairs(ships) do
        if v[dbunit.keys.id] == shipAttrid then
            unit = dbunit.instanse(v[dbunit.keys.idx])
            unit:set_num(unit:get_num() + num)
            if unit:get_num() <= 0 then
                isRemoved = true
                unit:delete()
            end
            break
        end
    end
    if unit == nil and (not isRemoved) then
        local ship = {}
        ship[dbunit.keys.idx] = DBUtl.nextVal("unit")
        ship[dbunit.keys.id] = shipAttrid
        ship[dbunit.keys.bidx] = b:get_idx()
        ship[dbunit.keys.num] = num
        unit = dbunit.new(ship)
    end

    -- 通知客户端
    CMD.onDockyardShipsChg(b:get_idx(), shipAttrid, num)
    if not (unit:isEmpty() or isRemoved) then
        unit:release()
    end
end

---@public 处理造船厂建造舰船的逻辑
---@param b dbbuilding
cmd4city.procDockyardBuildShip = function(b)
    if b:get_state() == IDConstVals.BuildingState.working then
        local roleAttrId = b:get_val()
        local num = b:get_val2()
        if roleAttrId <= 0 or num <= 0 then
            local data = {}
            data[dbbuilding.keys.val] = 0
            data[dbbuilding.keys.val2] = 0
            data[dbbuilding.keys.val3] = 0
            data[dbbuilding.keys.starttime] = b:get_endtime()
            data[dbbuilding.keys.state] = IDConstVals.BuildingState.normal
            b:refreshData(data)
            return
        end
        local attr = cfgUtl.getRoleByID(roleAttrId)
        -- 建船时间
        local BuildTimeS = attr.BuildTimeS / 10
        local starttime = b:get_val3() -- 保存的是上次造船的开始时间
        local diffSec = (dateEx.nowMS() - starttime) / 1000
        local finishBuildNum = numEx.getIntPart(diffSec / BuildTimeS)
        if finishBuildNum > 0 then
            if finishBuildNum >= num then
                -- 说明全部已经完成
                finishBuildNum = num
                local data = {}
                data[dbbuilding.keys.val] = 0
                data[dbbuilding.keys.val2] = 0
                data[dbbuilding.keys.val3] = 0
                data[dbbuilding.keys.starttime] = b:get_endtime()
                data[dbbuilding.keys.state] = IDConstVals.BuildingState.normal
                b:refreshData(data)
            else
                local leftSec = diffSec % BuildTimeS
                local data = {}
                data[dbbuilding.keys.val2] = b:get_val2() - finishBuildNum
                data[dbbuilding.keys.val3] = dateEx.nowMS() - numEx.getIntPart(leftSec * 1000)
                b:refreshData(data)
            end
            cmd4city.onChgShipInDockyard(b, roleAttrId, finishBuildNum)
        end

        if b:get_state() == IDConstVals.BuildingState.working then
            timerQueue.addShipQueue(b, BuildTimeS, cmd4city.procDockyardBuildShip)
        else
            timerQueue.removeShipQueue(b)
        end
    end
end

-- 释放数据
cmd4city.release = function()
    -- 队列释放
    timerQueue.release()

    ---@type dbbuilding
    local b
    for k, v in pairs(buildings) do
        b = v
        b:unsetTrigger(skynet.self(), "onBuildingChg")
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
        myself:unsetTrigger(skynet.self(), "onMyselfCityChg")
        myself:release()
        myself = nil
    end
    gridState4Tile = {}
    gridState4Building = {}
end

cmd4city.isEditMode = function()
    if skynet.address(agent) ~= nil then
        local playerserver = skynet.call(agent, "lua", "getLogic", "cmd4player")
        return skynet.call(playerserver, "lua", "getEditMode")
    end
    return false
end

---@public 取得所有的舰船数据
cmd4city.getAllShips = function()
    local shipList = {}
    ---@param building dbbuilding
    for idx, building in pairs(buildings) do
        if building:get_attrid() == IDConstVals.dockyardBuildingID then
            local shipMap = cmd4city.getShipsInDockyard(idx)
            if shipMap then
                table.insert(shipList, shipMap)
            end
        end
    end
    return shipList
end

---@public 取得等级
cmd4city.getLev = function()
    return cmd4city.getCityLev()
end
---@public 取得造船厂的舰船数据
---@return NetProtoIsland.ST_dockyardShips
cmd4city.getShipsInDockyard = function(buildingIdx)
    ---@type dbbuilding
    local b = buildings[buildingIdx] -- 不要使用new(), 或者instance()，也不能直接传data
    if b == nil then
        return nil
    end
    ---@type NetProtoIsland.ST_dockyardShips
    local dockyardShips = {}
    dockyardShips.buildingIdx = buildingIdx
    dockyardShips.ships = dbunit.getListBybidx(b:get_idx())
    return dockyardShips
end

---@从造舰厂里扣除舰船
cmd4city.deductShipsInDockyard = function(attrid, num)
    local shipList = cmd4city.getAllShips()
    local cutList = {}
    local doDeduct = function()
        for i, v in ipairs(cutList) do
            cmd4city.onChgShipInDockyard(buildings[v.bid], v.shipid, -v.num)
        end
    end

    ---@param v NetProtoIsland.ST_dockyardShips
    for i, v in ipairs(shipList) do
        ---@param unit NetProtoIsland.ST_unitInfor
        for j, unit in ipairs(v.ships) do
            if unit.id == attrid then
                if unit.num >= num then
                    table.insert(cutList, {bid = v.buildingIdx, shipid = attrid, num = num})
                    doDeduct()
                    return true
                else
                    num = num - unit.num
                    table.insert(cutList, {bid = v.buildingIdx, shipid = attrid, num = unit.num})
                end
            end
        end
    end
    -- 说明在for里都没有扣除完舰船，返回flase
    return false
end
--＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝
--＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝
--＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝
CMD.new = function(idx, _agent)
    agent = _agent
    ---@type dbcity
    local city = cmd4city.new(idx)
    if city then
        return city:value2copy()
    end
    return nil
end
CMD.getSelf = function(idx, _agent)
    agent = _agent
    local city = cmd4city.getSelf(idx)
    if city then
        return city:value2copy()
    end

    return nil
end
CMD.getSelfTiles = function()
    local tiles = cmd4city.getSelfTiles()
    if tiles then
        local tiles2 = {}
        for k, v in pairs(tiles) do
            tiles2[k] = v:value2copy()
        end
        return tiles2
    end
    return nil
end
CMD.getSelfBuildings = function()
    local buildings = cmd4city.getSelfBuildings()
    if buildings then
        local buildings2 = {}
        for k, v in pairs(buildings) do
            buildings2[k] = v:value2copy()
        end
        return buildings2
    end
    return nil
end
CMD.newBuilding = function(m, fd)
    -- 新建筑
    local cmd = "newBuilding"
    local ret = {}
    if myself == nil then
        printe("主城数据为空！")
        ret.code = Errcode.error
        ret.msg = "主城数据为空"
        return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, nil, m)
    end

    -- 是否有空闲队列
    if #(timerQueue.build) >= cmd4city.maxtimerQueue() then
        ret.code = Errcode.noIdelQueue
        ret.msg = "没有空闲队列"
        return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, nil, m)
    end

    if not cmd4city.canPlace(m.pos, true) then
        printe("该位置不能放置建筑！pos==" .. m.pos)
        ret.code = Errcode.error
        ret.msg = "该位置不能放置建筑"
        return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, nil, m)
    end

    local attrid = m.attrid
    local attr = cfgUtl.getBuildingByID(attrid)
    local persent = 1 / attr.MaxLev

    local isEditMode = cmd4city.isEditMode()
    if not isEditMode then
        -- 扣除资源
        local food =
            cfgUtl.getGrowingVal(attr.BuildCostFoodMin, attr.BuildCostFoodMax, attr.BuildCostFoodCurve, persent)
        local gold =
            cfgUtl.getGrowingVal(attr.BuildCostGoldMin, attr.BuildCostGoldMax, attr.BuildCostGoldCurve, persent)
        local oil = cfgUtl.getGrowingVal(attr.BuildCostOilMin, attr.BuildCostOilMax, attr.BuildCostOilCurve, persent)
        local succ, code = cmd4city.consumeRes(food, gold, oil)
        if not succ then
            ret.code = code
            ret.msg = "资源不足"
            return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, nil, m)
        end
    end

    local building = cmd4city.newBuilding(m.attrid, m.pos, myself:get_idx())
    if building == nil then
        printe("新建建筑失败")
        ret.code = Errcode.error
        ret.msg = "新建建筑失败"
        return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, nil, m)
    end

    -- 设置冷却时间
    local sec = cfgUtl.getGrowingVal(attr.BuildTimeMin * 60, attr.BuildTimeMax * 60, attr.BuildTimeCurve, persent)
    if sec > 0 then
        local endTime = numEx.getIntPart(dateEx.nowMS() + sec * 1000)
        local _v = {
            [dbbuilding.keys.starttime] = dateEx.nowMS(),
            [dbbuilding.keys.endtime] = endTime,
            [dbbuilding.keys.state] = IDConstVals.BuildingState.upgrade
        }
        building:refreshData(_v)
        timerQueue.addtimerQueue(building, cmd4city.onFinishBuildingUpgrade)
    end

    buildings[building:get_idx()] = building

    ret.code = Errcode.ok
    return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, building:value2copy(), m)
end
CMD.getBuilding = function(m, fd, agent)
    -- 取得建筑
    local ret = {}
    local b = cmd4city.getSelfBuilding(m.idx)
    if b == nil then
        ret.code = Errcode.error
        ret.msg = "取得建筑为空"
        return skynet.call(NetProtoIsland, "lua", "send", "getBuilding", ret, nil, m)
    end
    ret.code = Errcode.ok
    return skynet.call(NetProtoIsland, "lua", "send", "getBuilding", ret, b:value2copy(), m)
end
CMD.moveTile = function(m, fd, agent)
    -- 移动地块
    local ret = {}
    ---@type dbtile
    local t = cmd4city.getSelfTile(m.idx)
    if t == nil then
        ret.code = Errcode.error
        ret.msg = "取得地块为空"
        return skynet.call(NetProtoIsland, "lua", "send", "moveTile", ret, nil, m)
    end
    cmd4city.unPlaceTile(t)
    t:set_pos(m.pos)
    cmd4city.placeTile(t)
    ret.code = Errcode.ok
    return skynet.call(NetProtoIsland, "lua", "send", "moveTile", ret, t:value2copy(), m)
end
CMD.moveBuilding = function(m, fd, agent)
    -- 移动建筑
    local ret = {}
    ---@type dbbuilding
    local b = cmd4city.getSelfBuilding(m.idx)
    if b == nil then
        ret.code = Errcode.error
        ret.msg = "取得建筑为空"
        return skynet.call(NetProtoIsland, "lua", "send", "moveBuilding", ret, nil, m)
    end
    -- 先释放之前的网格状态
    cmd4city.unPlaceBuilding(b)
    b:set_pos(m.pos)
    -- 设置新的网格的状态
    cmd4city.placeBuilding(b)
    ret.code = Errcode.ok
    return skynet.call(NetProtoIsland, "lua", "send", "moveBuilding", ret, b:value2copy(), m)
end
CMD.upLevBuilding = function(m, fd, agent)
    -- 建筑升级
    local ret = {}
    local cmd = "upLevBuilding"
    local b = cmd4city.getSelfBuilding(m.idx)
    if b == nil then
        ret.code = Errcode.buildingIsNil
        ret.msg = "取得建筑为空"
        return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, nil, m)
    end

    if b:get_state() ~= IDConstVals.BuildingState.normal then
        ret.code = Errcode.buildingNotIdel
        ret.msg = "取得建筑不是空闲"
        return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, nil, m)
    end

    -- 是否有空闲队列
    if #(timerQueue.build) >= cmd4city.maxtimerQueue() then
        ret.code = Errcode.noIdelQueue
        ret.msg = "没有空闲队列"
        return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, nil, m)
    end

    --check max lev
    local attrid = b:get_attrid()
    local attr = cfgUtl.getBuildingByID(attrid)
    local maxLev = attr.MaxLev
    if b:get_lev() >= maxLev then
        ret.code = Errcode.outOfMaxLev
        ret.msg = "已经是最高等级"
        return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, nil, m)
    end

    -- 非主基地时，基它建筑要不能超过主基地
    if b:get_attrid() ~= IDConstVals.headquartersBuildingID then
        if b:get_lev() >= headquarters:get_lev() then
            ret.code = Errcode.exceedHeadquarters
            ret.msg = "不能超过主基地等级"
            return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, nil, m)
        end
    end

    local persent = (b:get_lev() + 1) / attr.MaxLev

    -- 如果是编辑模式，则不扣处资源
    local isEditMode = cmd4city.isEditMode()
    if not isEditMode then
        -- 扣除资源
        local food =
            cfgUtl.getGrowingVal(attr.BuildCostFoodMin, attr.BuildCostFoodMax, attr.BuildCostFoodCurve, persent)
        local gold =
            cfgUtl.getGrowingVal(attr.BuildCostGoldMin, attr.BuildCostGoldMax, attr.BuildCostGoldCurve, persent)
        local oil = cfgUtl.getGrowingVal(attr.BuildCostOilMin, attr.BuildCostOilMax, attr.BuildCostOilCurve, persent)
        local succ, code = cmd4city.consumeRes(food, gold, oil)
        if not succ then
            ret.code = code
            ret.msg = "资源不足"
            return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, nil, m)
        end
    end

    -- 设置冷却时间
    local sec = cfgUtl.getGrowingVal(attr.BuildTimeMin * 60, attr.BuildTimeMax * 60, attr.BuildTimeCurve, persent)
    if sec > 0 then
        local endTime = numEx.getIntPart(dateEx.nowMS() + sec * 1000)
        local v = {
            [dbbuilding.keys.starttime] = dateEx.nowMS(),
            [dbbuilding.keys.endtime] = endTime,
            [dbbuilding.keys.state] = IDConstVals.BuildingState.upgrade
        }
        b:refreshData(v)
        timerQueue.addtimerQueue(b, cmd4city.onFinishBuildingUpgrade)
    else
        b:set_lev(b:get_lev() + 1)
    end

    -- 通知服务器建筑有变化,已经加了触发器不需要主动再通知
    --cmd4city.CMD.onBuildingChg(b:value2copy())
    ret.code = Errcode.ok

    return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, b:value2copy(), m)
end
CMD.upLevBuildingImm = function(m, fd, agent)
    -- 立即完成升级
    local cmd = m.cmd

    local ret = {}
    ---@type dbbuilding
    local b = cmd4city.getSelfBuilding(m.idx)
    if b == nil then
        ret.code = Errcode.error
        ret.msg = "取得建筑为空"
        return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, m)
    end

    --check max lev
    local attrid = b:get_attrid()
    local attr = cfgUtl.getBuildingByID(attrid)
    local maxLev = attr.MaxLev
    if b:get_lev() >= maxLev then
        ret.code = Errcode.outOfMaxLev
        ret.msg = "已经是最高等级"
        return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, m)
    end

    -- 非主基地时，基它建筑要不能超过主基地
    if b:get_attrid() ~= IDConstVals.headquartersBuildingID then
        if b:get_lev() >= headquarters:get_lev() then
            ret.code = Errcode.exceedHeadquarters
            ret.msg = "不能超过主基地等级"
            return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, m)
        end
    end

    -- 看建筑状态
    local leftMinutes = 0
    local needDiam = 0
    if b:get_state() == IDConstVals.BuildingState.upgrade then
        -- 正在升级
        leftMinutes = (b:get_endtime() - dateEx.nowMS()) / 60000
        leftMinutes = math.ceil(leftMinutes)
        needDiam = cfgUtl.minutes2Diam(leftMinutes)
    elseif b:get_state() == IDConstVals.BuildingState.normal then
        -- 空闲状态
        local persent = (b:get_lev() + 1) / attr.MaxLev
        leftMinutes = cfgUtl.getGrowingVal(attr.BuildTimeMin, attr.BuildTimeMax, attr.BuildTimeCurve, persent)
        leftMinutes = math.ceil(leftMinutes)
        needDiam = cfgUtl.minutes2Diam(leftMinutes)

        local food =
            cfgUtl.getGrowingVal(attr.BuildCostFoodMin, attr.BuildCostFoodMax, attr.BuildCostFoodCurve, persent)
        local gold =
            cfgUtl.getGrowingVal(attr.BuildCostGoldMin, attr.BuildCostGoldMax, attr.BuildCostGoldCurve, persent)
        local oil = cfgUtl.getGrowingVal(attr.BuildCostOilMin, attr.BuildCostOilMax, attr.BuildCostOilCurve, persent)
        needDiam = needDiam + cfgUtl.res2Diam(food + gold + oil)
    else
        ret.code = Errcode.buildingIsBusy
        ret.msg = "建筑正忙，不可操作"
        return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, m)
    end
    local isEditMode = cmd4city.isEditMode()
    if needDiam > 0 and (not isEditMode) then
        local pidx = myself:get_pidx()
        ---@type dbplayer
        local player = dbplayer.instanse(pidx)
        if player == nil then
            ret.code = Errcode.playerIsNil
            ret.msg = "玩家数据取得为空"
            return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, m)
        end
        if player:get_diam() < needDiam then
            ret.code = Errcode.diamNotEnough
            ret.msg = "钻石不足"
            return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, m)
        end
        -- 扣除钻石
        player:set_diam(player:get_diam() - needDiam)
        player:release()
        player = nil
    end
    b:set_endtime(dateEx.nowMS())
    cmd4city.onFinishBuildingUpgrade(b)
    ret.code = Errcode.ok
    return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, m)
end

CMD.newTile = function(m, fd, agent)
    -- 扩建地块
    local cmd = "newTile"
    local ret = {}
    if myself == nil then
        printe("主城数据为空！")
        ret.code = Errcode.error
        ret.msg = "主城数据为空"
        return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, nil, m)
    end

    if not cmd4city.canPlace(m.pos, false) then
        printe("该位置不能放置地块！pos==" .. m.pos)
        ret.code = Errcode.error
        ret.msg = "该位置不能放置地块"
        return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, nil, m)
    end

    local headquartersOpen = cfgUtl.getHeadquartersLevsByID(headquarters:get_lev())
    local maxNum = headquartersOpen.Tiles
    if hadTileCount >= maxNum then
        ret.code = Errcode.maxNumber
        ret.msg = "地块数量已经达上限"
        return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, nil, m)
    end

    local constcfg = cfgUtl.getConstCfg()
    -- 扣除资源
    local persent = hadTileCount / constcfg.TilesTotal
    local food =
        cfgUtl.getGrowingVal(constcfg.ExtenTileCostMin, constcfg.ExtenTileCostMax, constcfg.ExtenTileCostCurve, persent)
    local succ, code = cmd4city.consumeRes(food, 0, 0)
    if not succ then
        ret.code = code
        ret.msg = "资源不足"
        return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, nil, m)
    end

    local tile, code = cmd4city.newTile(m.pos, 0, myself:get_idx())
    if tile == nil then
        ret.code = code
        ret.msg = "新建地块失败"
        return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, nil, m)
    end

    ret.code = Errcode.ok
    return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, tile:value2copy(), m)
end
CMD.rmTile = function(m, fd, agent)
    local ret = {}
    ret.code = cmd4city.delSelfTile(m.idx)
    return skynet.call(NetProtoIsland, "lua", "send", "rmTile", ret, m.idx, m)
end
CMD.rmBuilding = function(m, fd, agent)
    local ret = {}
    ret.code = cmd4city.delSelfBuilding(m.idx)
    return skynet.call(NetProtoIsland, "lua", "send", "rmBuilding", ret, m.idx, m)
end
---@public 收集资源
CMD.collectRes = function(m, fd, agent)
    local cmd = m.cmd
    local idx = m.idx
    local ret = {}
    ---@type dbbuilding
    local b = buildings[idx] -- 不要使用new(), 或者instance()，也不能直接传data
    if b == nil then
        ret.code = Errcode.buildingIsNil
        ret.msg = "取得建筑为空"
        return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, nil, nil, nil, m)
    end

    local attrid = b:get_attrid()
    local resType = getResTypeByBuildingAttrID(attrid)
    if resType == nil then
        ret.code = Errcode.buildingIsNotResFactory
        ret.msg = "不是资源建筑，不可操作"
        return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, nil, nil, nil, m)
    end

    local val = 0
    if b:get_state() == IDConstVals.BuildingState.normal then
        local proTime = dateEx.nowMS() - (b:get_starttime() or 0)
        proTime = numEx.getIntPart(proTime / 60000)
        -- 转成分钟
        if proTime > 0 then
            local constcfg = cfgUtl.getConstCfg()
            -- 判断时长是否超过最大生产时长(目前配置的时最大只可生产8小时产量)
            if proTime > constcfg.MaxTimeLen4ResYields then
                proTime = constcfg.MaxTimeLen4ResYields
            end

            local attr = cfgUtl.getBuildingByID(attrid)
            local maxLev = attr.MaxLev
            local persent = b:get_lev() / maxLev
            -- 每分钟产量
            local yieldsPerMinutes = cfgUtl.getGrowingVal(attr.ComVal1Min, attr.ComVal1Max, attr.ComVal1Curve, persent)
            val = yieldsPerMinutes * proTime
            -- 判断仓库空间能否装下
            local resinfor = cmd4city.getResInforByType(resType)
            local emptySpace = resinfor.maxstore - resinfor.stored
            if val > emptySpace then
                --说明空间不够了,看超出了多少，如果只超出了一点点，也可以收集
                local outPrent = (val - emptySpace) / val
                if outPrent > 0.2 then
                    ret.code = Errcode.storeNotEnough
                    ret.msg = "仓库空间不足"
                    return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, nil, nil, nil, m)
                end
                -- 只能存储剩余的空间
                val = emptySpace
            end

            cmd4city.consumeRes2({[resType] = -val}) --负数就是增加资源
            b:refreshData(
                {
                    [dbbuilding.keys.starttime] = dateEx.nowMS(),
                    [dbbuilding.keys.endtime] = dateEx.nowMS()
                }
            )
        end
    end

    ret.code = Errcode.ok
    return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, resType, val, b:value2copy(), m)
end

---@public 建造舰船
---@param map NetProtoIsland.RC_buildShip
CMD.buildShip = function(map, fd, agent)
    local ret = {}
    local cmd = map.cmd
    local buildingIdx = map.buildingIdx
    local shipAttrID = map.shipAttrID
    local num = map.num
    ---@type dbbuilding
    local b = buildings[buildingIdx] -- 不要使用new(), 或者instance()，也不能直接传data
    if b == nil then
        ret.code = Errcode.buildingIsNil
        ret.msg = "取得建筑为空"
        return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, nil, map)
    end
    if b:get_state() ~= IDConstVals.BuildingState.normal then
        ret.code = Errcode.buildingIsBusy
        ret.msg = "建筑状态不是空闲"
        return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, nil, map)
    end
    if num <= 0 then
        ret.code = Errcode.numError
        ret.msg = "数量必须大于0"
        return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, nil, map)
    end
    local roleAttr = cfgUtl.getRoleByID(shipAttrID)
    if roleAttr == nil then
        ret.code = Errcode.cfgIsNil
        ret.msg = "舰船配置取得为空"
        return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, nil, map)
    end
    -----------------------------------------------
    -- 是否解锁
    local needDockyardLev = roleAttr.ArsenalLev
    if needDockyardLev > b:get_lev() then
        ret.code = Errcode.shipIsLocked
        ret.msg = "舰船未解锁"
        return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, nil, map)
    end
    -----------------------------------------------
    -- 空间是否够
    local buildingAttr = cfgUtl.getBuildingByID(b:get_attrid())
    local totalSpace =
        cfgUtl.getGrowingVal(
        buildingAttr.ComVal1Min,
        buildingAttr.ComVal1Max,
        buildingAttr.ComVal1Curve,
        b:get_lev() / buildingAttr.MaxLev
    )
    -- 取得已经有的数量
    local usedSpace = 0
    local shipsList = dbunit.getListBybidx(b:get_idx())
    local _attr
    ---@param v dbunit
    for i, v in ipairs(shipsList) do
        _attr = cfgUtl.getRoleByID(v[dbunit.keys.id])
        usedSpace = usedSpace + v[dbunit.keys.num] * _attr.SpaceSize
    end
    if num * roleAttr.SpaceSize > (totalSpace - usedSpace) then
        ret.code = Errcode.dockyardSpaceNotEnough
        ret.msg = "船坞空间不足"
        return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, nil, map)
    end

    -----------------------------------------------
    -- 如果是编辑模式，则不扣处资源
    local isEditMode = cmd4city.isEditMode()
    if not isEditMode then
        -- 扣除资源
        local BuildRscType = roleAttr.BuildRscType
        local BuildCost = roleAttr.BuildCost
        local resInfor = {}
        resInfor[BuildRscType] = BuildCost
        local succ, code = cmd4city.consumeRes2(resInfor)
        if not succ then
            ret.code = code
            ret.msg = "资源不足"
            return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, nil, map)
        end
    end

    -- 建造时间
    local BuildTimeS = roleAttr.BuildTimeS / 10
    local totalSec = BuildTimeS * num

    -- 更新建筑数据
    local data = {}
    data[dbbuilding.keys.val] = shipAttrID
    data[dbbuilding.keys.val2] = num
    data[dbbuilding.keys.val3] = dateEx.nowMS() -- 用于计算用
    data[dbbuilding.keys.starttime] = dateEx.nowMS()
    data[dbbuilding.keys.endtime] = numEx.getIntPart(dateEx.nowMS() + totalSec * 1000)
    data[dbbuilding.keys.state] = IDConstVals.BuildingState.working
    b:refreshData(data)

    -- 添加造兵队列
    cmd4city.procDockyardBuildShip(b)

    ret.code = Errcode.ok
    return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, b:value2copy(), map)
end
---@public 取得造船厂所有舰艇列表
CMD.getShipsByBuildingIdx = function(map, fd, agent)
    local ret = {}
    local cmd = map.cmd
    local buildingIdx = map.buildingIdx
    ---@type dbbuilding
    local b = buildings[buildingIdx] -- 不要使用new(), 或者instance()，也不能直接传data
    if b == nil then
        -- 说明是客户端请求
        ret.code = Errcode.buildingIsNil
        ret.msg = "取得建筑为空"
        return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, nil, map)
    end

    ---@type NetProtoIsland.ST_dockyardShips
    local dockyardShips = cmd4city.getShipsInDockyard(buildingIdx)
    ret.code = Errcode.ok
    return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, dockyardShips, map)
end

CMD.onBuildingChg = function(data, cmd)
    -- 当建筑数据有变化，这个接口是内部触发的
    cmd = cmd or "onBuildingChg"
    if data then
        local idx = data.idx
        ---@type dbbuilding
        local b = buildings[idx] -- 不要使用new(), 或者instance()，也不能直接传data
        if b then
            local ret = {}
            ret.code = Errcode.ok
            local package = skynet.call(NetProtoIsland, "lua", "send", cmd, ret, b:value2copy())
            if skynet.address(agent) ~= nil then
                skynet.call(agent, "lua", "sendPackage", package)
            end
        end
    end
end

---@public 当造船厂的舰艇数量发化变化时
CMD.onDockyardShipsChg = function(bidx, shipAttrid, num)
    local cmd = ""
    local ret = {}
    ret.code = Errcode.ok

    ---@type dbbuilding
    local b = buildings[bidx] -- 不要使用new(), 或者instance()，也不能直接传data
    ---@type NetProtoIsland.ST_dockyardShips
    local dockyardShips = {}
    dockyardShips.buildingIdx = bidx
    dockyardShips.ships = dbunit.getListBybidx(b:get_idx())

    -- 推送给客户端
    cmd = "getShipsByBuildingIdx"
    local package = skynet.call(NetProtoIsland, "lua", "send", cmd, ret, dockyardShips)
    if skynet.address(agent) ~= nil then
        skynet.call(agent, "lua", "sendPackage", package)
    end

    if num > 0 then
        -- 推送给客户端
        cmd = "onFinishBuildOneShip"
        package = skynet.call(NetProtoIsland, "lua", "send", cmd, ret, bidx, shipAttrid, num)
        if skynet.address(agent) ~= nil then
            skynet.call(agent, "lua", "sendPackage", package)
        end
    end
end

CMD.onMyselfCityChg = function(data)
    local cmd = "onMyselfCityChg"
    local ret = {}
    ret.code = Errcode.ok
    local package = skynet.call(NetProtoIsland, "lua", "send", cmd, ret, myself:value2copy())
    if skynet.address(agent) ~= nil then
        skynet.call(agent, "lua", "sendPackage", package)
    end
end
-----------------------------------------------------
skynet.start(
    function()
        constCfg = cfgUtl.getConstCfg()
        gridSize = constCfg.GridCity
        grid = Grid.new()
        grid:init(Vector3.zero, gridSize, gridSize, cellSize)

        skynet.dispatch(
            "lua",
            function(_, _, command, ...)
                local f = CMD[command] or cmd4city[command]
                if f == nil then
                    error("func is nill.cmd =" .. command)
                else
                    skynet.ret(skynet.pack(f(...)))
                end
            end
        )
    end
)
