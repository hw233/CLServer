do
    ---@class NetProtoIsland
    NetProtoIsland = {}
    local cmd4player = require("cmd4player")
    local table = table
    local skynet = require "skynet"

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
    -- 返回信息
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
    -- 用户信息
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
    -- 主城
    NetProtoIsland.ST_city = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[12] =  BioUtl.int2bio(m.idx)  -- 唯一标识 int int
            r[31] =  BioUtl.int2bio(m.levpos)  -- 等级 int int
            r[13] = m.name  -- 名称 string
            r[32] = NetProtoIsland._toMap(NetProtoIsland.ST_building, m.buildings)  -- 建筑信息 key=idx, map
            r[33] =  BioUtl.int2bio(m.pos)  -- 城所在世界grid的index int int
            r[34] =  BioUtl.int2bio(m.statuspos)  -- 状态 1:正常; int int
            r[35] =  BioUtl.int2bio(m.pidx)  -- 玩家idx int int
            return r;
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[12] --  int
            r.levpos = m[31] --  int
            r.name = m[13] --  string
            r.buildings = NetProtoIsland._parseMap(NetProtoIsland.ST_building, m.buildings)  -- 建筑信息 key=idx, map
            r.pos = m[33] --  int
            r.statuspos = m[34] --  int
            r.pidx = m[35] --  int
            return r;
        end,
    }
    -- 建筑对象
    NetProtoIsland.ST_building = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[12] =  BioUtl.int2bio(m.idx)  -- 唯一标识 int int
            r[36] =  BioUtl.int2bio(m.levidx)  -- 等级 int int
            r[37] =  BioUtl.int2bio(m.validx)  -- 值。如:产量，仓库的存储量等 int int
            r[38] =  BioUtl.int2bio(m.cidxidx)  -- 主城idx int int
            r[39] =  BioUtl.int2bio(m.val2idx)  -- 值2。如:产量，仓库的存储量等 int int
            r[40] =  BioUtl.int2bio(m.val3idx)  -- 值3。如:产量，仓库的存储量等 int int
            r[41] =  BioUtl.int2bio(m.val4idx)  -- 值4。如:产量，仓库的存储量等 int int
            r[42] =  BioUtl.int2bio(m.attrididx)  -- 属性配置id int int
            r[43] =  BioUtl.int2bio(m.posidx)  -- 位置，即在城的gird中的index int int
            return r;
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[12] --  int
            r.levidx = m[36] --  int
            r.validx = m[37] --  int
            r.cidxidx = m[38] --  int
            r.val2idx = m[39] --  int
            r.val3idx = m[40] --  int
            r.val4idx = m[41] --  int
            r.attrididx = m[42] --  int
            r.posidx = m[43] --  int
            return r;
        end,
    }
    --==============================
    NetProtoIsland.recive = {
    -- 数据释放，客户端不用调用，服务器内部调用的指令
    release = function(map)
        local ret = {}
        ret.cmd = "release"
        ret.__session__ = map[1]
        return ret
    end,
    -- 登出
    logout = function(map)
        local ret = {}
        ret.cmd = "logout"
        ret.__session__ = map[1]
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
    -- 停服，客户端不用调用，服务器内部调用的指令
    stopserver = function(map)
        local ret = {}
        ret.cmd = "stopserver"
        ret.__session__ = map[1]
        return ret
    end,
    }
    --==============================
    NetProtoIsland.send = {
    release = function()
        local ret = {}
        ret[0] = 14
        return ret
    end,
    logout = function(retInfor)
        local ret = {}
        ret[0] = 15
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
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
    stopserver = function()
        local ret = {}
        ret[0] = 25
        return ret
    end,
    }
    --==============================
    NetProtoIsland.dispatch[14]={onReceive = NetProtoIsland.recive.release, send = NetProtoIsland.send.release, logic = cmd4player}
    NetProtoIsland.dispatch[15]={onReceive = NetProtoIsland.recive.logout, send = NetProtoIsland.send.logout, logic = cmd4player}
    NetProtoIsland.dispatch[16]={onReceive = NetProtoIsland.recive.login, send = NetProtoIsland.send.login, logic = cmd4player}
    NetProtoIsland.dispatch[25]={onReceive = NetProtoIsland.recive.stopserver, send = NetProtoIsland.send.stopserver, logic = cmd4player}
    --==============================
    NetProtoIsland.cmds = {
        release = "release",
        logout = "logout",
        login = "login",
        stopserver = "stopserver"
    }

    --==============================
    function NetProtoIsland.dispatcher(map, client_fd)
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
        local logicCMD = assert(dis.logic.CMD)
        local f = assert(logicCMD[m.cmd])
        if f then
            return f(m, client_fd)
        end
        return nil;
    end
    --==============================
    return NetProtoIsland
end