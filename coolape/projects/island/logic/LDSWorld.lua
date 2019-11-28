-- 世界地图网格
local skynet = require "skynet"
require "skynet.manager" -- import skynet.register
require("public.include")
require("Errcode")
---@type Grid
require("Grid")
require("public.cfgUtl")
require("numEx")
require("db.dbworldmap")
require("db.dbcity")
require("db.dbplayer")
require("logic.IDConstVals")

local constCfg  -- 常量配置
---@type Grid
local grid
local gridSize  -- 网格size
local screenSize = 10 -- 大地图一屏size
local cellSize = 1
local screenCells = {} -- 每屏的网格信息
local screenCneterIndexs = {}
local currScreenOrder = 1
local NetProtoIsland = skynet.getenv("NetProtoName")

local cachePages = {}
local ConstTimeOut = 60 * 100 -- 60秒

local CMD = {}
local pauseFork = false

--取得下屏的order
--local getNextScreenOrder = function()
--    currScreenOrder = currScreenOrder + 1
--    if currScreenOrder > #screenCneterIndexs then
--        currScreenOrder = 1
--    end
--end

---@public 启动一个线程处理超时数据（//TODO:可能有多线程数据同步问题）
-- local procTimeoutData = function()
--     while (true) do
--         if not pauseFork then
--             for pageIdx, lastUseTime in pairs(cachePages) do
--                 if not pauseFork then
--                     if lastUseTime and (dateEx.nowMS() - lastUseTime > ConstTimeOut) then
--                         -- 已经超时了
--                         local list = dbworldmap.getListBypageIdx(pageIdx)
--                         if list then
--                             local cell = nil
--                             for i, v in ipairs(list) do
--                                 cell = dbworldmap.new()
--                                 cell.__key__ = v.idx
--                                 cell:release()
--                             end
--                         end
--                         cachePages[pageIdx] = nil
--                     end
--                 end
--             end
--         end
--         skynet.sleep(ConstTimeOut)
--     end
-- end

--============================================
--============================================
--=========================================
local mapBaseData = {} -- 配置数据
local mapAreaInfor  -- 大地图分区数据
-- 数据的路径
local scale = 100
---@type Grid
local gridArea

-- 加载配置数据
local function loadCfgData()
    gridArea = Grid.new()
    gridArea:init(Vector3.zero, screenSize, screenSize, scale)
    local priorityPath = assert(skynet.getenv("projectPath"))
    printe(priorityPath)
    local cfgWorldBasePath = priorityPath .. "cfgWorldmap/"
    printe(cfgWorldBasePath)
    printe(cfgWorldBasePath .. "maparea.cfg")
    local bytes = fileEx.readAll(cfgWorldBasePath .. "maparea.cfg")
    mapAreaInfor = BioUtl.readObject(bytes)

    for i = 0, 99 do
        local bytes = fileEx.readAll(cfgWorldBasePath .. i .. ".cfg")
        local map = BioUtl.readObject(bytes)
        for pageid, m in pairs(map) do
            for index, id in pairs(m) do
                mapBaseData[index] = id
            end
        end
    end
end

---@public 取得大图的index映射到分区网格的index
---@param index
local function mapIndex2AreaIndex(index)
    local areaIndex = -1
    local col = grid:GetColumn(index)
    local row = grid:GetRow(index)
    col = NumEx.getIntPart(col / scale)
    row = NumEx.getIntPart(row / scale)

    areaIndex = gridArea:GetCellIndex(col, row)
    return areaIndex
end

---@public 取得网格id对应的分区id
local function getAreaId(index)
    if mapAreaInfor == nil then
        local cfgPath = joinStr(cfgWorldBasePath, "maparea.cfg")
        local bytes = fileEx.readAll(cfgPath)
        mapAreaInfor = BioUtl.readObject(bytes)
    end
    return mapAreaInfor[index]
end
--============================================
--============================================
---@public 初始化
function CMD.init()
    local center
    local x, y
    local cells
    for i = 0, gridSize - 1, screenSize do
        for j = 0, gridSize - 1, screenSize do
            x = i + numEx.getIntPart(screenSize / 2)
            y = j + numEx.getIntPart(screenSize / 2)
            center = grid:GetCellIndex(x, y)
            cells = grid:getCells(center, screenSize)
            screenCells[center] = cells
            table.insert(screenCneterIndexs, center)
        end
    end

    -- 加载地图配置
    loadCfgData()
end

local function haveBaseData(index)
    return (mapBaseData[index] ~= nil)
end

---@public 通过网格idx取得所有屏的index
function CMD.getPageIdx(gidx)
    local pos = grid:GetCellCenter(gidx)
    pos = pos - grid.Origin

    local screen = screenSize * cellSize
    local col, row
    col = numEx.getIntPart(pos.x / screen)
    row = numEx.getIntPart(pos.z / screen)

    local x2 = col * screen + (screen / 2)
    local z2 = row * screen + (screen / 2)
    local cellPosition = grid.Origin + Vector3(x2, 0, z2)
    return grid:GetCellIndex(cellPosition)
end

---@public 取得空闲位置的index
function CMD.getIdleIdx(creenIdx)
    --if screenOrder then
    --    currScreenOrder = screenOrder
    --end
    if creenIdx == nil then
        local i = numEx.nextInt(1, #screenCneterIndexs)
        creenIdx = screenCneterIndexs[i]
    end

    local cells = screenCells[creenIdx]
    local index = numEx.nextInt(1, #cells)
    local pos = cells[index]
    local mapCell = dbworldmap.instanse(pos)
    if mapCell:isEmpty() and (not haveBaseData(index)) then
        -- 该位置是可用
        return pos
    else
        mapCell:release()
        local i = index + 1
        if i > #cells then
            i = 1
        end
        while i ~= index do
            local pos = cells[i]
            local mapCell = dbworldmap.instanse(pos)
            if mapCell:isEmpty() then
                -- 该位置是可用
                return pos
            end
            mapCell:release()
            i = i + 1
            if i > #cells then
                i = 1
            end
        end
        -- 仍然没有找到
        return CMD.getIdleIdx()
    end
end

---@public 占用一个格子
function CMD.occupyMapCell(cidx, type, attrid)
    local idx = CMD.getIdleIdx()
    local mapCell = dbworldmap.instanse(idx)
    local cellData = {}
    cellData[dbworldmap.keys.idx] = idx
    cellData[dbworldmap.keys.pageIdx] = CMD.getPageIdx(idx)
    cellData[dbworldmap.keys.cidx] = cidx or 0
    cellData[dbworldmap.keys.type] = type
    cellData[dbworldmap.keys.attrid] = attrid
    mapCell:init(cellData, true)
    local ret = mapCell:value2copy()
    mapCell:release()
    return ret
end

---@public 取得一屏数据
function CMD.getMapDataByPageIdx(map)
    pauseFork = true
    local pageIdx = map.pageIdx
    local cmd = map.cmd

    -- 先从缓存里取
    local list = dbworldmap.getListBypageIdx(pageIdx)
    -- if list == nil or cachePages[pageIdx] == nil then
    --     -- 缓存里没有，那就从数据库里取
    --     list = dbworldmap.getListBypageIdx(pageIdx)
    --     for i, v in ipairs(list) do
    --         -- 这样就会把数据先缓存起来
    --         dbworldmap.instanse(v.idx)
    --     end
    -- end
    -- 记录已经缓存了的page
    cachePages[pageIdx] = dateEx.nowMS()
    local cells = {}
    ---@param v dbworldmap
    for i, v in ipairs(list) do
        ---@type NetProtoIsland.ST_mapCell
        local cell = v
        -- 包装数据
        if v[dbworldmap.keys.cidx] > 0 and v[dbworldmap.keys.type] == IDConstVals.WorldmapCellType.user then
            local city = dbcity.instanse(v[dbworldmap.keys.cidx])
            if not city:isEmpty() then
                local pidx = city:get_pidx()
                local player = dbplayer.instanse(pidx)
                if not player:isEmpty() then
                    cell.name = player:get_name()
                    cell.lev = player:get_lev()
                    cell.state = city:get_status()
                    player:release()
                end
                city:release()
            end
        end
        table.insert(cells, cell)
    end
    ---@type NetProtoIsland.ST_mapPage
    local mapPage = {}
    mapPage.pageIdx = pageIdx
    mapPage.cells = cells
    -- skynet.error("=================" .. #list)
    pauseFork = false
    return skynet.call(NetProtoIsland, "lua", "send", cmd, {code = Errcode.ok}, mapPage, map)
end

---@public 搬迁
---@param map NetProtoIsland.RC_moveCity
function CMD.moveCity(map)
    ---@type NetProtoIsland.ST_retInfor
    local ret = {}
    local cidx = map.cidx
    local toPos = map.pos

    if not grid:IsInBounds(toPos) then
        ret.code = Errcode.notInGridBounds
        return skynet.call(NetProtoIsland, "lua", "send", map.cmd, ret, map)
    end

    local toCell = dbworldmap.instanse(toPos)
    if (not toCell:isEmpty()) or toCell:get_cidx() > 0 or haveBaseData(toPos) then
        toCell:release()
        ret.code = Errcode.worldCellNotIdel
        return skynet.call(NetProtoIsland, "lua", "send", map.cmd, ret, map)
    end

    local city = dbcity.instanse(cidx)
    if city:isEmpty() then
        ret.code = Errcode.cityIsNil
        return skynet.call(NetProtoIsland, "lua", "send", map.cmd, ret, map)
    end
    local fromPos = city:get_pos()

    local fromCell = dbworldmap.instanse(fromPos)
    if fromCell:isEmpty() or fromCell:get_cidx() <= 0 then
        fromCell:release()
        city:release()
        ret.code = Errcode.notFoundInWorld
        return skynet.call(NetProtoIsland, "lua", "send", map.cmd, ret, map)
    end
    -- 把城的坐标先修改了
    city:set_pos(toPos)

    local data = fromCell:value2copy()
    data[dbworldmap.keys.idx] = toPos
    data[dbworldmap.keys.cidx] = cidx
    data[dbworldmap.keys.pageIdx] = CMD.getPageIdx(toPos)
    -- 重新设置地块数据
    toCell:init(data, true)

    ---@type NetProtoIsland.ST_mapCell
    local d = toCell:value2copy()
    local pidx = city:get_pidx()
    local player = dbplayer.instanse(pidx)
    d.name = player:get_name()
    d.lev = player:get_lev()
    d.state = city:get_status()
    city:release()
    player:release()

    --推送给在线的客户端
    local mapcell = skynet.call(NetProtoIsland, "lua", "send", "onMapCellChg", {code = Errcode.ok}, d, false)
    skynet.call("watchdog", "lua", "notifyAll", mapcell)

    -- 旧地块也推送
    local d = fromCell:value2copy()
    d[dbworldmap.keys.cidx] = 0
    mapcell = skynet.call(NetProtoIsland, "lua", "send", "onMapCellChg", {code = Errcode.ok}, d, true)
    skynet.call("watchdog", "lua", "notifyAll", mapcell)

    -- 删除旧的地块
    fromCell:delete()
    toCell:release()
    ret.code = Errcode.ok
    return skynet.call(NetProtoIsland, "lua", "send", map.cmd, ret, map)
end

skynet.start(
    function()
        constCfg = cfgUtl.getConstCfg()
        gridSize = constCfg.GridWorld

        -- 初始化网格
        grid = Grid.new()
        grid:init(Vector3.zero, gridSize, gridSize, cellSize)

        skynet.dispatch(
            "lua",
            function(_, _, command, ...)
                local f = CMD[command]
                skynet.ret(skynet.pack(f(...)))
            end
        )

        -- 启动一个线路处理超时数据（应该有多线程数据同步问题）
        -- skynet.fork(procTimeoutData)

        skynet.register "LDSWorld"
    end
)
