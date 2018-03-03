---网格
require("class")
require("Math")
require("Vector3")
require("Bounds")
require("numEx")
---@class Grid
Grid = class("Grid")

local table = table
local m_numberOfRows
local m_numberOfColumns
local m_cellSize
local Origin = Vector3.zero
local kInvalidIndex = -1 -- 无效的单元index
local kXAxis = Vector3(1, 0, 0)
local kZAxis = Vector3(0, 0, 1)
local kDepth = 1
--Grid.Width = 0
--Grid.Height = 0
--Grid.NumberOfCells = 0
--===================================================
function Grid:init(origin, numRows, numCols, cellSize)
    Origin = origin or Vector3.zero
    m_numberOfRows = numRows
    m_numberOfColumns = numCols
    m_cellSize = cellSize or 1
    self.Width = m_numberOfColumns * m_cellSize
    self.Height = m_numberOfRows * m_cellSize
    self.NumberOfCells = m_numberOfRows * m_numberOfColumns
end

-- pos is in world space coordinates. The returned position is also in world space coordinates.
---@return Vector3
function Grid:GetNearestCellCenter(pos)
    local index = self:GetCellIndex(pos)
    local cellPos = self:GetCellPosition( index )
    cellPos.x = cellPos.x + ( m_cellSize / 2.0)
    cellPos.z = cellPos.z + ( m_cellSize / 2.0)
    return cellPos
end

-- returns a position in world space coordinates.
---@return Vector3
function Grid:GetCellCenterByIndex(index)
    local cellPosition = self:GetCellPosition(index)
    cellPosition.x = cellPosition.x + ( m_cellSize / 2.0)
    cellPosition.z = cellPosition.z + ( m_cellSize / 2.0)
    return cellPosition
end
function Grid:GetCellCenter(...)
    local paras = { ... }
    if #paras > 1 then
        local col, row
        col = paras[1]
        row = paras[2]
        return self:GetCellCenterByIndex(self:GetCellIndex(col, row))
    else
        local index = paras[1]
        return self:GetCellCenterByIndex(index)
    end
end

--[[ <summary>
/// Returns the lower left position of the grid cell at the passed tile index. The origin of the grid is at the lower left,
/// so it uses a cartesian coordinate system.
/// </summary>
/// <param name = "index">index to the grid cell to consider</param>
/// <returns>Lower left position of the grid cell (origin position of the grid cell), in world space coordinates</returns>
]]
function Grid:GetCellPosition(index)
    local row = self:GetRow(index)
    local col = self:GetColumn(index)
    local x = col * m_cellSize
    local z = row * m_cellSize
    local cellPosition = Origin + Vector3(x, 0, z)
    return cellPosition
end

-- pass in world space coords. Get the tile index at the passed position
function Grid:GetCellIndexByPos(pos)
    if ( not self:IsInBounds(pos) ) then
        return kInvalidIndex
    end
    pos = pos - Origin
    local col, row
    col = numEx.getIntPart(pos.x / m_cellSize)
    row = numEx.getIntPart(pos.z / m_cellSize)
    return row * m_numberOfColumns + col
end

function Grid:GetCellIndex(...)
    local paras = { ... }
    if #paras > 1 then
        local col, row
        col = paras[1]
        row = paras[2]
        return (row * m_numberOfColumns + col)
    else
        local pos = paras[1]
        return self:GetCellIndexByPos(pos)
    end
end

--// pass in world space coords. Get the tile index at the passed position, clamped to be within the grid.
function Grid:GetCellIndexClamped(pos)
    pos = pos - Origin

    local col = numEx.getIntPart(pos.x / m_cellSize)
    local row = numEx.getIntPart(pos.z / m_cellSize)

    --//make sure the position is in range.
    col = numEx.getIntPart(math.clamp(col, 0, m_numberOfColumns - 1))
    row = numEx.getIntPart(math.clamp(row, 0, m_numberOfRows - 1))

    return (row * m_numberOfColumns + col)
end

function Grid:GetCellBounds(index)
    local cellCenterPos = self:GetCellPosition(index)
    cellCenterPos.x = cellCenterPos.x + ( m_cellSize / 2.0)
    cellCenterPos.z = cellCenterPos.z + ( m_cellSize / 2.0 )
    local cellBounds = Bounds.New(cellCenterPos, Vector3(m_cellSize, kDepth, m_cellSize))
    return cellBounds
end

function Grid:GetGridBounds()
    local gridCenter = Origin + (self.Width / 2.0) * kXAxis + (self.Height / 2.0) * kZAxis
    local gridBounds = Bounds.New(gridCenter, Vector3(self.Width, kDepth, self.Height))
    return gridBounds
end

function Grid:GetRow(index)
    local row = numEx.getIntPart(index / m_numberOfColumns)
    return row
end

function Grid:GetColumn(index)
    local col = numEx.getIntPart(index % m_numberOfColumns)
    return col
end

function Grid:Left(index)
    local col = self:GetColumn(index)
    local row = self:GetRow(index)
    col = col - 1
    if self:IsInBounds(col, row) then
        return self:GetCellIndex(col, row)
    else
        return -1
    end
end

function Grid:Right(index)
    local col = self:GetColumn(index)
    local row = self:GetRow(index)
    col = col + 1
    if self:IsInBounds(col, row) then
        return self:GetCellIndex(col, row)
    else
        return -1
    end
end

function Grid:Up(index)
    local col = self:GetColumn(index)
    local row = self:GetRow(index)
    row = row + 1
    if self:IsInBounds(col, row) then
        return self:GetCellIndex(col, row)
    else
        return -1
    end
end

function Grid:Down(index)
    local col = self:GetColumn(index)
    local row = self:GetRow(index)
    row = row - 1
    if self:IsInBounds(col, row) then
        return self:GetCellIndex(col, row)
    else
        return -1
    end
end


function Grid:LeftUp(index)
    local col = self:GetColumn(index)
    local row = self:GetRow(index)
    col = col - 1
    row = row + 1
    if self:IsInBounds(col, row) then
        return self:GetCellIndex(col, row)
    else
        return -1
    end
end

function Grid:RightUp(index)
    local col = self:GetColumn(index)
    local row = self:GetRow(index)
    col = col + 1
    row = row + 1
    if self:IsInBounds(col, row) then
        return self:GetCellIndex(col, row)
    else
        return -1
    end
end

function Grid:LeftDown(index)
    local col = self:GetColumn(index)
    local row = self:GetRow(index)
    col = col - 1
    row = row - 1
    if self:IsInBounds(col, row) then
        return self:GetCellIndex(col, row)
    else
        return -1
    end
end

function Grid:RightDown(index)
    local col = self:GetColumn(index)
    local row = self:GetRow(index)
    col = col + 1
    row = row - 1
    if self:IsInBounds(col, row) then
        return self:GetCellIndex(col, row)
    else
        return -1
    end
end

function Grid:IsInBounds(...)
    local paras = { ... }
    if #paras > 1 then
        local col, row
        col = paras[1]
        row = paras[2]
        if (col < 0 or col >= m_numberOfColumns) then
            return false
        elseif (row < 0 or row >= m_numberOfRows) then
            return false
        else
            return true
        end
    else
        local index = paras[1]
        return ( index >= 0 and index < self.NumberOfCells )
    end
end

--// pass in world space coords
function Grid:IsPosInBounds(pos)
    local index = self:GetCellIndex(pos)
    return self:IsInBounds(index)
end

--[[
/// <summary>
/// Gets the own grids.根据中心点及占用格子size,取得占用格子index数
/// </summary>
/// <returns>
/// The own grids.
/// </returns>
/// <param name='center'>
/// Center. 中心点index
/// </param>
/// <param name='size'>
/// Size. Size * Size的范围
/// </param>
]]
function Grid:getCells ( center, size)
    local ret = {}
    if (center < 0) then
        return ret
    end
    local tpindex
    local numRows = m_numberOfRows
    local half = numEx.getIntPart(size / 2)
    if (size % 2 == 0) then
        for row = 0, half do
            for i = 1, half do
                tpindex = center - row * numRows - i
                if tpindex < 0 or (numEx.getIntPart(tpindex / numRows) ~= numEx.getIntPart((center - row * numRows) / numRows)) then
                    --超出grid范围
                    tpindex = kInvalidIndex
                end
                table.insert(ret, tpindex)
            end
            for i = 0, half - 1 do
                tpindex = center - row * numRows + i
                if tpindex < 0 or (numEx.getIntPart(tpindex / numRows) ~= numEx.getIntPart((center - row * numRows) / numRows)) then
                    tpindex = kInvalidIndex
                end
                table.insert(ret, tpindex)
            end
        end
        for row = 1, half - 1 do
            for i = 1, half do
                tpindex = center + row * numRows - i
                if tpindex < 0 or (numEx.getIntPart(tpindex / numRows) ~= numEx.getIntPart((center + row * numRows) / numRows)) then
                    tpindex = kInvalidIndex
                end
                table.insert(ret, tpindex)
            end
            for i = 0, half - 1 do
                tpindex = center + row * numRows + i
                if tpindex < 0 or (numEx.getIntPart(tpindex / numRows) ~= numEx.getIntPart((center + row * numRows) / numRows)) then
                    tpindex = kInvalidIndex
                end
                table.insert(ret, tpindex)
            end
        end
    else
        for row = 0, half do
            for i = 0, half do
                tpindex = center - row * numRows - i
                if tpindex < 0 or (numEx.getIntPart(tpindex / numRows) ~= numEx.getIntPart((center - row * numRows) / numRows)) then
                    tpindex = kInvalidIndex
                end
                table.insert(ret, tpindex)
            end

            for i = 1, half do
                tpindex = center - row * numRows + i
                if tpindex < 0 or (numEx.getIntPart(tpindex / numRows) ~= numEx.getIntPart((center - row * numRows) / numRows)) then
                    tpindex = kInvalidIndex
                end
                table.insert(ret, tpindex)
            end
        end

        for row = 1, half do
            for i = 0, half do
                tpindex = center + row * numRows - i
                if tpindex < 0 or (numEx.getIntPart(tpindex / numRows) ~= numEx.getIntPart((center + row * numRows) / numRows)) then
                    tpindex = kInvalidIndex
                end
                table.insert(ret, tpindex)
            end

            for i = 1, half do
                tpindex = center + row * numRows + i
                if tpindex < 0 or (numEx.getIntPart(tpindex / numRows) ~= numEx.getIntPart((center + row * numRows) / numRows)) then
                    tpindex = kInvalidIndex
                end
                table.insert(ret, tpindex)
            end
        end
    end
    return ret
end
--===================================================
return Grid
