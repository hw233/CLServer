do
    UsermgrHttpProto = {}
    local cmd4user = require("cmd4user")
    local skynet = require "skynet"

    require("BioUtl")

    UsermgrHttpProto.dispatch = {}
    --==============================
    -- public toMap
    UsermgrHttpProto._toMap = function(stName, m)
        local ret = {}
        if m == nil then return ret end
        for k,v in pairs(m) do
            ret[k] = UsermgrHttpProto[stName].toMap(v)
        end
        return ret
    end
    -- public toList
    UsermgrHttpProto._toList = function(stName, m)
        local ret = {}
        if m == nil then return ret end
        for i,v in ipairs(m) do
            table.insert(ret, UsermgrHttpProto[stName].toMap(v))
        end
        return ret
    end
    -- public parse
    UsermgrHttpProto._parseMap = function(stName, m)
        local ret = {}
        if m == nil then return ret end
        for k,v in pairs(m) do
            ret[k] = UsermgrHttpProto[stName].parse(v)
        end
        return ret
    end
    -- public parse
    UsermgrHttpProto._parseList = function(stName, m)
        local ret = {}
        if m == nil then return ret end
        for i,v in ipairs(m) do
            table.insert(ret, UsermgrHttpProto[stName].parse(v))
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
    -- 服务器列表
    UsermgrHttpProto.ST_servers = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[12] = UsermgrHttpProto._toList(UsermgrHttpProto.ST_server, m.list)  -- 服务器列表
            return r;
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.list = UsermgrHttpProto._parseList(UsermgrHttpProto.ST_server, m.list)  -- 服务器列表
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
    -- 取得服务器列表
    getServers = function(map)
        local ret = {}
        ret.cmd = "getServers"
        ret.__session__ = map[1]
        ret.appid = map[17]-- 应用id
        ret.channceid = map[18]-- 渠道号
        return ret
    end,
    -- 登陆
    login = function(map)
        local ret = {}
        ret.cmd = "login"
        ret.__session__ = map[1]
        ret.userId = map[21]-- 用户名
        ret.password = map[22]-- 密码
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
    }
    --==============================
    UsermgrHttpProto.send = {
    getServers = function(retInfor, servers)
        local ret = {}
        ret[0] = 16
        ret[2] = UsermgrHttpProto.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[19] = UsermgrHttpProto.ST_servers.toMap(servers); -- 服务器列表
        return ret
    end,
    login = function(retInfor, userInfor)
        local ret = {}
        ret[0] = 20
        ret[2] = UsermgrHttpProto.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[23] = UsermgrHttpProto.ST_userInfor.toMap(userInfor); -- 用户信息
        return ret
    end,
    regist = function(retInfor, userInfor)
        local ret = {}
        ret[0] = 24
        ret[2] = UsermgrHttpProto.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[23] = UsermgrHttpProto.ST_userInfor.toMap(userInfor); -- 用户信息
        return ret
    end,
    }
    --==============================
    UsermgrHttpProto.dispatch[16]={onReceive = UsermgrHttpProto.recive.getServers, send = UsermgrHttpProto.send.getServers, logic = cmd4user}
    UsermgrHttpProto.dispatch[20]={onReceive = UsermgrHttpProto.recive.login, send = UsermgrHttpProto.send.login, logic = cmd4user}
    UsermgrHttpProto.dispatch[24]={onReceive = UsermgrHttpProto.recive.regist, send = UsermgrHttpProto.send.regist, logic = cmd4user}
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