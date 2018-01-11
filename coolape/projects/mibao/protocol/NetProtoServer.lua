do
    require("cmd4user")
    require("BioUtl")

    NetProto = {}
    NetProto.dispatch = {}
    --==============================
    -- public toMap
    NetProto._toMap = function(stName, m)
        local ret = {}
        if m == nil then return ret end
        for k,v in pairs(m) do
            ret[k] = NetProto[stName].toMap(v)
        end
        return ret
    end
    -- public toList
    NetProto._toList = function(stName, m)
        local ret = {}
        if m == nil then return ret end
        for i,v in ipairs(m) do
            table.insert(ret, NetProto[stName].toMap(v))
        end
        return ret
    end
    -- public parse
    NetProto._parseMap = function(stName, m)
        local ret = {}
        if m == nil then return ret end
        for k,v in pairs(m) do
            ret[k] = NetProto[stName].parse(v)
        end
        return ret
    end
    -- public parse
    NetProto._parseList = function(stName, m)
        local ret = {}
        if m == nil then return ret end
        for i,v in ipairs(m) do
            table.insert(ret, NetProto[stName].parse(v))
        end
        return ret
    end
  --==================================
  --==================================
    -- 返回信息
    NetProto.ST_retInfor = {
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
    NetProto.ST_userInfor = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[12] = m.id  --   string
            r[13] =  BioUtl.int2bio(m.ver)  -- 服务数据版本号 int
            r[14] = m.name  -- 名字 string
            r[15] =  BioUtl.int2bio(m.lev)  -- 等级 int
            return r;
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.id = m[12] --  string
            r.ver = m[13] --  int
            r.name = m[14] --  string
            r.lev = m[15] --  int
            return r;
        end,
    }
    --==============================
    NetProto.recive = {
    -- 退出
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
        ret.userId = map[18]-- 用户名
        ret.password = map[19]-- 密码
        return ret
    end,
    -- 数据同步
    syndata = function(map)
        local ret = {}
        ret.cmd = "syndata"
        ret.__session__ = map[1]
        ret.ver = map[13]-- 版本号
        ret.data = map[23]-- 数据信息
        return ret
    end,
    }
    --==============================
    NetProto.send = {
    logout = function(retInfor)
        local ret = {}
        ret[0] = 16
        ret[2] = NetProto.ST_retInfor.toMap(retInfor); -- 返回信息
        return ret
    end,
    login = function(retInfor, userInfor, sysTime)
        local ret = {}
        ret[0] = 17
        ret[2] = NetProto.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[20] = NetProto.ST_userInfor.toMap(userInfor); -- 用户信息
        ret[21] = sysTime; -- 系统时间
        return ret
    end,
    syndata = function(retInfor, newVer, newData)
        local ret = {}
        ret[0] = 22
        ret[2] = NetProto.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[24] = newVer; -- 新版本号
        ret[25] = newData; -- 新数据
        return ret
    end,
    }
    --==============================
    NetProto.dispatch[16]={onReceive = NetProto.recive.logout, send = NetProto.send.logout, logic = cmd4user}
    NetProto.dispatch[17]={onReceive = NetProto.recive.login, send = NetProto.send.login, logic = cmd4user}
    NetProto.dispatch[22]={onReceive = NetProto.recive.syndata, send = NetProto.send.syndata, logic = cmd4user}
    --==============================
    function NetProto.dispatcher(map)
        local cmd = map[0]
        if cmd == nil then
            skynet.error("get cmd is nil")
            return nil;
        end
        local dis = NetProto.dispatch[cmd]
        if dis == nil then
            skynet.error("get protocol cfg is nil")
            return nil;
        end
        local m = dis.onReceive(map)
        local logicCMD = assert(dis.logic.CMD)
        local f = assert(logicCMD[m.cmd])
        if f then
            return f(m)
        end
        return nil;
    end
    --==============================
    return NetProto
end