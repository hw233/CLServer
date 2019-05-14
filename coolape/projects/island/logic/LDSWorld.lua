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

local constCfg  -- 常量配置
---@type Grid
local grid
local gridSize  -- 网格size
local screenSize = 10 -- 大地图一屏size
local cellSize = 1
local screenCells = {} -- 每屏的网格信息
local screenCneterIndexs = {}
local currScreenOrder = 1
local NetProtoIsland = "NetProtoIsland"

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

---@public 启动一个线路处理超时数据（//TODO:可能有多线程数据同步问题）
local procTimeoutData = function()
    while (true) do
        if not pauseFork then
            for pageIdx, lastUseTime in pairs(cachePages) do
                if not pauseFork then
                    if lastUseTime and (dateEx.nowMS() - lastUseTime > ConstTimeOut) then
                        -- 已经超时了
                        local list = skynet.call("CLDB", "lua", "GETGROUP", dbworldmap.name, pageIdx)
                        if list then
                            local cell = nil
                            for i, v in ipairs(list) do
                                cell = dbworldmap.new()
                                cell.__key__ = v.idx
                                cell:release()
                            end
                        end
                        cachePages[pageIdx] = nil
                    end
                end
            end
        end
        skynet.sleep(ConstTimeOut)
    end
end

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
end

---@public 通过网格idx取得所以屏的index
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
    if mapCell:isEmpty() then
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
function CMD.occupyMapCell(cidx, type)
    local idx = CMD.getIdleIdx()
    local mapCell = dbworldmap.instanse(idx)
    local cellData = {}
    cellData[dbworldmap.keys.idx] = idx
    cellData[dbworldmap.keys.pageIdx] = CMD.getPageIdx(idx)
    cellData[dbworldmap.keys.cidx] = cidx or 0
    cellData[dbworldmap.keys.type] = type
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
    local list = skynet.call("CLDB", "lua", "GETGROUP", dbworldmap.name, pageIdx)
    if list == nil or cachePages[pageIdx] == nil then
        -- 缓存里没有，那就从数据库里取
        list = dbworldmap.getListBypageIdx(pageIdx)
        for i, v in ipairs(list) do
            -- 这样就会把数据先缓存起来
            dbworldmap.instanse(v.idx)
        end
    end
    -- 记录已经缓存了的page
    cachePages[pageIdx] = dateEx.nowMS()
    local mapPage = {}
    mapPage.pageIdx = pageIdx
    mapPage.cells = list
    skynet.error("=================" .. #list)
    pauseFork = false
    return skynet.call(NetProtoIsland, "lua", "send", cmd, {code = Errcode.ok}, mapPage, map)
end

---@public 搬迁
function CMD.moveCity(cidx, fromPos, toPos)
    if not grid:IsInBounds(toPos) then
        return Errcode.notInGridBounds
    end
    local toCell = dbworldmap.instanse(toPos)
    if (not toCell:isEmpty()) and toCell:get_cidx() > 0 then
        printe(toPos)
        toCell:release()
        return Errcode.worldCellNotIdel
    end
    local fromCell = dbworldmap.instanse(fromPos)
    if fromCell:isEmpty() or fromCell:get_cidx() <= 0 then
        printe(fromPos)
        fromCell:release()
        return Errcode.notFoundInWorld
    end

    local data = fromCell:value2copy()
    data[dbworldmap.keys.idx] = toPos
    data[dbworldmap.keys.cidx] = cidx
    data[dbworldmap.keys.pageIdx] = CMD.getPageIdx(toPos)
    -- 重新设置地块数据
    toCell:init(data, true)
    --推送给在线的客户端
    local map = skynet.call(NetProtoIsland, "lua", "send", "onMapCellChg", {code = Errcode.ok}, toCell:value2copy())
    skynet.call("watchdog", "lua", "notifyAll", map)
    -- 旧地块也推送
    local d = toCell:value2copy()
    d[dbworldmap.keys.cidx] = 0
    d[dbworldmap.keys.type] = 0
    map = skynet.call(NetProtoIsland, "lua", "send", "onMapCellChg", {code = Errcode.ok}, d)
    skynet.call("watchdog", "lua", "notifyAll", map)

    -- 删除旧的地块
    fromCell:delete()
    toCell:release()
    return Errcode.ok
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
        skynet.fork(procTimeoutData)

        skynet.register "LDSWorld"
    end
)
