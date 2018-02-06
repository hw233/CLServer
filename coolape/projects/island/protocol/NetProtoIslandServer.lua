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
            r[12] =  BioUtl.int2bio(m.idx)  -- 唯一标识 int
            r[13] = m.name  -- 名字 string
            return r;
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[12] --  int
            r.name = m[13] --  string
            return r;
        end,
    }
    --==============================
    NetProtoIsland.recive = {
    -- 停服，客户端不用调用，服务器内部调用的指令
    stopserver = function(map)
        local ret = {}
        ret.cmd = "stopserver"
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
    -- 注册
    regist = function(map)
        local ret = {}
        ret.cmd = "regist"
        ret.__session__ = map[1]
        ret.uidx = map[17]-- 用户id
        ret.name = map[13]-- 名字
        ret.icon = map[24]-- 头像
        ret.channel = map[18]-- 渠道号
        ret.deviceID = map[19]-- 机器码
        return ret
    end,
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
    }
    --==============================
    NetProtoIsland.send = {
    stopserver = function()
        local ret = {}
        ret[0] = 25
        return ret
    end,
    login = function(retInfor, player, systime, session)
        local ret = {}
        ret[0] = 16
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[20] = NetProtoIsland.ST_player.toMap(player); -- 玩家信息
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
    regist = function(retInfor, player, systime, session)
        local ret = {}
        ret[0] = 23
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[20] = NetProtoIsland.ST_player.toMap(player); -- 玩家信息
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
    }
    --==============================
    NetProtoIsland.dispatch[25]={onReceive = NetProtoIsland.recive.stopserver, send = NetProtoIsland.send.stopserver, logic = cmd4player}
    NetProtoIsland.dispatch[16]={onReceive = NetProtoIsland.recive.login, send = NetProtoIsland.send.login, logic = cmd4player}
    NetProtoIsland.dispatch[23]={onReceive = NetProtoIsland.recive.regist, send = NetProtoIsland.send.regist, logic = cmd4player}
    NetProtoIsland.dispatch[14]={onReceive = NetProtoIsland.recive.release, send = NetProtoIsland.send.release, logic = cmd4player}
    NetProtoIsland.dispatch[15]={onReceive = NetProtoIsland.recive.logout, send = NetProtoIsland.send.logout, logic = cmd4player}
    --==============================
    NetProtoIsland.cmds = {
        stopserver = "stopserver",
        login = "login",
        regist = "regist",
        release = "release",
        logout = "logout"
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