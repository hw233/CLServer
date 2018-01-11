do
    require("bio.BioUtl")

    NetProto = {}
    NetProto.__sessionID = 0; -- 会话ID
    NetProto.dispatch = {}
    --==============================
    -- public toMap
    NetProto._toMap = function(stName, m)
        local ret = {}
        for k,v in pairs(m) do
            ret[k] = NetProto[stName].toMap(v)
        end
        return ret
    end
    -- public toList
    NetProto._toList = function(stName, m)
        local ret = {}
        for i,v in ipairs(m) do
            table.insert(ret, NetProto[stName].toMap(v))
        end
        return ret
    end
    -- public parse
    NetProto._parseMap = function(stName, m)
        local ret = {}
        for k,v in pairs(m) do
            ret[k] = NetProto[stName].parse(v)
        end
        return ret
    end
    -- public parse
    NetProto._parseList = function(stName, m)
        local ret = {}
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
            r[10] = m.msg  -- 返回消息 string
            r[11] = m.code  -- 返回值 int
            return r;
        end,
        parse = function(m)
            local r = {}
            r.msg = m[10] --  string
            r.code = m[11] --  int
            return r;
        end,
    }
    -- 用户信息
    NetProto.ST_userInfor = {
        toMap = function(m)
            local r = {}
            r[12] = m.id  --   string
            r[13] = m.ver  -- 服务数据版本号 int
            r[14] = m.name  -- 名字 string
            r[15] = m.lev  -- 等级 int
            return r;
        end,
        parse = function(m)
            local r = {}
            r.id = m[12] --  string
            r.ver = m[13] --  int
            r.name = m[14] --  string
            r.lev = m[15] --  int
            return r;
        end,
    }
    --==============================
    NetProto.send = {
    -- 退出
    logout = function()
        local ret = {}
        ret[0] = 16
        ret[1] = NetProto.__sessionID
        return ret
    end,
    -- 登陆
    login = function(userId, password)
        local ret = {}
        ret[0] = 17
        ret[1] = NetProto.__sessionID
        ret[18] = userId; -- 用户名
        ret[19] = password; -- 密码
        return ret
    end,
    -- 数据同步
    syndata = function(ver, data)
        local ret = {}
        ret[0] = 22
        ret[1] = NetProto.__sessionID
        ret[13] = ver; -- 版本号
        ret[23] = data; -- 数据信息
        return ret
    end,
    }
    --==============================
    NetProto.recive = {
    logout = function(map)
        local ret = {}
        ret.cmd = "logout"
        ret.retInfor = NetProto.ST_retInfor.parse(map[2]) -- 返回信息
        return ret
    end,
    login = function(map)
        local ret = {}
        ret.cmd = "login"
        ret.retInfor = NetProto.ST_retInfor.parse(map[2]) -- 返回信息
        ret.userInfor = NetProto.ST_userInfor.parse(map[20]) -- 用户信息
        ret.sysTime = map[21]-- 系统时间
        return ret
    end,
    syndata = function(map)
        local ret = {}
        ret.cmd = "syndata"
        ret.retInfor = NetProto.ST_retInfor.parse(map[2]) -- 返回信息
        ret.newVer = map[24]-- 新版本号
        ret.newData = map[25]-- 新数据
        return ret
    end,
    }
    --==============================
    NetProto.dispatch[16]={onReceive = NetProto.recive.logout, send = NetProto.send.logout}
    NetProto.dispatch[17]={onReceive = NetProto.recive.login, send = NetProto.send.login}
    NetProto.dispatch[22]={onReceive = NetProto.recive.syndata, send = NetProto.send.syndata}
    return NetProto
end