-- 世界地图网格
local skynet = require "skynet"
require "skynet.manager"    -- import skynet.register
---@type Grid
require("Grid")
require("public.cfgUtl")
require("numEx")

local constCfg  -- 常量配置
local grid
local gridSize -- 网格size
local screenSize = 10   -- 大地图一屏size
local cellSize = 1
local screenCells = {}  -- 每屏的网格信息
local screenCneterIndexs = {}
local currScreenOrder = 1

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
    local i = numEx.nextInt(1, #cells)
    local index = cells[i]
    --todo:判断该位置是否可用
    return index
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
