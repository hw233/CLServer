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
    -- 城池
    NetProto.ST_city = {
        toMap = function(m)
            local r = {}
            r[12] = m.id  --  int
            r[13] = m.name  -- 名字 string
            return r;
        end,
        parse = function(m)
            local r = {}
            r.id = m[12] --  int
            r.name = m[13] --  string
            return r;
        end,
    }
    -- 用户信息
    NetProto.ST_userInfor = {
        toMap = function(m)
            local r = {}
            r[14] = m.lev  -- 等级 int
            r[13] = m.name  -- 名字 string
            r[24] = NetProto._toList(NetProto.ST_city, m.cityList)  -- 城池列表
            r[12] = m.id  --   string
            r[17] = m.ver  -- 版本 int
            r[16] = m.isNew  --  boolean
            r[25] = NetProto.ST_city.toMap(m.currCity) -- 当前城
            return r;
        end,
        parse = function(m)
            local r = {}
            r.lev = m[14] --  int
            r.name = m[13] --  string
            r.cityList = NetProto._parseList(NetProto.ST_city, m.cityList)  -- 城池列表
            r.id = m[12] --  string
            r.ver = m[17] --  int
            r.isNew = m[16] --  boolean
            r.currCity = NetProto.ST_city.parse(m[25]) --  table
            return r;
        end,
    }
    --==============================
    NetProto.send = {
    -- 登陆
    login = function(userId, password)
        local ret = {}
        ret[0] = 18
        ret[1] = NetProto.__sessionID
        ret[19] = userId; -- 用户名
        ret[20] = password; -- 密码
        return ret
    end,
    -- 退出
    logout = function()
        local ret = {}
        ret[0] = 23
        ret[1] = NetProto.__sessionID
        return ret
    end,
    }
    --==============================
    NetProto.recive = {
    login = function(map)
        local ret = {}
        ret.cmd = "login"
        ret.retInfor = NetProto.ST_retInfor.parse(map[2]) -- 返回信息
        ret.userInfor = NetProto.ST_userInfor.parse(map[21]) -- 用户信息
        ret.sysTime = map[22]-- 系统时间
        return ret
    end,
    logout = function(map)
        local ret = {}
        ret.cmd = "logout"
        ret.retInfor = NetProto.ST_retInfor.parse(map[2]) -- 返回信息
        return ret
    end,
    }
    --==============================
    NetProto.dispatch[18]={onReceive = NetProto.recive.login, send = NetProto.send.login}
    NetProto.dispatch[23]={onReceive = NetProto.recive.logout, send = NetProto.send.logout}
    return NetProto
end