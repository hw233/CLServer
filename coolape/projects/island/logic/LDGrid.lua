---网格
require("sys.Vector3")
require("sys.Math")
require("sys.Bounds")
require("numEx")
---@class LDGrid
local LDGrid = {}

local m_numberOfRows
local m_numberOfColumns
local m_cellSize
local Origin = Vector3.zero
local InvalidIndex = -1 -- 无效的单元index
local kXAxis = Vector3(1, 0, 0);
local kZAxis = Vector3(0, 0, 1);
local kDepth = 1
LDGrid.Width = 0
LDGrid.Height = 0
LDGrid.NumberOfCells = 0
--===================================================
function LDGrid.init(origin, numRows, numCols, cellSize)
    Origin = origin or Vector3.zero
    m_numberOfRows = numRows
    m_numberOfColumns = numCols
    m_cellSize = cellSize or 1
    LDGrid.Width = m_numberOfColumns * m_cellSize
    LDGrid.Height = m_numberOfRows * m_cellSize
    LDGrid.NumberOfCells = m_numberOfRows * m_numberOfColumns
end

-- pos is in world space coordinates. The returned position is also in world space coordinates.
---@return Vector3
function LDGrid.GetNearestCellCenter(pos)
    local index = LDGrid.GetCellIndex(pos)
    local cellPos = LDGrid.GetCellPosition( index )
    cellPos.x = cellPos.x + ( m_cellSize / 2.0)
    cellPos.z = cellPos.z + ( m_cellSize / 2.0)
    return cellPos;
end

-- returns a position in world space coordinates.
---@return Vector3
function LDGrid.GetCellCenterByIndex(index)
    local cellPosition = LDGrid.GetCellPosition(index);
    cellPosition.x = cellPosition.x + ( m_cellSize / 2.0)
    cellPosition.z = cellPosition.z + ( m_cellSize / 2.0)
    return cellPosition
end
function LDGrid.GetCellCenter(...)
    local paras = { ... }
    if #paras > 1 then
        local col, row
        col = paras[1]
        row = paras[2]
        return LDGrid.GetCellCenterByIndex(LDGrid.GetCellIndex(col, row))
    else
        local index = paras[1]
        return LDGrid.GetCellCenterByIndex(index)
    end
end

--[[ <summary>
/// Returns the lower left position of the grid cell at the passed tile index. The origin of the grid is at the lower left,
/// so it uses a cartesian coordinate system.
/// </summary>
/// <param name = "index">index to the grid cell to consider</param>
/// <returns>Lower left position of the grid cell (origin position of the grid cell), in world space coordinates</returns>
]]
function LDGrid.GetCellPosition(index)
    local row = LDGrid.GetRow(index);
    local col = LDGrid.GetColumn(index);
    local x = col * m_cellSize;
    local z = row * m_cellSize;
    local cellPosition = Origin + Vector3(x, 0, z);
    return cellPosition;
end

-- pass in world space coords. Get the tile index at the passed position
function LDGrid.GetCellIndexByPos(pos)
    if ( not LDGrid.IsInBounds(pos) ) then
        return InvalidIndex
    end
    pos = pos - Origin
    local col, row
    col = numEx.getIntPart(pos.x / m_cellSize)
    row = numEx.getIntPart(pos.z / m_cellSize)
    return row * m_numberOfColumns + col
end

function LDGrid.GetCellIndex(...)
    local paras = { ... }
    if #paras > 1 then
        local col, row
        col = paras[1]
        row = paras[2]
        return (row * m_numberOfColumns + col);
    else
        local pos = paras[1]
        return LDGrid.GetCellIndexByPos(pos)
    end
end

--// pass in world space coords. Get the tile index at the passed position, clamped to be within the grid.
function LDGrid.GetCellIndexClamped(pos)
    pos = pos - Origin;

    local col = numEx.getIntPart(pos.x / m_cellSize);
    local row = numEx.getIntPart(pos.z / m_cellSize);

    --//make sure the position is in range.
    col = numEx.getIntPart(math.clamp(col, 0, m_numberOfColumns - 1));
    row = numEx.getIntPart(math.clamp(row, 0, m_numberOfRows - 1));

    return (row * m_numberOfColumns + col);
end

function LDGrid.GetCellBounds(index)
    local cellCenterPos = LDGrid.GetCellPosition(index);
    cellCenterPos.x = cellCenterPos.x + ( m_cellSize / 2.0);
    cellCenterPos.z = cellCenterPos.z + ( m_cellSize / 2.0 );
    local cellBounds = Bounds.New(cellCenterPos, Vector3(m_cellSize, kDepth, m_cellSize));
    return cellBounds;
end

function LDGrid.GetGridBounds()
    local gridCenter = Origin + (LDGrid.Width / 2.0) * kXAxis + (LDGrid.Height / 2.0) * kZAxis;
    local gridBounds = Bounds.New(gridCenter, Vector3(LDGrid.Width, kDepth, LDGrid.Height));
    return gridBounds;
end

function LDGrid.GetRow(index)
    local row = numEx.getIntPart(index / m_numberOfColumns);
    return row;
end

function LDGrid.GetColumn(index)
    local col = numEx.getIntPart(index % m_numberOfColumns);
    return col;
end

function LDGrid.IsInBounds(...)
    local paras = { ... }
    if #paras > 1 then
        local col, row
        col = paras[1]
        row = paras[2]
        if (col < 0 or col >= m_numberOfColumns) then
            return false;
        elseif (row < 0 or row >= m_numberOfRows) then
            return false;
        else
            return true;

        end
    else
        local index = paras[1]
        return ( index >= 0 and index < LDGrid.NumberOfCells );
    end
end

--// pass in world space coords
function LDGrid.IsPosInBounds(pos)
    local index = LDGrid.GetCellIndex(pos)
    return LDGrid.IsInBounds(index)
end
--===================================================
return LDGrid
