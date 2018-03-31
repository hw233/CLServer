do
    ---@class NetProtoIsland
    NetProtoIsland = {}
    local table = table
    require("bio.BioUtl")

    NetProtoIsland.__sessionID = 0; -- 会话ID
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
            r[11] = m.code  -- 返回值 int
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
    ---@class NetProtoIsland.ST_player 用户信息
    NetProtoIsland.ST_player = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[12] = m.idx  -- 唯一标识 int int
            r[29] = m.diam  -- 钻石 long int
            r[13] = m.name  -- 名字 string
            r[26] = m.status  -- 状态 1：正常 int int
            r[28] = m.cityidx  -- 城池id int int
            r[27] = m.unionidx  -- 联盟id int int
            r[30] = m.lev  -- 等级 long int
            return r;
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[12] --  int
            r.diam = m[29] --  int
            r.name = m[13] --  string
            r.status = m[26] --  int
            r.cityidx = m[28] --  int
            r.unionidx = m[27] --  int
            r.lev = m[30] --  int
            return r;
        end,
    }
    ---@class NetProtoIsland.ST_city 主城
    NetProtoIsland.ST_city = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[12] = m.idx  -- 唯一标识 int int
            r[45] = NetProtoIsland._toMap(NetProtoIsland.ST_tile, m.tiles)  -- 地块信息 key=idx, map
            r[13] = m.name  -- 名称 string
            r[26] = m.status  -- 状态 1:正常; int int
            r[32] = NetProtoIsland._toMap(NetProtoIsland.ST_building, m.buildings)  -- 建筑信息 key=idx, map
            r[30] = m.lev  -- 等级 int int
            r[33] = m.pos  -- 城所在世界grid的index int int
            r[35] = m.pidx  -- 玩家idx int int
            return r;
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[12] --  int
            r.tiles = NetProtoIsland._parseMap(NetProtoIsland.ST_tile, m[45])  -- 地块信息 key=idx, map
            r.name = m[13] --  string
            r.status = m[26] --  int
            r.buildings = NetProtoIsland._parseMap(NetProtoIsland.ST_building, m[32])  -- 建筑信息 key=idx, map
            r.lev = m[30] --  int
            r.pos = m[33] --  int
            r.pidx = m[35] --  int
            return r;
        end,
    }
    ---@class NetProtoIsland.ST_tile 建筑信息对象
    NetProtoIsland.ST_tile = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[12] = m.idx  -- 唯一标识 int int
            r[46] = m.attrid  -- 属性配置id int int
            r[47] = m.cidx  -- 主城idx int int
            r[33] = m.pos  -- 位置，即在城的gird中的index int int
            return r;
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[12] --  int
            r.attrid = m[46] --  int
            r.cidx = m[47] --  int
            r.pos = m[33] --  int
            return r;
        end,
    }
    ---@class NetProtoIsland.ST_building 建筑信息对象
    NetProtoIsland.ST_building = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[12] = m.idx  -- 唯一标识 int int
            r[48] = m.val4  -- 值4。如:产量，仓库的存储量等 int int
            r[49] = m.val3  -- 值3。如:产量，仓库的存储量等 int int
            r[50] = m.val2  -- 值2。如:产量，仓库的存储量等 int int
            r[30] = m.lev  -- 等级 int int
            r[47] = m.cidx  -- 主城idx int int
            r[46] = m.attrid  -- 属性配置id int int
            r[51] = m.val  -- 值。如:产量，仓库的存储量等 int int
            r[33] = m.pos  -- 位置，即在城的gird中的index int int
            return r;
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[12] --  int
            r.val4 = m[48] --  int
            r.val3 = m[49] --  int
            r.val2 = m[50] --  int
            r.lev = m[30] --  int
            r.cidx = m[47] --  int
            r.attrid = m[46] --  int
            r.val = m[51] --  int
            r.pos = m[33] --  int
            return r;
        end,
    }
    --==============================
    NetProtoIsland.send = {
    -- 移动建筑
    moveBuilding = function(idx, pos)
        local ret = {}
        ret[0] = 56
        ret[1] = NetProtoIsland.__sessionID
        ret[12] = idx; -- 建筑idx int
        ret[33] = pos; -- 位置 int
        return ret
    end,
    -- 登出
    logout = function()
        local ret = {}
        ret[0] = 15
        ret[1] = NetProtoIsland.__sessionID
        return ret
    end,
    -- 新建建筑
    newBuilding = function(attrid, pos)
        local ret = {}
        ret[0] = 52
        ret[1] = NetProtoIsland.__sessionID
        ret[46] = attrid; -- 建筑配置id int
        ret[33] = pos; -- 位置 int
        return ret
    end,
    -- 登陆
    login = function(uidx, channel, deviceID)
        local ret = {}
        ret[0] = 16
        ret[1] = NetProtoIsland.__sessionID
        ret[17] = uidx; -- 用户id
        ret[18] = channel; -- 渠道号
        ret[19] = deviceID; -- 机器码
        return ret
    end,
    -- 心跳
    heart = function()
        local ret = {}
        ret[0] = 59
        ret[1] = NetProtoIsland.__sessionID
        return ret
    end,
    -- 数据释放，客户端不用调用，服务器内部调用的指令
    release = function()
        local ret = {}
        ret[0] = 14
        ret[1] = NetProtoIsland.__sessionID
        return ret
    end,
    -- 移动地块
    moveTile = function(idx, pos)
        local ret = {}
        ret[0] = 57
        ret[1] = NetProtoIsland.__sessionID
        ret[12] = idx; -- 地块idx int
        ret[33] = pos; -- 位置 int
        return ret
    end,
    -- 取得建筑
    getBuilding = function(idx)
        local ret = {}
        ret[0] = 55
        ret[1] = NetProtoIsland.__sessionID
        ret[12] = idx; -- 建筑idx int
        return ret
    end,
    -- 升级建筑
    upLevBuilding = function(idx)
        local ret = {}
        ret[0] = 54
        ret[1] = NetProtoIsland.__sessionID
        ret[12] = idx; -- 建筑idx int
        return ret
    end,
    }
    --==============================
    NetProtoIsland.recive = {
    moveBuilding = function(map)
        local ret = {}
        ret.cmd = "moveBuilding"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.building = NetProtoIsland.ST_building.parse(map[53]) -- 建筑信息
        return ret
    end,
    logout = function(map)
        local ret = {}
        ret.cmd = "logout"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        return ret
    end,
    newBuilding = function(map)
        local ret = {}
        ret.cmd = "newBuilding"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.building = NetProtoIsland.ST_building.parse(map[53]) -- 建筑信息对象
        return ret
    end,
    login = function(map)
        local ret = {}
        ret.cmd = "login"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.player = NetProtoIsland.ST_player.parse(map[20]) -- 玩家信息
        ret.city = NetProtoIsland.ST_city.parse(map[44]) -- 主城信息
        ret.systime = map[21]-- 系统时间 long
        ret.session = map[22]-- 会话id
        return ret
    end,
    heart = function(map)
        local ret = {}
        ret.cmd = "heart"
        return ret
    end,
    release = function(map)
        local ret = {}
        ret.cmd = "release"
        return ret
    end,
    moveTile = function(map)
        local ret = {}
        ret.cmd = "moveTile"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.tile = NetProtoIsland.ST_tile.parse(map[58]) -- 地块信息
        return ret
    end,
    getBuilding = function(map)
        local ret = {}
        ret.cmd = "getBuilding"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.building = NetProtoIsland.ST_building.parse(map[53]) -- 建筑信息对象
        return ret
    end,
    upLevBuilding = function(map)
        local ret = {}
        ret.cmd = "upLevBuilding"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.building = NetProtoIsland.ST_building.parse(map[53]) -- 
        return ret
    end,
    }
    --==============================
    NetProtoIsland.dispatch[56]={onReceive = NetProtoIsland.recive.moveBuilding, send = NetProtoIsland.send.moveBuilding}
    NetProtoIsland.dispatch[15]={onReceive = NetProtoIsland.recive.logout, send = NetProtoIsland.send.logout}
    NetProtoIsland.dispatch[52]={onReceive = NetProtoIsland.recive.newBuilding, send = NetProtoIsland.send.newBuilding}
    NetProtoIsland.dispatch[16]={onReceive = NetProtoIsland.recive.login, send = NetProtoIsland.send.login}
    NetProtoIsland.dispatch[59]={onReceive = NetProtoIsland.recive.heart, send = NetProtoIsland.send.heart}
    NetProtoIsland.dispatch[14]={onReceive = NetProtoIsland.recive.release, send = NetProtoIsland.send.release}
    NetProtoIsland.dispatch[57]={onReceive = NetProtoIsland.recive.moveTile, send = NetProtoIsland.send.moveTile}
    NetProtoIsland.dispatch[55]={onReceive = NetProtoIsland.recive.getBuilding, send = NetProtoIsland.send.getBuilding}
    NetProtoIsland.dispatch[54]={onReceive = NetProtoIsland.recive.upLevBuilding, send = NetProtoIsland.send.upLevBuilding}
    --==============================
    NetProtoIsland.cmds = {
        moveBuilding = "moveBuilding",
        logout = "logout",
        newBuilding = "newBuilding",
        login = "login",
        heart = "heart",
        release = "release",
        moveTile = "moveTile",
        getBuilding = "getBuilding",
        upLevBuilding = "upLevBuilding"
    }
    --==============================
    return NetProtoIsland
end