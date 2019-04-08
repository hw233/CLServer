do
    ---@class NetProtoIsland
    local NetProtoIsland = {}
    local table = table
    local CMD = {}
    local skynet = require "skynet"

    require "skynet.manager"    -- import skynet.register
    require("BioUtl")

    NetProtoIsland.dispatch = {}
    --==============================
    -- public toMap
    NetProtoIsland._toMap = function(stuctobj, m)
        local ret = {}
        if m == nil then return ret end
        for k,v in pairs(m) do
            ret[k] = stuctobj.toMap(v)
        end
        return ret
    end
    -- public toList
    NetProtoIsland._toList = function(stuctobj, m)
        local ret = {}
        if m == nil then return ret end
        for i,v in ipairs(m) do
            table.insert(ret, stuctobj.toMap(v))
        end
        return ret
    end
    -- public parse
    NetProtoIsland._parseMap = function(stuctobj, m)
        local ret = {}
        if m == nil then return ret end
        for k,v in pairs(m) do
            ret[k] = stuctobj.parse(v)
        end
        return ret
    end
    -- public parse
    NetProtoIsland._parseList = function(stuctobj, m)
        local ret = {}
        if m == nil then return ret end
        for i,v in ipairs(m) do
            table.insert(ret, stuctobj.parse(v))
        end
        return ret
    end
  --==================================
  --==================================
    ---@class NetProtoIsland.ST_retInfor 返回信息
    NetProtoIsland.ST_retInfor = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[10] = m.msg  -- 返回消息 string
            r[11] =  BioUtl.number2bio(m.code)  -- 返回值 int
            return r;
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.msg = m[10] --  string
            r.code = m[11] --  int
            return r;
        end,
    }
    ---@class NetProtoIsland.ST_mapPage 一屏大地图数据
    NetProtoIsland.ST_mapPage = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[12] = NetProtoIsland._toList(NetProtoIsland.ST_mapCell, m.cells)  -- 地图数据 key=网络index, map
            r[13] =  BioUtl.number2bio(m.pageIdx)  -- 一屏所在的网格index  int
            return r;
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.cells = NetProtoIsland._parseList(NetProtoIsland.ST_mapCell, m[12])  -- 地图数据 key=网络index, map
            r.pageIdx = m[13] --  int
            return r;
        end,
    }
    ---@class NetProtoIsland.ST_dockyardShips 造船厂的舰船信息
    NetProtoIsland.ST_dockyardShips = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[14] = m.shipsMap  -- key=舰船的配置id, val=舰船数量 map
            r[15] =  BioUtl.number2bio(m.buildingIdx)  -- 造船厂的idx int
            return r;
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.shipsMap = m[14] --  table
            r.buildingIdx = m[15] --  int
            return r;
        end,
    }
    ---@class NetProtoIsland.ST_tile 建筑信息对象
    NetProtoIsland.ST_tile = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[16] =  BioUtl.number2bio(m.idx)  -- 唯一标识 int int
            r[17] =  BioUtl.number2bio(m.attrid)  -- 属性配置id int int
            r[18] =  BioUtl.number2bio(m.cidx)  -- 主城idx int int
            r[19] =  BioUtl.number2bio(m.pos)  -- 位置，即在城的gird中的index int int
            return r;
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[16] --  int
            r.attrid = m[17] --  int
            r.cidx = m[18] --  int
            r.pos = m[19] --  int
            return r;
        end,
    }
    ---@class NetProtoIsland.ST_building 建筑信息对象
    NetProtoIsland.ST_building = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[16] =  BioUtl.number2bio(m.idx)  -- 唯一标识 int int
            r[20] =  BioUtl.number2bio(m.val4)  -- 值4。如:产量，仓库的存储量等 int int
            r[21] =  BioUtl.number2bio(m.val3)  -- 值3。如:产量，仓库的存储量等 int int
            r[22] =  BioUtl.number2bio(m.val2)  -- 值2。如:产量，仓库的存储量等 int int
            r[23] =  BioUtl.number2bio(m.endtime)  -- 完成升级、恢复、采集等的时间点 long int
            r[24] =  BioUtl.number2bio(m.lev)  -- 等级 int int
            r[25] =  BioUtl.number2bio(m.val)  -- 值。如:产量，仓库的存储量等 int int
            r[18] =  BioUtl.number2bio(m.cidx)  -- 主城idx int int
            r[26] =  BioUtl.number2bio(m.val5)  -- 值5。如:产量，仓库的存储量等 int int
            r[17] =  BioUtl.number2bio(m.attrid)  -- 属性配置id int int
            r[27] =  BioUtl.number2bio(m.starttime)  -- 开始升级、恢复、采集等的时间点 long int
            r[28] =  BioUtl.number2bio(m.state)  -- 状态. 0：正常；1：升级中；9：恢复中 int
            r[19] =  BioUtl.number2bio(m.pos)  -- 位置，即在城的gird中的index int int
            return r;
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[16] --  int
            r.val4 = m[20] --  int
            r.val3 = m[21] --  int
            r.val2 = m[22] --  int
            r.endtime = m[23] --  int
            r.lev = m[24] --  int
            r.val = m[25] --  int
            r.cidx = m[18] --  int
            r.val5 = m[26] --  int
            r.attrid = m[17] --  int
            r.starttime = m[27] --  int
            r.state = m[28] --  int
            r.pos = m[19] --  int
            return r;
        end,
    }
    ---@class NetProtoIsland.ST_mapCell 大地图地块数据
    NetProtoIsland.ST_mapCell = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[16] =  BioUtl.number2bio(m.idx)  -- 网格index int
            r[29] =  BioUtl.number2bio(m.val1)  -- 值1 int
            r[18] =  BioUtl.number2bio(m.cidx)  -- 主城idx int
            r[21] =  BioUtl.number2bio(m.val3)  -- 值3 int
            r[30] =  BioUtl.number2bio(m.type)  -- 地块类型 1：玩家，2：npc int
            r[22] =  BioUtl.number2bio(m.val2)  -- 值2 int
            r[13] =  BioUtl.number2bio(m.pageIdx)  -- 所在屏的index int
            return r;
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[16] --  int
            r.val1 = m[29] --  int
            r.cidx = m[18] --  int
            r.val3 = m[21] --  int
            r.type = m[30] --  int
            r.val2 = m[22] --  int
            r.pageIdx = m[13] --  int
            return r;
        end,
    }
    ---@class NetProtoIsland.ST_resInfor 资源信息
    NetProtoIsland.ST_resInfor = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[31] =  BioUtl.number2bio(m.oil)  -- 油 int
            r[32] =  BioUtl.number2bio(m.gold)  -- 金 int
            r[33] =  BioUtl.number2bio(m.food)  -- 粮 int
            return r;
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.oil = m[31] --  int
            r.gold = m[32] --  int
            r.food = m[33] --  int
            return r;
        end,
    }
    ---@class NetProtoIsland.ST_city 主城
    NetProtoIsland.ST_city = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[16] =  BioUtl.number2bio(m.idx)  -- 唯一标识 int int
            r[34] = NetProtoIsland._toMap(NetProtoIsland.ST_tile, m.tiles)  -- 地块信息 key=idx, map
            r[35] = m.name  -- 名称 string
            r[36] = NetProtoIsland._toMap(NetProtoIsland.ST_building, m.buildings)  -- 建筑信息 key=idx, map
            r[24] =  BioUtl.number2bio(m.lev)  -- 等级 int int
            r[37] =  BioUtl.number2bio(m.status)  -- 状态 1:正常; int int
            r[19] =  BioUtl.number2bio(m.pos)  -- 城所在世界grid的index int int
            r[38] =  BioUtl.number2bio(m.pidx)  -- 玩家idx int int
            return r;
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[16] --  int
            r.tiles = NetProtoIsland._parseMap(NetProtoIsland.ST_tile, m[34])  -- 地块信息 key=idx, map
            r.name = m[35] --  string
            r.buildings = NetProtoIsland._parseMap(NetProtoIsland.ST_building, m[36])  -- 建筑信息 key=idx, map
            r.lev = m[24] --  int
            r.status = m[37] --  int
            r.pos = m[19] --  int
            r.pidx = m[38] --  int
            return r;
        end,
    }
    ---@class NetProtoIsland.ST_player 用户信息
    NetProtoIsland.ST_player = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[16] =  BioUtl.number2bio(m.idx)  -- 唯一标识 int int
            r[39] =  BioUtl.number2bio(m.diam)  -- 钻石 long int
            r[35] = m.name  -- 名字 string
            r[41] =  BioUtl.number2bio(m.unionidx)  -- 联盟id int int
            r[40] =  BioUtl.number2bio(m.cityidx)  -- 城池id int int
            r[24] =  BioUtl.number2bio(m.lev)  -- 等级 long int
            r[37] =  BioUtl.number2bio(m.status)  -- 状态 1：正常 int int
            return r;
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[16] --  int
            r.diam = m[39] --  int
            r.name = m[35] --  string
            r.unionidx = m[41] --  int
            r.cityidx = m[40] --  int
            r.lev = m[24] --  int
            r.status = m[37] --  int
            return r;
        end,
    }
    --==============================
    NetProtoIsland.recive = {
    -- 取得造船厂所有舰艇列表
    getShipsByBuildingIdx = function(map)
        local ret = {}
        ret.cmd = "getShipsByBuildingIdx"
        ret.__session__ = map[1]
        ret.callback = map[3]
        ret.buildingIdx = map[15]-- 造船厂的idx int
        return ret
    end,
    -- 升级建筑
    upLevBuilding = function(map)
        local ret = {}
        ret.cmd = "upLevBuilding"
        ret.__session__ = map[1]
        ret.callback = map[3]
        ret.idx = map[16]-- 建筑idx int
        return ret
    end,
    -- 移除建筑
    rmBuilding = function(map)
        local ret = {}
        ret.cmd = "rmBuilding"
        ret.__session__ = map[1]
        ret.callback = map[3]
        ret.idx = map[16]-- 地块idx int
        return ret
    end,
    -- 新建建筑
    newBuilding = function(map)
        local ret = {}
        ret.cmd = "newBuilding"
        ret.__session__ = map[1]
        ret.callback = map[3]
        ret.attrid = map[17]-- 建筑配置id int
        ret.pos = map[19]-- 位置 int
        return ret
    end,
    -- 登陆
    login = function(map)
        local ret = {}
        ret.cmd = "login"
        ret.__session__ = map[1]
        ret.callback = map[3]
        ret.uidx = map[49]-- 用户id
        ret.channel = map[50]-- 渠道号
        ret.deviceID = map[51]-- 机器码
        ret.isEditMode = map[52]-- 编辑模式
        return ret
    end,
    -- 当完成建造部分舰艇的通知
    onFinishBuildOneShip = function(map)
        local ret = {}
        ret.cmd = "onFinishBuildOneShip"
        ret.__session__ = map[1]
        ret.callback = map[3]
        ret.buildingIdx = map[15]-- 造船厂的idx int
        return ret
    end,
    -- 取得建筑
    getBuilding = function(map)
        local ret = {}
        ret.cmd = "getBuilding"
        ret.__session__ = map[1]
        ret.callback = map[3]
        ret.idx = map[16]-- 建筑idx int
        return ret
    end,
    -- 移除地块
    rmTile = function(map)
        local ret = {}
        ret.cmd = "rmTile"
        ret.__session__ = map[1]
        ret.callback = map[3]
        ret.idx = map[16]-- 地块idx int
        return ret
    end,
    -- 资源变化时推送
    onResChg = function(map)
        local ret = {}
        ret.cmd = "onResChg"
        ret.__session__ = map[1]
        ret.callback = map[3]
        return ret
    end,
    -- 移动建筑
    moveBuilding = function(map)
        local ret = {}
        ret.cmd = "moveBuilding"
        ret.__session__ = map[1]
        ret.callback = map[3]
        ret.idx = map[16]-- 建筑idx int
        ret.pos = map[19]-- 位置 int
        return ret
    end,
    -- 登出
    logout = function(map)
        local ret = {}
        ret.cmd = "logout"
        ret.__session__ = map[1]
        ret.callback = map[3]
        return ret
    end,
    -- 造船
    buildShip = function(map)
        local ret = {}
        ret.cmd = "buildShip"
        ret.__session__ = map[1]
        ret.callback = map[3]
        ret.buildingIdx = map[15]-- 造船厂的idx int
        ret.shipAttrID = map[58]-- 舰船配置id int
        ret.num = map[67]-- 数量 int
        return ret
    end,
    -- 立即升级建筑
    upLevBuildingImm = function(map)
        local ret = {}
        ret.cmd = "upLevBuildingImm"
        ret.__session__ = map[1]
        ret.callback = map[3]
        ret.idx = map[16]-- 建筑idx int
        return ret
    end,
    -- 新建地块
    newTile = function(map)
        local ret = {}
        ret.cmd = "newTile"
        ret.__session__ = map[1]
        ret.callback = map[3]
        ret.pos = map[19]-- 位置 int
        return ret
    end,
    -- 建筑变化时推送
    onBuildingChg = function(map)
        local ret = {}
        ret.cmd = "onBuildingChg"
        ret.__session__ = map[1]
        ret.callback = map[3]
        return ret
    end,
    -- 玩家信息变化时推送
    onPlayerChg = function(map)
        local ret = {}
        ret.cmd = "onPlayerChg"
        ret.__session__ = map[1]
        ret.callback = map[3]
        return ret
    end,
    -- 心跳
    heart = function(map)
        local ret = {}
        ret.cmd = "heart"
        ret.__session__ = map[1]
        ret.callback = map[3]
        return ret
    end,
    -- 取得一屏的在地图数据
    getMapDataByPageIdx = function(map)
        local ret = {}
        ret.cmd = "getMapDataByPageIdx"
        ret.__session__ = map[1]
        ret.callback = map[3]
        ret.pageIdx = map[13]-- 一屏所在的网格index
        return ret
    end,
    -- 移动地块
    moveTile = function(map)
        local ret = {}
        ret.cmd = "moveTile"
        ret.__session__ = map[1]
        ret.callback = map[3]
        ret.idx = map[16]-- 地块idx int
        ret.pos = map[19]-- 位置 int
        return ret
    end,
    -- 收集资源
    collectRes = function(map)
        local ret = {}
        ret.cmd = "collectRes"
        ret.__session__ = map[1]
        ret.callback = map[3]
        ret.idx = map[16]-- 资源建筑的idx int
        return ret
    end,
    -- 建筑升级完成
    onFinishBuildingUpgrade = function(map)
        local ret = {}
        ret.cmd = "onFinishBuildingUpgrade"
        ret.__session__ = map[1]
        ret.callback = map[3]
        return ret
    end,
    }
    --==============================
    NetProtoIsland.send = {
    getShipsByBuildingIdx = function(retInfor, dockyardShips, mapOrig) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 42
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[43] = NetProtoIsland.ST_dockyardShips.toMap(dockyardShips); -- 造船厂的idx int
        return ret
    end,
    upLevBuilding = function(retInfor, building, mapOrig) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 44
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[45] = NetProtoIsland.ST_building.toMap(building); -- 建筑信息
        return ret
    end,
    rmBuilding = function(retInfor, idx, mapOrig) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 46
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        if type(idx) == "number" then
            ret[16] = BioUtl.number2bio(idx); -- 被移除建筑的idx int
        else
            ret[16] = idx; -- 被移除建筑的idx int
        end
        return ret
    end,
    newBuilding = function(retInfor, building, mapOrig) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 47
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[45] = NetProtoIsland.ST_building.toMap(building); -- 建筑信息对象
        return ret
    end,
    login = function(retInfor, player, city, systime, session, mapOrig) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 48
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[53] = NetProtoIsland.ST_player.toMap(player); -- 玩家信息
        ret[54] = NetProtoIsland.ST_city.toMap(city); -- 主城信息
        if type(systime) == "number" then
            ret[55] = BioUtl.number2bio(systime); -- 系统时间 long
        else
            ret[55] = systime; -- 系统时间 long
        end
        if type(session) == "number" then
            ret[56] = BioUtl.number2bio(session); -- 会话id
        else
            ret[56] = session; -- 会话id
        end
        return ret
    end,
    onFinishBuildOneShip = function(retInfor, buildingIdx, shipAttrID, shipNum, mapOrig) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 57
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        if type(buildingIdx) == "number" then
            ret[15] = BioUtl.number2bio(buildingIdx); -- 造船厂的idx int
        else
            ret[15] = buildingIdx; -- 造船厂的idx int
        end
        if type(shipAttrID) == "number" then
            ret[58] = BioUtl.number2bio(shipAttrID); -- 航船的配置id
        else
            ret[58] = shipAttrID; -- 航船的配置id
        end
        if type(shipNum) == "number" then
            ret[59] = BioUtl.number2bio(shipNum); -- 航船的数量
        else
            ret[59] = shipNum; -- 航船的数量
        end
        return ret
    end,
    getBuilding = function(retInfor, building, mapOrig) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 60
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[45] = NetProtoIsland.ST_building.toMap(building); -- 建筑信息对象
        return ret
    end,
    rmTile = function(retInfor, idx, mapOrig) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 61
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        if type(idx) == "number" then
            ret[16] = BioUtl.number2bio(idx); -- 被移除地块的idx int
        else
            ret[16] = idx; -- 被移除地块的idx int
        end
        return ret
    end,
    onResChg = function(retInfor, resInfor, mapOrig) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 62
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[63] = NetProtoIsland.ST_resInfor.toMap(resInfor); -- 资源信息
        return ret
    end,
    moveBuilding = function(retInfor, building, mapOrig) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 64
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[45] = NetProtoIsland.ST_building.toMap(building); -- 建筑信息
        return ret
    end,
    logout = function(retInfor, mapOrig) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 65
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        return ret
    end,
    buildShip = function(retInfor, building, mapOrig) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 66
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[45] = NetProtoIsland.ST_building.toMap(building); -- 造船厂信息
        return ret
    end,
    upLevBuildingImm = function(retInfor, building, mapOrig) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 68
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[45] = NetProtoIsland.ST_building.toMap(building); -- 建筑信息
        return ret
    end,
    newTile = function(retInfor, tile, mapOrig) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 69
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[70] = NetProtoIsland.ST_tile.toMap(tile); -- 地块信息对象
        return ret
    end,
    onBuildingChg = function(retInfor, building, mapOrig) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 71
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[45] = NetProtoIsland.ST_building.toMap(building); -- 建筑信息
        return ret
    end,
    onPlayerChg = function(retInfor, player, mapOrig) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 72
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[53] = NetProtoIsland.ST_player.toMap(player); -- 玩家信息
        return ret
    end,
    heart = function(mapOrig) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 73
        ret[3] = mapOrig and mapOrig.callback or nil
        return ret
    end,
    getMapDataByPageIdx = function(retInfor, mapPage, mapOrig) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 74
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[75] = NetProtoIsland.ST_mapPage.toMap(mapPage); -- 在地图一屏数据 map
        return ret
    end,
    moveTile = function(retInfor, tile, mapOrig) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 76
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[70] = NetProtoIsland.ST_tile.toMap(tile); -- 地块信息
        return ret
    end,
    collectRes = function(retInfor, resType, resVal, building, mapOrig) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 77
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        if type(resType) == "number" then
            ret[78] = BioUtl.number2bio(resType); -- 收集的资源类型 int
        else
            ret[78] = resType; -- 收集的资源类型 int
        end
        if type(resVal) == "number" then
            ret[79] = BioUtl.number2bio(resVal); -- 收集到的资源量 int
        else
            ret[79] = resVal; -- 收集到的资源量 int
        end
        ret[45] = NetProtoIsland.ST_building.toMap(building); -- 建筑信息
        return ret
    end,
    onFinishBuildingUpgrade = function(retInfor, building, mapOrig) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 80
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[45] = NetProtoIsland.ST_building.toMap(building); -- 建筑信息
        return ret
    end,
    }
    --==============================
    NetProtoIsland.dispatch[42]={onReceive = NetProtoIsland.recive.getShipsByBuildingIdx, send = NetProtoIsland.send.getShipsByBuildingIdx, logicName = "cmd4city"}
    NetProtoIsland.dispatch[44]={onReceive = NetProtoIsland.recive.upLevBuilding, send = NetProtoIsland.send.upLevBuilding, logicName = "cmd4city"}
    NetProtoIsland.dispatch[46]={onReceive = NetProtoIsland.recive.rmBuilding, send = NetProtoIsland.send.rmBuilding, logicName = "cmd4city"}
    NetProtoIsland.dispatch[47]={onReceive = NetProtoIsland.recive.newBuilding, send = NetProtoIsland.send.newBuilding, logicName = "cmd4city"}
    NetProtoIsland.dispatch[48]={onReceive = NetProtoIsland.recive.login, send = NetProtoIsland.send.login, logicName = "cmd4player"}
    NetProtoIsland.dispatch[57]={onReceive = NetProtoIsland.recive.onFinishBuildOneShip, send = NetProtoIsland.send.onFinishBuildOneShip, logicName = "cmd4city"}
    NetProtoIsland.dispatch[60]={onReceive = NetProtoIsland.recive.getBuilding, send = NetProtoIsland.send.getBuilding, logicName = "cmd4city"}
    NetProtoIsland.dispatch[61]={onReceive = NetProtoIsland.recive.rmTile, send = NetProtoIsland.send.rmTile, logicName = "cmd4city"}
    NetProtoIsland.dispatch[62]={onReceive = NetProtoIsland.recive.onResChg, send = NetProtoIsland.send.onResChg, logicName = "cmd4city"}
    NetProtoIsland.dispatch[64]={onReceive = NetProtoIsland.recive.moveBuilding, send = NetProtoIsland.send.moveBuilding, logicName = "cmd4city"}
    NetProtoIsland.dispatch[65]={onReceive = NetProtoIsland.recive.logout, send = NetProtoIsland.send.logout, logicName = "cmd4player"}
    NetProtoIsland.dispatch[66]={onReceive = NetProtoIsland.recive.buildShip, send = NetProtoIsland.send.buildShip, logicName = "cmd4city"}
    NetProtoIsland.dispatch[68]={onReceive = NetProtoIsland.recive.upLevBuildingImm, send = NetProtoIsland.send.upLevBuildingImm, logicName = "cmd4city"}
    NetProtoIsland.dispatch[69]={onReceive = NetProtoIsland.recive.newTile, send = NetProtoIsland.send.newTile, logicName = "cmd4city"}
    NetProtoIsland.dispatch[71]={onReceive = NetProtoIsland.recive.onBuildingChg, send = NetProtoIsland.send.onBuildingChg, logicName = "cmd4city"}
    NetProtoIsland.dispatch[72]={onReceive = NetProtoIsland.recive.onPlayerChg, send = NetProtoIsland.send.onPlayerChg, logicName = "cmd4player"}
    NetProtoIsland.dispatch[73]={onReceive = NetProtoIsland.recive.heart, send = NetProtoIsland.send.heart, logicName = "cmd4com"}
    NetProtoIsland.dispatch[74]={onReceive = NetProtoIsland.recive.getMapDataByPageIdx, send = NetProtoIsland.send.getMapDataByPageIdx, logicName = "LDSWorld"}
    NetProtoIsland.dispatch[76]={onReceive = NetProtoIsland.recive.moveTile, send = NetProtoIsland.send.moveTile, logicName = "cmd4city"}
    NetProtoIsland.dispatch[77]={onReceive = NetProtoIsland.recive.collectRes, send = NetProtoIsland.send.collectRes, logicName = "cmd4city"}
    NetProtoIsland.dispatch[80]={onReceive = NetProtoIsland.recive.onFinishBuildingUpgrade, send = NetProtoIsland.send.onFinishBuildingUpgrade, logicName = "cmd4city"}
    --==============================
    NetProtoIsland.cmds = {
        getShipsByBuildingIdx = "getShipsByBuildingIdx", -- 取得造船厂所有舰艇列表,
        upLevBuilding = "upLevBuilding", -- 升级建筑,
        rmBuilding = "rmBuilding", -- 移除建筑,
        newBuilding = "newBuilding", -- 新建建筑,
        login = "login", -- 登陆,
        onFinishBuildOneShip = "onFinishBuildOneShip", -- 当完成建造部分舰艇的通知,
        getBuilding = "getBuilding", -- 取得建筑,
        rmTile = "rmTile", -- 移除地块,
        onResChg = "onResChg", -- 资源变化时推送,
        moveBuilding = "moveBuilding", -- 移动建筑,
        logout = "logout", -- 登出,
        buildShip = "buildShip", -- 造船,
        upLevBuildingImm = "upLevBuildingImm", -- 立即升级建筑,
        newTile = "newTile", -- 新建地块,
        onBuildingChg = "onBuildingChg", -- 建筑变化时推送,
        onPlayerChg = "onPlayerChg", -- 玩家信息变化时推送,
        heart = "heart", -- 心跳,
        getMapDataByPageIdx = "getMapDataByPageIdx", -- 取得一屏的在地图数据,
        moveTile = "moveTile", -- 移动地块,
        collectRes = "collectRes", -- 收集资源,
        onFinishBuildingUpgrade = "onFinishBuildingUpgrade", -- 建筑升级完成
    }

    --==============================
    function CMD.dispatcher(agent, map, client_fd)
        if map == nil then
            skynet.error("[dispatcher] map == nil")
            return nil
        end
        local cmd = map[0]
        if cmd == nil then
            skynet.error("get cmd is nil")
            return nil;
        end
        local dis = NetProtoIsland.dispatch[cmd]
        if dis == nil then
            skynet.error("get protocol cfg is nil")
            return nil;
        end
        local m = dis.onReceive(map)
        local logicProc = skynet.call(agent, "lua", "getLogic", dis.logicName)
        if logicProc == nil then
            skynet.error("get logicServe is nil. serverName=[" .. dis.loginAccount .."]")
            return nil
        else
            return skynet.call(logicProc, "lua", m.cmd, m, client_fd, agent)
        end
    end
    --==============================
    skynet.start(function()
        skynet.dispatch("lua", function(_, _, command, command2, ...)
            if command == "send" then
                local f = NetProtoIsland.send[command2]
                skynet.ret(skynet.pack(f(...)))
            else
                local f = CMD[command]
                skynet.ret(skynet.pack(f(command2, ...)))
            end
        end)
    
        skynet.register "NetProtoIsland"
    end)
end
