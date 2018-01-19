do
    UsermgrHttpProto = {}
    local cmd4user = require("cmd4user")
    local table = table
    local skynet = require "skynet"

    require("BioUtl")

    UsermgrHttpProto.dispatch = {}
    --==============================
    -- public toMap
    UsermgrHttpProto._toMap = function(stuctobj, m)
        local ret = {}
        if m == nil then return ret end
        for k,v in pairs(m) do
            ret[k] = stuctobj.toMap(v)
        end
        return ret
    end
    -- public toList
    UsermgrHttpProto._toList = function(stuctobj, m)
        local ret = {}
        if m == nil then return ret end
        for i,v in ipairs(m) do
            table.insert(ret, stuctobj.toMap(v))
        end
        return ret
    end
    -- public parse
    UsermgrHttpProto._parseMap = function(stuctobj, m)
        local ret = {}
        if m == nil then return ret end
        for k,v in pairs(m) do
            ret[k] = stuctobj.parse(v)
        end
        return ret
    end
    -- public parse
    UsermgrHttpProto._parseList = function(stuctobj, m)
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
    UsermgrHttpProto.ST_retInfor = {
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
    -- 服务器
    UsermgrHttpProto.ST_server = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[13] =  BioUtl.int2bio(m.idx)  -- id int
            r[15] =  BioUtl.int2bio(m.status)  -- 状态 0:正常; 1:爆满; 2:维护 int
            r[14] = m.name  -- 名称 string
            return r;
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[13] --  int
            r.status = m[15] --  int
            r.name = m[14] --  string
            return r;
        end,
    }
    -- 用户信息
    UsermgrHttpProto.ST_userInfor = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[13] =  BioUtl.int2bio(m.idx)  -- 唯一标识 int
            r[14] = m.name  -- 名字 string
            return r;
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[13] --  int
            r.name = m[14] --  string
            return r;
        end,
    }
    --==============================
    UsermgrHttpProto.recive = {
    -- 登陆
    login = function(map)
        local ret = {}
        ret.cmd = "login"
        ret.__session__ = map[1]
        ret.userId = map[21]-- 用户名
        ret.password = map[22]-- 密码
        ret.appid = map[17]-- 应用id
        return ret
    end,
    -- 注册
    regist = function(map)
        local ret = {}
        ret.cmd = "regist"
        ret.__session__ = map[1]
        ret.userId = map[21]-- 用户名
        ret.password = map[22]-- 密码
        ret.appid = map[17]-- 应用id
        ret.channel = map[25]-- 渠道
        ret.deviceID = map[26]-- 机器码
        ret.deviceInfor = map[27]-- 机器信息
        return ret
    end,
    -- 保存所选服务器
    setEnterServer = function(map)
        local ret = {}
        ret.cmd = "setEnterServer"
        ret.__session__ = map[1]
        ret.sidx = map[30]-- 服务器id
        ret.uidx = map[31]-- 用户id
        ret.appid = map[17]-- 应用id
        return ret
    end,
    -- 取得服务器信息
    getServerInfor = function(map)
        local ret = {}
        ret.cmd = "getServerInfor"
        ret.__session__ = map[1]
        ret.idx = map[13]-- 服务器id
        return ret
    end,
    -- 取得服务器列表
    getServers = function(map)
        local ret = {}
        ret.cmd = "getServers"
        ret.__session__ = map[1]
        ret.appid = map[17]-- 应用id
        ret.channceid = map[18]-- 渠道号
        return ret
    end,
    }
    --==============================
    UsermgrHttpProto.send = {
    login = function(retInfor, userInfor, serverid)
        local ret = {}
        ret[0] = 20
        ret[2] = UsermgrHttpProto.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[23] = UsermgrHttpProto.ST_userInfor.toMap(userInfor); -- 用户信息
        ret[28] = serverid; -- 服务器id
        return ret
    end,
    regist = function(retInfor, userInfor, serverid)
        local ret = {}
        ret[0] = 24
        ret[2] = UsermgrHttpProto.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[23] = UsermgrHttpProto.ST_userInfor.toMap(userInfor); -- 用户信息
        ret[28] = serverid; -- 服务器id
        return ret
    end,
    setEnterServer = function(retInfor)
        local ret = {}
        ret[0] = 29
        ret[2] = UsermgrHttpProto.ST_retInfor.toMap(retInfor); -- 返回信息
        return ret
    end,
    getServerInfor = function(retInfor, server)
        local ret = {}
        ret[0] = 32
        ret[2] = UsermgrHttpProto.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[33] = UsermgrHttpProto.ST_server.toMap(server); -- 服务器信息
        return ret
    end,
    getServers = function(retInfor, servers)
        local ret = {}
        ret[0] = 16
        ret[2] = UsermgrHttpProto.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[19] = UsermgrHttpProto._toList(UsermgrHttpProto.ST_server, servers)  -- 服务器列表
        return ret
    end,
    }
    --==============================
    UsermgrHttpProto.dispatch[20]={onReceive = UsermgrHttpProto.recive.login, send = UsermgrHttpProto.send.login, logic = cmd4user}
    UsermgrHttpProto.dispatch[24]={onReceive = UsermgrHttpProto.recive.regist, send = UsermgrHttpProto.send.regist, logic = cmd4user}
    UsermgrHttpProto.dispatch[29]={onReceive = UsermgrHttpProto.recive.setEnterServer, send = UsermgrHttpProto.send.setEnterServer, logic = cmd4user}
    UsermgrHttpProto.dispatch[32]={onReceive = UsermgrHttpProto.recive.getServerInfor, send = UsermgrHttpProto.send.getServerInfor, logic = cmd4user}
    UsermgrHttpProto.dispatch[16]={onReceive = UsermgrHttpProto.recive.getServers, send = UsermgrHttpProto.send.getServers, logic = cmd4user}
    --==============================
    function UsermgrHttpProto.dispatcher(map, client_fd)
        if map == nil then
            skynet.error("[dispatcher] mpa == nil")
            return nil
        end
        local cmd = map[0]
        if cmd == nil then
            skynet.error("get cmd is nil")
            return nil;
        end
        local dis = UsermgrHttpProto.dispatch[cmd]
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
    return UsermgrHttpProto
end