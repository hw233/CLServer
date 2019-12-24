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
require("db.dbunit")
require("db.dbfleet")
require("logic.IDConstVals")
---@type logic4fleet
local logic4fleet = require("logic.logic4fleet")
require("timerQueue")

local constCfg  -- 常量配置
---@type Grid
local grid
local gridSize  -- 网格size
local screenSize = 10 -- 大地图一屏size
local cellSize = 10
local screenCells = {} -- 每屏的网格信息
local screenCneterIndexs = {}
local currScreenOrder = 1
local NetProtoIsland = skynet.getenv("NetProtoName")

local cachePages = {}
local ConstTimeOut = 60 * 100 -- 60秒

local agentsInCurrPage = {} -- 用户当前正在查看哪个页面
local CMD = {} -- 外部的接口
local logic = {} -- 内部的接口
local pauseFork = false

local moveSpeed
local atleaseTime = 0 -- 至少需要多少时间
local constDeadMs

-- 舰队通过哪些屏 key:舰队idx，val:屏的idx table
local fleetPassScreens = {}
-- 屏对应该有哪些舰队 key:屏的idx，val:舰队idx table
local screen4Fleets = {}

--取得下屏的order
--local getNextScreenOrder = function()
--    currScreenOrder = currScreenOrder + 1
--    if currScreenOrder > #screenCneterIndexs then
--        currScreenOrder = 1
--    end
--end

--============================================
--============================================
--============================================
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
    local cfgWorldBasePath = priorityPath .. "cfgWorldmap/"
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

---@public 通过网格idx取得所以屏的index
local function getPageIdx(index)
    local pos = grid:GetCellCenter(index)
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

---@public 取得大图的index映射到分区网格的index
---@param index
local function mapIndex2AreaIndex(index)
    local areaIndex = -1
    local col = grid:GetColumn(index)
    local row = grid:GetRow(index)
    col = numEx.getIntPart(col / scale)
    row = numEx.getIntPart(row / scale)

    areaIndex = gridArea:GetCellIndex(col, row)
    return areaIndex
end

---@public 取得网格id对应的分区id
local function getAreaId(index)
    local areaIdx = mapIndex2AreaIndex(index)
    return mapAreaInfor[areaIdx]
end

local function haveBaseData(index)
    return (mapBaseData[index] ~= nil)
end

---@public 取得中心屏四周8屏的index
local function getAroundPages(centerPageIdx)
    local ret = {}
    if centerPageIdx < 0 then
        return ret
    end
    local centerPos = grid:GetCellCenter(centerPageIdx)
    local screen = screenSize * grid.m_cellSize
    -- center
    -- local index = grid:GetCellIndex(centerPos)
    ret[centerPageIdx] = centerPageIdx
    -- left
    local pos = centerPos + Vector3(-1, 0, 0) * screen
    local index = grid:GetCellIndex(pos)
    ret[index] = index
    -- right
    pos = centerPos + Vector3(1, 0, 0) * screen
    index = grid:GetCellIndex(pos)
    ret[index] = index
    -- up
    pos = centerPos + Vector3(0, 0, 1) * screen
    index = grid:GetCellIndex(pos)
    ret[index] = index
    -- down
    pos = centerPos + Vector3(0, 0, -1) * screen
    index = grid:GetCellIndex(pos)
    ret[index] = index
    -- leftup
    pos = centerPos + Vector3(-1, 0, 1) * screen
    index = grid:GetCellIndex(pos)
    ret[index] = index
    -- leftdown
    pos = centerPos + Vector3(-1, 0, -1) * screen
    index = grid:GetCellIndex(pos)
    ret[index] = index
    -- rightup
    pos = centerPos + Vector3(1, 0, 1) * screen
    index = grid:GetCellIndex(pos)
    ret[index] = index
    -- rightdown
    pos = centerPos + Vector3(1, 0, -1) * screen
    index = grid:GetCellIndex(pos)
    ret[index] = index
    return ret
end

---@type CLLQueue 需要推送的数据包的队列
local needPushPkgQueue = CLLQueue.new()
---@public 推送有变化的数据
local loopPushPkg = function()
    while true do
        while needPushPkgQueue:size() > 0 do
            local pkgInfor = needPushPkgQueue:deQueue()
            if pkgInfor then
                local index = pkgInfor.index
                local pkg = pkgInfor.pkg
                for agent, pagesMap in pairs(agentsInCurrPage) do
                    if pagesMap[getPageIdx(index)] and pagesMap[getPageIdx(index)] >= 0 then
                        -- 在九屏内都可以推送
                        if skynet.address(agent) then
                            skynet.call(agent, "lua", "sendPackage", pkg)
                        end
                    end
                end
            end
        end
        skynet.sleep(50) -- 等0.5秒
    end
end

---@public 清除舰队屏的数据
local cleanFleetPassScreen = function(fidx)
    local screens = fleetPassScreens[fidx]
    if screens then
        for k, index in pairs(screens) do
            local fleetsMap = screen4Fleets[index]
            if fleetsMap then
                fleetsMap[fidx] = nil
                screen4Fleets[index] = fleetsMap
            end
        end
    end
    fleetPassScreens[fidx] = nil
end

---@public 处理舰队会通过哪些屏
local setFleetPassScreen = function(fidx)
    -- 先清除再处理
    cleanFleetPassScreen(fidx)

    local fleet = dbfleet.instanse(fidx)
    if fleet:isEmpty() then
        return
    end
    local from = fleet:get_frompos()
    local to = fleet:get_topos()
    local fromPos = grid:GetCellCenter(from)
    local toPos = grid:GetCellCenter(to)
    local dir = toPos - fromPos
    -- 取得from->to通过的屏
    local screenMap = {}
    local maxdis = Vector3.Distance(fromPos, toPos)
    local dis = 0
    local pos

    local pageIdx = getPageIdx(from)
    screenMap[pageIdx] = pageIdx
    pageIdx = getPageIdx(to)
    screenMap[pageIdx] = pageIdx
    -- 把步长设置成屏的size的一半，是尽量保证能取得完整的舰队经过所有屏，但也有可能漏掉,比如舰队只是经过一屏的一个小角
    local stepDis = screenSize * cellSize / 4
    dis = dis + stepDis
    while dis < maxdis do
        pos = fromPos + dir:Normalize() * dis
        pageIdx = getPageIdx(grid:GetCellIndexByPos(pos))
        if pageIdx >= 0 then
            screenMap[pageIdx] = pageIdx
        end
        dis = dis + stepDis
    end
    fleetPassScreens[fidx] = screenMap
    for k, pageIdx in pairs(screenMap) do
        local m = screen4Fleets[pageIdx] or {}
        m[fidx] = fidx
        screen4Fleets[pageIdx] = m
    end

    fleet:release()
end

---@public 舰队是否到达
---@param fleet dbfleet
local procFleetArrived = function(fidx)
    local fleet = dbfleet.instanse(fidx)
    if fleet:isEmpty() or fleet:get_status() ~= IDConstVals.FleetState.moving then
        return true
    end
    local diff = fleet:get_arrivetime() - dateEx.nowMS()
    if diff > 0 then
        -- 未到达
        return false
    end
    local index = fleet:get_topos()
    fleet:set_curpos(index)
    local type = logic.getTileType(index)
    if fleet:get_task() == IDConstVals.FleetTask.voyage then
        -- //TODO:如果目标地块是npc，进攻
        if type == IDConstVals.WorldmapCellType.empty then
            -- 如果目标地块是空地，更改状态
            fleet:set_status(IDConstVals.FleetState.stay)
        elseif type == IDConstVals.WorldmapCellType.port then
            -- 如果目标地块是港口，如果没人更改状态，清空沉没时间，如果有人进入战场
            local mapcell = dbworldmap.instanse(index)
            if mapcell:isEmpty() or mapcell:get_cidx() <= 0 then
                -- 如果没人更改状态，清空沉没时间、同时更改地块数据
                fleet:set_status(IDConstVals.FleetState.docked)
                fleet:set_deadtime(nil)
                mapcell:init(
                    {
                        [dbworldmap.keys.idx] = index,
                        [dbworldmap.keys.attrid] = mapBaseData[index],
                        [dbworldmap.keys.type] = IDConstVals.WorldmapCellType.port,
                        [dbworldmap.keys.pageIdx] = getPageIdx(index),
                        [dbworldmap.keys.cidx] = fleet:get_cidx(),
                        [dbworldmap.keys.fidx] = fleet:get_idx()
                    }
                )
                -- 推送地块
                logic.pushMapCellChg(index)
            else
                if mapcell:get_cidx() == fleet:get_cidx() then
                    --//TODO:给玩家发个邮件告知你的舰队为何返航了
                    -- 是自己的舰队，直接返回
                    local city = dbcity.instanse(fleet:get_cidx())
                    logic.fleetMoveTo(fleet:get_idx(), nil, fleet:get_topos(), city:get_pos(), IDConstVals.FleetTask.back)
                    city:release()
                else
                    --//TODO: 如果有人且不是自己,进入战斗
                end
            end
            if not mapcell:isEmpty() then
                mapcell:release()
            end
        elseif type == IDConstVals.WorldmapCellType.user then
            -- 如果目标地块是玩家岛，如果是自己的岛，更改状态，如果是别人的岛，进攻
            local mapcell = dbworldmap.instanse(index)
            -- 走到这里mapcell不可能是empty
            if mapcell:get_cidx() == fleet:get_cidx() then
                -- 自己的城，那就说明是返回到自己的主城
                fleet:set_task(IDConstVals.FleetTask.idel)
                fleet:set_status(IDConstVals.FleetState.none)
                fleet:set_deadtime(nil)
                fleet:set_curpos(index)
            else
                --//TODO:进入战斗
            end
        end
    elseif fleet:get_task() == IDConstVals.FleetTask.back then
        fleet:set_task(IDConstVals.FleetTask.idel)
        fleet:set_status(IDConstVals.FleetState.none)
        fleet:set_deadtime(nil)
        -- 重新取一次主城的坐标，因为有可能主城已经迁城了
        local city = dbcity.instanse(fleet:get_cidx())
        fleet:set_curpos(city:get_pos())
        city:release()
    elseif fleet:get_task() == IDConstVals.FleetTask.attack then
    --TODO:
    end
    --------------------------------------------
    if fleet:get_status() ~= IDConstVals.FleetState.moving then
        logic.onFleetArrived(fleet:get_idx())
    else
        -- 说明又返回了，只需要推送舰队
        logic.pushFleetChg(fleet:get_idx())
    end
    fleet:release()
    return true
end

---@public 舰队是否沉没
---@param fleet dbfleet
---@return boolean true:表示已经沉没
local procFleetDead = function(fleet)
    if fleet:isEmpty() or fleet:get_task() == IDConstVals.FleetTask.idel then
        return true
    end
    local fidx = fleet:get_idx()
    local diff = fleet:get_deadtime() - dateEx.nowMS()
    if diff <= 0 then
        logic4fleet.delete(fidx)
        logic.onFleetDead(fidx)
        return true
    end
    return false
end

-- 需要轮询处理的舰队
local needPollingFleets = {}
---@public 舰队轮询处理（只处理在移动中、停在海面的舰队）
local fleetPolling = function()
    ---@type dbfleet
    local fleet
    while true do
        for k, fidx in pairs(needPollingFleets) do
            fleet = dbfleet.instanse(fidx)
            if fleet:isEmpty() then
                cleanFleetPassScreen(fidx)
                needPollingFleets[k] = nil
            else
                if fleet:get_status() == IDConstVals.FleetState.moving then
                    if fleet:get_deadtime() <= dateEx.nowMS() then
                        -- 沉没了
                        needPollingFleets[k] = nil
                        if procFleetDead(fleet) then
                            fleet = nil
                        end
                    else
                        if fleet:get_arrivetime() <= dateEx.nowMS() then
                            -- 到达了
                            procFleetArrived(fleet:get_idx())
                        end
                    end
                elseif fleet:get_status() == IDConstVals.FleetState.stay then
                    if fleet:get_deadtime() <= dateEx.nowMS() then
                        -- 沉没了
                        needPollingFleets[k] = nil
                        if procFleetDead(fleet) then
                            fleet = nil
                        end
                    end
                else
                    cleanFleetPassScreen(fidx)
                    needPollingFleets[k] = nil
                end
                if fleet then
                    fleet:release()
                end
            end
        end
        skynet.sleep(100) -- 等1秒
    end
end
--============================================
--============================================
--============================================
---@public 初始化
logic.init = function()
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

    moveSpeed = cfgUtl.getConstCfg().FleetMoveSpeed * 1000
    constDeadMs = cfgUtl.getConstCfg().FleetTimePerOnce * 60 * 1000
    atleaseTime = cfgUtl.getConstCfg().FleetAtLeastSec * 1000

    logic4fleet.init()

    -- 初始化需要处理的舰队列表
    local sql =
        "select * from fleet where status=" ..
        IDConstVals.FleetState.moving .. " or status=" .. IDConstVals.FleetState.stay .. ";"
    local list = skynet.call("CLMySQL", "lua", "exesql", sql)
    if list and list.errno then
        skynet.error("[fleet] sql error==" .. sql)
        return nil
    end
    local fidx
    for i, v in ipairs(list) do
        fidx = v[dbfleet.keys.idx]
        needPollingFleets[fidx] = fidx
        setFleetPassScreen(fidx)
    end
end

---@public 取得两个网格之间的距离
logic.getDistance = function(index1, index2)
    local v1 = grid:GetCellCenter(index1)
    local v2 = grid:GetCellCenter(index2)
    return Vector3.Distance(v1, v2)
end

---@public 取得空闲位置的index
logic.getIdleIdx = function(creenIdx)
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
        return logic.getIdleIdx()
    end
end
---@public 取得地块的配置表
logic.getTileAttr = function(index)
    local id = mapBaseData[index]
    if id then
        return cfgUtl.getMapTileByID(id)
    end
    return nil
end

---@public 取得地块类型
logic.getTileType = function(index)
    local cell = dbworldmap.instanse(index)
    if cell:isEmpty() then
        if (not haveBaseData(index)) then
            return IDConstVals.WorldmapCellType.empty
        else
            local attr = cfgUtl.getMapTileByID(mapBaseData[index])
            if attr == nil then
                printe("get maptile cfg is nil. attrid=" .. cell:get_attrid())
                return IDConstVals.WorldmapCellType.occupy
            else
                return attr.GID
            end
        end
    else
        local attr = cfgUtl.getMapTileByID(cell:get_attrid())
        cell:release()
        if attr == nil then
            printe("get maptile cfg is nil. attrid=" .. cell:get_attrid())
            return IDConstVals.WorldmapCellType.occupy
        else
            return attr.GID
        end
    end
end

---@public 占用一个格子
logic.occupyMapCell = function(cidx, type, attrid)
    local idx = logic.getIdleIdx()
    local mapCell = dbworldmap.instanse(idx)
    local cellData = {}
    cellData[dbworldmap.keys.idx] = idx
    cellData[dbworldmap.keys.pageIdx] = getPageIdx(idx)
    cellData[dbworldmap.keys.cidx] = cidx or 0
    cellData[dbworldmap.keys.type] = type
    cellData[dbworldmap.keys.attrid] = attrid
    mapCell:init(cellData, true)
    local ret = mapCell:value2copy()
    mapCell:release()
    return ret
end

---@public 推送有变化的数据
logic.pushMapCellChg = function(index, isRemove)
    ---@type NetProtoIsland.ST_mapCell
    local d
    local cell = dbworldmap.instanse(index)
    if isRemove or cell:isEmpty() then
        isRemove = true
        d = {}
        d.idx = index
        d.cidx = 0
    else
        d = cell:value2copy()
        if cell:get_cidx() > 0 then
            local city = dbcity.instanse(cell:get_cidx())
            local pidx = city:get_pidx()
            local player = dbplayer.instanse(pidx)
            d.name = player:get_name()
            d.lev = player:get_lev()
            d.state = city:get_status()
            city:release()
            player:release()
        end
    end
    if not cell:isEmpty() then
        cell:release()
    end
    --推送给在线的客户端
    local mapcell = skynet.call(NetProtoIsland, "lua", "send", "onMapCellChg", {code = Errcode.ok}, d, isRemove)
    logic.addPushPkg(index, mapcell)
end

---@public 推送有变化的数据
logic.addPushPkg = function(index, msgPkg)
    needPushPkgQueue:enQueue({index = index, pkg = msgPkg})
end
---@public 移除用户
logic.rmPlayerCurrLook4WorldPage = function(agent)
    agentsInCurrPage[agent] = nil
end

---@public 取得舰队当前的真实位置
logic.getFleetRealCurPos = function(fidx)
    local fleet = dbfleet.instanse(fidx)
    if fleet:isEmpty() then
        return -1
    end
    if fleet:get_status() == IDConstVals.FleetState.moving then
        -- 正在出
        local dis = logic.getDistance(fleet:get_frompos(), fleet:get_topos())
        dis = dis / cellSize
        local leftTime = fleet:get_arrivetime() - dateEx.nowMS()
        leftTime = leftTime < 0 and 0 or leftTime
        local totalTime = dis * moveSpeed
        totalTime = totalTime < atleaseTime and atleaseTime or totalTime -- 至少要5秒
        local persent = 1 - (leftTime / totalTime)
        -- printe("persent===================" .. persent)
        local from = grid:GetCellCenter(fleet:get_frompos())
        local to = grid:GetCellCenter(fleet:get_topos())
        ---@type Vector3
        local dir = to - from
        local curPos = from + dir * persent
        return grid:GetCellIndexByPos(curPos), curPos
    else
        local curPos = grid:GetCellCenter(fleet:get_curpos())
        return fleet:get_curpos(), curPos
    end
end

---@public 出征
---@param fromPosV3 Vector3
---@param fromPos number
---@param toPos number
logic.fleetMoveTo = function(fidx, fromPosV3, fromPos, toPos, task)
    local fleet = dbfleet.instanse(fidx)
    if fleet:isEmpty() then
        printe("失败，取得舰队为nil=" .. fidx)
        return
    end
    local fleetData = {}
    fleetData[dbfleet.keys.curpos] = fromPos
    fleetData[dbfleet.keys.frompos] = fromPos
    fleetData[dbfleet.keys.topos] = toPos
    fleetData[dbfleet.keys.status] = IDConstVals.FleetState.moving
    fleetData[dbfleet.keys.task] = task
    local dis = logic.getDistance(fromPos, toPos)/cellSize
    local costMs = dis * moveSpeed
    costMs = costMs < atleaseTime and atleaseTime or costMs -- 至少要5秒
    fleetData[dbfleet.keys.arrivetime] = dateEx.nowMS() + costMs
    fleet:refreshData(fleetData)
    if fromPosV3 == nil then
        fromPosV3 = grid:GetCellCenter(fromPos)
    end
    logic4fleet.setFleetCurPos(fleet:get_idx(), fromPosV3)
    fleet:release()

    -- 有舰队出征了
    logic.onFleetDepart(fidx)
end

---@public 推送舰队变化
logic.pushFleetChg = function(fidx)
    local fleet = dbfleet.instanse(fidx)
    ---@type NetProtoIsland.ST_fleetinfor
    local fdata
    local isRemove = false
    if fleet:isEmpty() then
        -- 说明是舰队已经沉没
        isRemove = true
        fdata = {}
        fdata[dbfleet.keys.idx] = fidx
    else
        fdata = logic4fleet.getFleet(fidx)
        fleet:release()
    end
    local pkg = skynet.call(NetProtoIsland, "lua", "send", "sendFleet", {code = Errcode.ok}, fdata, isRemove)

    -- 取得舰队经过的屏的index
    local pages = fleetPassScreens[fidx] or {}
    for k, pageIdx in pairs(pages) do
        logic.addPushPkg(pageIdx, pkg)
    end
end

---@public 有舰队出征了
logic.onFleetDepart = function(fidx)
    needPollingFleets[fidx] = fidx
    setFleetPassScreen(fidx)
    logic.pushFleetChg(fidx)
end

---@public 当舰队到达目标
logic.onFleetArrived = function(fidx)
    -- 先推送再清空
    logic.pushFleetChg(fidx)
    local fleet = dbfleet.instanse(fidx)
    if fleet:get_status() == IDConstVals.FleetState.stay or fleet.get_status() == IDConstVals.FleetState.fighting then
        setFleetPassScreen(fidx)
    else
        cleanFleetPassScreen(fidx)
    end
end
---@public 当舰队沉没时
logic.onFleetDead = function(fidx)
    -- 先推送再清空
    logic.pushFleetChg(fidx)
    cleanFleetPassScreen(fidx)
    needPollingFleets[fidx] = nil
end
--============================================================
--============================================================
--============================================================
---@public 取得一屏数据
CMD.getMapDataByPageIdx = function(map, fd, agent)
    pauseFork = true
    local pageIdx = map.pageIdx
    local cmd = map.cmd

    local list = dbworldmap.getListBypageIdx(pageIdx)
    -- cachePages[pageIdx] = dateEx.nowMS()

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

    -- 舰队列表
    local fleets = {}
    local fleetIdxs = screen4Fleets[pageIdx] or {}
    for k, idx in pairs(fleetIdxs) do
        table.insert(fleets, logic4fleet.getFleet(idx))
    end

    pauseFork = false
    return skynet.call(NetProtoIsland, "lua", "send", cmd, {code = Errcode.ok}, mapPage, fleets, map)
end

---@public 搬迁
---@param map NetProtoIsland.RC_moveCity
CMD.moveCity = function(map, fd, agent)
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
    -- 把该城相关的舰队的位置修改
    local fleets = dbfleet.getListBycidx(city:get_idx()) or {}
    for i, v in ipairs(fleets) do
        local fleet = dbfleet.instanse(v[dbfleet.keys.idx])
        if fleet:get_status() == IDConstVals.FleetState.idel then
            -- 说明是在城里待命中的
            fleet:set_curpos(toPos)
        end
        fleet:release()
    end

    local data = fromCell:value2copy()
    data[dbworldmap.keys.idx] = toPos
    data[dbworldmap.keys.cidx] = cidx
    data[dbworldmap.keys.pageIdx] = getPageIdx(toPos)
    -- 重新设置地块数据
    toCell:init(data, true)

    --推送给在线的客户端
    logic.pushMapCellChg(toCell:get_idx())

    -- 删除旧的地块
    fromCell:delete()
    -- 旧地块也推送
    logic.pushMapCellChg(fromPos, true)

    toCell:release()
    ret.code = Errcode.ok
    return skynet.call(NetProtoIsland, "lua", "send", map.cmd, ret, map)
end

---@param map NetProtoIsland.RC_setPlayerCurrLook4WorldPage
CMD.setPlayerCurrLook4WorldPage = function(map, fd, agent)
    agentsInCurrPage[agent] = getAroundPages(map.pageIdx)
    local ret = {code = Errcode.ok}
    return skynet.call(NetProtoIsland, "lua", "send", map.cmd, ret, map)
end

---@param map NetProtoIsland.RC_saveFleet
CMD.saveFleet = function(map, fd, agent)
    ---@type NetProtoIsland.ST_retInfor
    local ret = {}
    ---@type dbfleet
    local fleet
    if map.idx > 0 then
        fleet = dbfleet.instanse(map.idx)
        if fleet:isEmpty() then
            ret.code = Errcode.fleetIsNil
            ret.msg = "舰队已经不存在！"
            return skynet.call(NetProtoIsland, "lua", "send", map.cmd, ret, nil, map)
        end
    end
    local city = dbcity.instanse(map.cidx)
    if city:isEmpty() then
        ret.code = Errcode.cityIsNil
        ret.msg = "主城不存在！"
        return skynet.call(NetProtoIsland, "lua", "send", map.cmd, ret, nil, map)
    end

    if fleet == nil then
        -- 说明是新建舰队
        local cityServer = skynet.call(agent, "lua", "getLogic", "cmd4city")
        local lev = skynet.call(cityServer, "lua", "getLev")
        local attr = cfgUtl.getHeadquartersLevsByID(lev)
        local fleets = dbfleet.getListBycidx(map.cidx)
        if attr.FleetsCount <= #fleets then
            city:release()
            -- 已经超过最大舰队数量
            ret.code = Errcode.fleetsReachedMax
            ret.msg = "已经超过最大舰队数量"
            return skynet.call(NetProtoIsland, "lua", "send", map.cmd, ret, nil, map)
        end
        fleet = logic4fleet.new(map.name, map.cidx, city:get_pos())
    else
        fleet:set_name(map.name)
    end

    -- 刷新舰队的舰船数据
    logic4fleet.refreshUnits(fleet:get_idx(), map.unitInfors, agent)
    --------------------
    ---@type NetProtoIsland.ST_fleetinfor
    local fleetData = logic4fleet.getFleet(fleet:get_idx())
    ret.code = Errcode.ok
    local result = skynet.call(NetProtoIsland, "lua", "send", map.cmd, ret, fleetData, map)
    city:release()
    fleet:release()
    return result
end

---@param map NetProtoIsland.RC_fleetDepart
CMD.fleetDepart = function(map, fd, agent)
    ---@type NetProtoIsland.ST_retInfor
    local ret = {}
    ---@type dbfleet
    local fleet = dbfleet.instanse(map.idx)
    if fleet:isEmpty() then
        ret.code = Errcode.fleetIsNil
        ret.msg = "舰队不存在"
        return skynet.call(NetProtoIsland, "lua", "send", map.cmd, ret, nil, map)
    end

    -- 如果当前位置与目标坐标在一起不可操作
    if fleet:get_curpos() == map.toPos then
        ret.code = Errcode.toposisCurPos
        ret.msg = "目标坐标与当前坐标一致"
        return skynet.call(NetProtoIsland, "lua", "send", map.cmd, ret, nil, map)
    end
    -- 判读目标位置能否移动过去
    -- 如果目标是占位，如果港口已经有人，且是自己的都不能过到达
    local tileattr = logic.getTileAttr(map.toPos)
    if
        tileattr and
            (tileattr.GID == IDConstVals.WorldmapCellType.occupy or
                tileattr.GID == IDConstVals.WorldmapCellType.decorate)
     then
        ret.code = Errcode.fleetCannotMoveTo
        ret.msg = "舰队不能到达"
        return skynet.call(NetProtoIsland, "lua", "send", map.cmd, ret, nil, map)
    end

    local toCell = dbworldmap.instanse(map.toPos)
    if (not toCell:isEmpty()) and toCell:get_cidx() == fleet:get_cidx() then
        toCell:release()
        ret.code = Errcode.fleetCannotMoveTo
        ret.msg = "舰队不能到达"
        return skynet.call(NetProtoIsland, "lua", "send", map.cmd, ret, nil, map)
    end
    if not toCell:isEmpty() then
        toCell:release()
    end

    local fromPosV3 = grid:GetCellCenter(fleet:get_curpos())
    -- 如果是idel状态，则需要消耗资源，同时设置沉没时间
    if fleet:get_task() == IDConstVals.FleetTask.idel then
        local dis = logic.getDistance(fleet:get_curpos(), map.toPos)
        local constAttr = cfgUtl.getConstCfg()
        local cost = constAttr.DepartCostResPerCell * dis

        local cityServer = skynet.call(agent, "lua", "getLogic", "cmd4city")
        ---@type _ParamResInfor
        local foodInfor = skynet.call(cityServer, "lua", "getResInforByType", IDConstVals.ResType.food)
        if foodInfor.stored < cost then
            fleet:release()
            ret.code = Errcode.foodNotEnough
            ret.msg = "粮食不足"
            return skynet.call(NetProtoIsland, "lua", "send", map.cmd, ret, nil, map)
        end
        -- 操除资源
        if not skynet.call(cityServer, "lua", "consumeRes", cost, 0, 0) then
            fleet:release()
            ret.code = Errcode.foodNotEnough
            ret.msg = "粮食不足"
            return skynet.call(NetProtoIsland, "lua", "send", map.cmd, ret, nil, map)
        end
        -- 更新死亡时间
        local deadTime = dateEx.nowMS() + constDeadMs
        fleet:set_deadtime(deadTime)
    elseif fleet:get_task() == IDConstVals.FleetTask.voyage or fleet:get_task() == IDConstVals.FleetTask.back then
        if fleet:get_status() == IDConstVals.FleetState.docked then
            -- 如果是docked状态，只需要改变目标坐标,重新设置死亡时间,港口释放出来
            -- 更新死亡时间
            local deadTime = dateEx.nowMS() + constDeadMs
            fleet:set_deadtime(deadTime)
            local mapcell = dbworldmap.instanse(fleet:get_curpos())
            -- 如果港口中的舰队也是此出征的舰队，就释放港口
            if
                (not mapcell:isEmpty()) and mapcell:get_fidx() == fleet:get_idx() and
                    mapcell.get_type() == IDConstVals.WorldmapCellType.port
             then
                mapcell:delete()
                logic.pushMapCellChg(fleet:get_curpos(), false)
            end
        elseif fleet:get_status() == IDConstVals.FleetState.moving then
            -- 需要重新计算当前坐标
            local curPos, realPos = logic.getFleetRealCurPos(map.idx)
            fromPosV3 = realPos
            fleet:set_curpos(curPos)
        end
    elseif fleet:get_task() == IDConstVals.FleetState.fighting then
    --//TODO: 正在战斗， 只改变目标坐标
    end

    -- 处理移动数据
    logic.fleetMoveTo(fleet:get_idx(), fromPosV3, fleet:get_curpos(), map.toPos, IDConstVals.FleetTask.voyage)
    fleet:release()
    ret.code = Errcode.ok
    return skynet.call(NetProtoIsland, "lua", "send", map.cmd, ret, logic4fleet.getFleet(map.idx), map)
end

---@param map NetProtoIsland.RC_getFleet
CMD.getFleet = function(map, fd, agent)
    local ret = {}
    ret.code = Errcode.ok
    return skynet.call(NetProtoIsland, "lua", "send", map.cmd, ret, logic4fleet.getFleet(map.idx), map)
end

---@param map NetProtoIsland.RC_getAllFleets
CMD.getAllFleets = function(map, fd, agent)
    ---@type NetProtoIsland.ST_retInfor
    local ret = {}
    local list = dbfleet.getListBycidx(map.cidx)
    local fleets = {}
    for i, v in ipairs(list) do
        -- v.units = dbunit.getListByfidx(v[dbfleet.keys.idx])
        table.insert(fleets, logic4fleet.getFleet(v[dbfleet.keys.idx]))
    end
    list = nil
    ret.code = Errcode.ok
    return skynet.call(NetProtoIsland, "lua", "send", map.cmd, ret, fleets, map)
end
--============================================================
--============================================================
skynet.start(
    function()
        constCfg = cfgUtl.getConstCfg()
        gridSize = constCfg.GridWorld

        -- 初始化网格
        -- cellSize = 10
        grid = Grid.new()
        grid:init(Vector3.New(-gridSize * cellSize / 2, 0, -gridSize * cellSize / 2), gridSize, gridSize, cellSize)
        -- grid:init(Vector3.zero, gridSize, gridSize, cellSize)

        skynet.dispatch(
            "lua",
            function(_, _, command, ...)
                local f = CMD[command] or logic[command]
                skynet.ret(skynet.pack(f(...)))
            end
        )

        -- 启动一个线路处理推送变化的数量
        skynet.fork(loopPushPkg)

        -- 启动一个线路处理舰队移动及沉没
        skynet.fork(fleetPolling)

        skynet.register "LDSWorld"
    end
)
