do
    NetProtoUsermgr = {}
    local cmd4server = require("cmd4server")
    local cmd4user = require("cmd4user")
    local table = table
    local skynet = require "skynet"

    require("BioUtl")

    NetProtoUsermgr.dispatch = {}
    --==============================
    -- public toMap
    NetProtoUsermgr._toMap = function(stuctobj, m)
        local ret = {}
        if m == nil then return ret end
        for k,v in pairs(m) do
            ret[k] = stuctobj.toMap(v)
        end
        return ret
    end
    -- public toList
    NetProtoUsermgr._toList = function(stuctobj, m)
        local ret = {}
        if m == nil then return ret end
        for i,v in ipairs(m) do
            table.insert(ret, stuctobj.toMap(v))
        end
        return ret
    end
    -- public parse
    NetProtoUsermgr._parseMap = function(stuctobj, m)
        local ret = {}
        if m == nil then return ret end
        for k,v in pairs(m) do
            ret[k] = stuctobj.parse(v)
        end
        return ret
    end
    -- public parse
    NetProtoUsermgr._parseList = function(stuctobj, m)
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
    NetProtoUsermgr.ST_retInfor = {
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
    NetProtoUsermgr.ST_server = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[13] =  BioUtl.int2bio(m.idx)  -- id int
            r[14] = m.name  -- 名称 string
            r[38] = m.iosVer  -- 客户端ios版本 string
            r[39] = m.androidVer  -- 客户端android版本 string
            r[34] = m.isnew  -- 新服 boolean
            r[15] =  BioUtl.int2bio(m.status)  -- 状态 0:正常; 1:爆满; 2:维护 int
            return r;
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[13] --  int
            r.name = m[14] --  string
            r.iosVer = m[38] --  string
            r.androidVer = m[39] --  string
            r.isnew = m[34] --  boolean
            r.status = m[15] --  int
            return r;
        end,
    }
    -- 用户信息
    NetProtoUsermgr.ST_userInfor = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[13] =  BioUtl.int2bio(m.idx)  -- 唯一标识 int
            return r;
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[13] --  int
            return r;
        end,
    }
    --==============================
    NetProtoUsermgr.recive = {
    -- 注册
    registAccount = function(map)
        local ret = {}
        ret.cmd = "registAccount"
        ret.__session__ = map[1]
        ret.userId = map[21]-- 用户名
        ret.password = map[22]-- 密码
        ret.appid = map[17]-- 应用id
        ret.channel = map[25]-- 渠道号
        ret.deviceID = map[26]-- 机器码
        ret.deviceInfor = map[27]-- 机器信息
        return ret
    end,
    -- 取得服务器列表
    getServers = function(map)
        local ret = {}
        ret.cmd = "getServers"
        ret.__session__ = map[1]
        ret.appid = map[17]-- 应用id
        ret.channel = map[25]-- 渠道号
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
    -- 登陆
    loginAccount = function(map)
        local ret = {}
        ret.cmd = "loginAccount"
        ret.__session__ = map[1]
        ret.userId = map[21]-- 用户名
        ret.password = map[22]-- 密码
        ret.appid = map[17]-- 应用id
        ret.channel = map[25]-- 渠道号
        return ret
    end,
    -- 渠道登陆
    loginAccountChannel = function(map)
        local ret = {}
        ret.cmd = "loginAccountChannel"
        ret.__session__ = map[1]
        ret.userId = map[21]-- 用户名
        ret.appid = map[17]-- 应用id
        ret.channel = map[25]-- 渠道号
        ret.deviceID = map[26]-- 
        ret.deviceInfor = map[27]-- 
        return ret
    end,
    }
    --==============================
    NetProtoUsermgr.send = {
    registAccount = function(retInfor, userInfor, serverid, systime)
        local ret = {}
        ret[0] = 36
        ret[2] = NetProtoUsermgr.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[23] = NetProtoUsermgr.ST_userInfor.toMap(userInfor); -- 用户信息
        ret[28] = serverid; -- 服务器id int
        ret[35] = systime; -- 系统时间 long
        return ret
    end,
    getServers = function(retInfor, servers)
        local ret = {}
        ret[0] = 16
        ret[2] = NetProtoUsermgr.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[19] = NetProtoUsermgr._toList(NetProtoUsermgr.ST_server, servers)  -- 服务器列表
        return ret
    end,
    getServerInfor = function(retInfor, server)
        local ret = {}
        ret[0] = 32
        ret[2] = NetProtoUsermgr.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[33] = NetProtoUsermgr.ST_server.toMap(server); -- 服务器信息
        return ret
    end,
    setEnterServer = function(retInfor)
        local ret = {}
        ret[0] = 29
        ret[2] = NetProtoUsermgr.ST_retInfor.toMap(retInfor); -- 返回信息
        return ret
    end,
    loginAccount = function(retInfor, userInfor, serverid, systime)
        local ret = {}
        ret[0] = 37
        ret[2] = NetProtoUsermgr.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[23] = NetProtoUsermgr.ST_userInfor.toMap(userInfor); -- 用户信息
        ret[28] = serverid; -- 服务器id int
        ret[35] = systime; -- 系统时间 long
        return ret
    end,
    loginAccountChannel = function(retInfor, userInfor, serverid, systime)
        local ret = {}
        ret[0] = 40
        ret[2] = NetProtoUsermgr.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[23] = NetProtoUsermgr.ST_userInfor.toMap(userInfor); -- 用户信息
        ret[28] = serverid; -- 服务器id int
        ret[35] = systime; -- 系统时间 long
        return ret
    end,
    }
    --==============================
    NetProtoUsermgr.dispatch[36]={onReceive = NetProtoUsermgr.recive.registAccount, send = NetProtoUsermgr.send.registAccount, logic = cmd4user}
    NetProtoUsermgr.dispatch[16]={onReceive = NetProtoUsermgr.recive.getServers, send = NetProtoUsermgr.send.getServers, logic = cmd4server}
    NetProtoUsermgr.dispatch[32]={onReceive = NetProtoUsermgr.recive.getServerInfor, send = NetProtoUsermgr.send.getServerInfor, logic = cmd4server}
    NetProtoUsermgr.dispatch[29]={onReceive = NetProtoUsermgr.recive.setEnterServer, send = NetProtoUsermgr.send.setEnterServer, logic = cmd4server}
    NetProtoUsermgr.dispatch[37]={onReceive = NetProtoUsermgr.recive.loginAccount, send = NetProtoUsermgr.send.loginAccount, logic = cmd4user}
    NetProtoUsermgr.dispatch[40]={onReceive = NetProtoUsermgr.recive.loginAccountChannel, send = NetProtoUsermgr.send.loginAccountChannel, logic = cmd4user}
    --==============================
    NetProtoUsermgr.cmds = {
        registAccount = "registAccount",
        getServers = "getServers",
        getServerInfor = "getServerInfor",
        setEnterServer = "setEnterServer",
        loginAccount = "loginAccount",
        loginAccountChannel = "loginAccountChannel"
    }

    --==============================
    function NetProtoUsermgr.dispatcher(map, client_fd)
        if map == nil then
            skynet.error("[dispatcher] mpa == nil")
            return nil
        end
        local cmd = map[0]
        if cmd == nil then
            skynet.error("get cmd is nil")
            return nil;
        end
        local dis = NetProtoUsermgr.dispatch[cmd]
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
    return NetProtoUsermgr
end