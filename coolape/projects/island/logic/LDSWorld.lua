-- 世界地图网格
local skynet = require "skynet"
require "skynet.manager"    -- import skynet.register
require("Errcode")
---@type Grid
require("Grid")
require("public.cfgUtl")
require("numEx")
require("db.dbworldmap")

local constCfg  -- 常量配置
---@type Grid
local grid
local gridSize -- 网格size
local screenSize = 10   -- 大地图一屏size
local cellSize = 1
local screenCells = {}  -- 每屏的网格信息
local screenCneterIndexs = {}
local currScreenOrder = 1
local NetProtoIsland = "NetProtoIsland"

local CMD = {}

--取得下屏的order
--local getNextScreenOrder = function()
--    currScreenOrder = currScreenOrder + 1
--    if currScreenOrder > #screenCneterIndexs then
--        currScreenOrder = 1
--    end
--end

--============================================
-- 初始化
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

    local col, row
    col = numEx.getIntPart(pos.x / screenSize)
    row = numEx.getIntPart(pos.z / screenSize)

    local x2 = col * screenSize + (screenSize / 2)
    local z2 = row * screenSize + (screenSize / 2)
    local cellPosition = grid.Origin + Vector3(x2, 0, z2)
    return grid:GetCellIndex(cellPosition)
end

-- 取得空闲位置的index
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
    mapCell:release()
    return mapCell:value2copy()
end

---@public 取得一屏数据
function CMD.getMapDataByPageIdx(map)
    local pageIdx = map.pageIdx
    local cmd = map.cmd
    local list = dbworldmap.getListBypageIdx(pageIdx)
    local mapPage = {}
    mapPage.pageIdx = pageIdx
    mapPage.mapPage = list
    skynet.ret(NetProtoIsland, "lua", "send", cmd, { code = Errcode.ok }, mapPage)
end

skynet.start(function()
    constCfg = cfgUtl.getConstCfg()
    gridSize = constCfg.GridWorld

    -- 初始化网格
    grid = Grid.new()
    grid:init(Vector3.zero, gridSize, gridSize, cellSize)

    skynet.dispatch("lua", function(_, _, command, ...)
        local f = CMD[command]
        skynet.ret(skynet.pack(f(...)))
    end)
    skynet.register "LDSWorld"
end)
