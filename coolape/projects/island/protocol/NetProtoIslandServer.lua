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
            r[11] =  BioUtl.int2bio(m.code)  -- 返回值 int
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
            r[12] =  BioUtl.int2bio(m.idx)  -- 唯一标识 int int
            r[26] =  BioUtl.int2bio(m.status)  -- 状态 1：正常 int int
            r[13] = m.name  -- 名字 string
            r[27] =  BioUtl.int2bio(m.unionidx)  -- 联盟id int int
            r[28] =  BioUtl.int2bio(m.cityidx)  -- 城池id int int
            r[29] =  BioUtl.int2bio(m.diam)  -- 钻石 long int
            r[30] =  BioUtl.int2bio(m.lev)  -- 等级 long int
            return r;
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[12] --  int
            r.status = m[26] --  int
            r.name = m[13] --  string
            r.unionidx = m[27] --  int
            r.cityidx = m[28] --  int
            r.diam = m[29] --  int
            r.lev = m[30] --  int
            return r;
        end,
    }
    ---@class NetProtoIsland.ST_city 主城
    NetProtoIsland.ST_city = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[12] =  BioUtl.int2bio(m.idx)  -- 唯一标识 int int
            r[26] =  BioUtl.int2bio(m.status)  -- 状态 1:正常; int int
            r[13] = m.name  -- 名称 string
            r[45] = NetProtoIsland._toMap(NetProtoIsland.ST_tile, m.tiles)  -- 地块信息 key=idx, map
            r[32] = NetProtoIsland._toMap(NetProtoIsland.ST_building, m.buildings)  -- 建筑信息 key=idx, map
            r[30] =  BioUtl.int2bio(m.lev)  -- 等级 int int
            r[33] =  BioUtl.int2bio(m.pos)  -- 城所在世界grid的index int int
            r[35] =  BioUtl.int2bio(m.pidx)  -- 玩家idx int int
            return r;
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[12] --  int
            r.status = m[26] --  int
            r.name = m[13] --  string
            r.tiles = NetProtoIsland._parseMap(NetProtoIsland.ST_tile, m[45])  -- 地块信息 key=idx, map
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
            r[12] =  BioUtl.int2bio(m.idx)  -- 唯一标识 int int
            r[46] =  BioUtl.int2bio(m.attrid)  -- 属性配置id int int
            r[47] =  BioUtl.int2bio(m.cidx)  -- 主城idx int int
            r[33] =  BioUtl.int2bio(m.pos)  -- 位置，即在城的gird中的index int int
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
            r[12] =  BioUtl.int2bio(m.idx)  -- 唯一标识 int int
            r[48] =  BioUtl.int2bio(m.val4)  -- 值4。如:产量，仓库的存储量等 int int
            r[49] =  BioUtl.int2bio(m.val3)  -- 值3。如:产量，仓库的存储量等 int int
            r[50] =  BioUtl.int2bio(m.val2)  -- 值2。如:产量，仓库的存储量等 int int
            r[30] =  BioUtl.int2bio(m.lev)  -- 等级 int int
            r[47] =  BioUtl.int2bio(m.cidx)  -- 主城idx int int
            r[46] =  BioUtl.int2bio(m.attrid)  -- 属性配置id int int
            r[51] =  BioUtl.int2bio(m.val)  -- 值。如:产量，仓库的存储量等 int int
            r[33] =  BioUtl.int2bio(m.pos)  -- 位置，即在城的gird中的index int int
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
    NetProtoIsland.recive = {
    -- 移动建筑
    moveBuilding = function(map)
        local ret = {}
        ret.cmd = "moveBuilding"
        ret.__session__ = map[1]
        ret.idx = map[12]-- 建筑idx int
        ret.pos = map[33]-- 位置 int
        return ret
    end,
    -- 登出
    logout = function(map)
        local ret = {}
        ret.cmd = "logout"
        ret.__session__ = map[1]
        return ret
    end,
    -- 新建建筑
    newBuilding = function(map)
        local ret = {}
        ret.cmd = "newBuilding"
        ret.__session__ = map[1]
        ret.attrid = map[46]-- 建筑配置id int
        ret.pos = map[33]-- 位置 int
        return ret
    end,
    -- 登陆
    login = function(map)
        local ret = {}
        ret.cmd = "login"
        ret.__session__ = map[1]
        ret.uidx = map[17]-- 用户id
        ret.channel = map[18]-- 渠道号
        ret.deviceID = map[19]-- 机器码
        return ret
    end,
    -- 心跳
    heart = function(map)
        local ret = {}
        ret.cmd = "heart"
        ret.__session__ = map[1]
        return ret
    end,
    -- 数据释放，客户端不用调用，服务器内部调用的指令
    release = function(map)
        local ret = {}
        ret.cmd = "release"
        ret.__session__ = map[1]
        return ret
    end,
    -- 移动地块
    moveTile = function(map)
        local ret = {}
        ret.cmd = "moveTile"
        ret.__session__ = map[1]
        ret.idx = map[12]-- 地块idx int
        ret.pos = map[33]-- 位置 int
        return ret
    end,
    -- 取得建筑
    getBuilding = function(map)
        local ret = {}
        ret.cmd = "getBuilding"
        ret.__session__ = map[1]
        ret.idx = map[12]-- 建筑idx int
        return ret
    end,
    -- 升级建筑
    upLevBuilding = function(map)
        local ret = {}
        ret.cmd = "upLevBuilding"
        ret.__session__ = map[1]
        ret.idx = map[12]-- 建筑idx int
        return ret
    end,
    }
    --==============================
    NetProtoIsland.send = {
    moveBuilding = function(retInfor, building)
        local ret = {}
        ret[0] = 56
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[53] = NetProtoIsland.ST_building.toMap(building); -- 建筑信息
        return ret
    end,
    logout = function(retInfor)
        local ret = {}
        ret[0] = 15
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        return ret
    end,
    newBuilding = function(retInfor, building)
        local ret = {}
        ret[0] = 52
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[53] = NetProtoIsland.ST_building.toMap(building); -- 建筑信息对象
        return ret
    end,
    login = function(retInfor, player, city, systime, session)
        local ret = {}
        ret[0] = 16
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[20] = NetProtoIsland.ST_player.toMap(player); -- 玩家信息
        ret[44] = NetProtoIsland.ST_city.toMap(city); -- 主城信息
        if type(systime) == "number" then
            ret[21] = BioUtl.number2bio(systime); -- 系统时间 long
        else
            ret[21] = systime; -- 系统时间 long
        end
        if type(session) == "number" then
            ret[22] = BioUtl.number2bio(session); -- 会话id
        else
            ret[22] = session; -- 会话id
        end
        return ret
    end,
    heart = function()
        local ret = {}
        ret[0] = 59
        return ret
    end,
    release = function()
        local ret = {}
        ret[0] = 14
        return ret
    end,
    moveTile = function(retInfor, tile)
        local ret = {}
        ret[0] = 57
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[58] = NetProtoIsland.ST_tile.toMap(tile); -- 地块信息
        return ret
    end,
    getBuilding = function(retInfor, building)
        local ret = {}
        ret[0] = 55
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[53] = NetProtoIsland.ST_building.toMap(building); -- 建筑信息对象
        return ret
    end,
    upLevBuilding = function(retInfor, building)
        local ret = {}
        ret[0] = 54
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[53] = NetProtoIsland.ST_building.toMap(building); -- 
        return ret
    end,
    }
    --==============================
    NetProtoIsland.dispatch[56]={onReceive = NetProtoIsland.recive.moveBuilding, send = NetProtoIsland.send.moveBuilding, logicName = "cmd4city"}
    NetProtoIsland.dispatch[15]={onReceive = NetProtoIsland.recive.logout, send = NetProtoIsland.send.logout, logicName = "cmd4player"}
    NetProtoIsland.dispatch[52]={onReceive = NetProtoIsland.recive.newBuilding, send = NetProtoIsland.send.newBuilding, logicName = "cmd4city"}
    NetProtoIsland.dispatch[16]={onReceive = NetProtoIsland.recive.login, send = NetProtoIsland.send.login, logicName = "cmd4player"}
    NetProtoIsland.dispatch[59]={onReceive = NetProtoIsland.recive.heart, send = NetProtoIsland.send.heart, logicName = "cmd4com"}
    NetProtoIsland.dispatch[14]={onReceive = NetProtoIsland.recive.release, send = NetProtoIsland.send.release, logicName = "cmd4player"}
    NetProtoIsland.dispatch[57]={onReceive = NetProtoIsland.recive.moveTile, send = NetProtoIsland.send.moveTile, logicName = "cmd4city"}
    NetProtoIsland.dispatch[55]={onReceive = NetProtoIsland.recive.getBuilding, send = NetProtoIsland.send.getBuilding, logicName = "cmd4city"}
    NetProtoIsland.dispatch[54]={onReceive = NetProtoIsland.recive.upLevBuilding, send = NetProtoIsland.send.upLevBuilding, logicName = "cmd4city"}
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
    function CMD.dispatcher(agent, map, client_fd)
        if map == nil then
            skynet.error("[dispatcher] mpa == nil")
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
        local logicCMD = skynet.call(agent, "lua", "getLogic", m.logicName)
        local f = assert(logicCMD[m.cmd])
        if f then
            return f(m, client_fd)
        end
        return nil
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
    
        skynet.register ("NetProtoIsland")
    end)
