do
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
    -- 返回信息
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
    -- 用户信息
    NetProtoIsland.ST_player = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[12] = m.idx  -- 唯一标识 int
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
    NetProtoIsland.send = {
    -- 数据释放，客户端不用调用，服务器内部调用的指令
    release = function()
        local ret = {}
        ret[0] = 14
        ret[1] = NetProtoIsland.__sessionID
        return ret
    end,
    -- 登陆
    logout = function()
        local ret = {}
        ret[0] = 15
        ret[1] = NetProtoIsland.__sessionID
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
    -- 注册
    regist = function(uidx, name, icon, channel, deviceID)
        local ret = {}
        ret[0] = 23
        ret[1] = NetProtoIsland.__sessionID
        ret[17] = uidx; -- 用户id
        ret[13] = name; -- 名字
        ret[24] = icon; -- 头像
        ret[18] = channel; -- 渠道号
        ret[19] = deviceID; -- 机器码
        return ret
    end,
    }
    --==============================
    NetProtoIsland.recive = {
    release = function(map)
        local ret = {}
        ret.cmd = "release"
        return ret
    end,
    logout = function(map)
        local ret = {}
        ret.cmd = "logout"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        return ret
    end,
    login = function(map)
        local ret = {}
        ret.cmd = "login"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.player = NetProtoIsland.ST_player.parse(map[20]) -- 玩家信息
        ret.systime = map[21]-- 系统时间 long
        ret.session = map[22]-- 会话id
        return ret
    end,
    regist = function(map)
        local ret = {}
        ret.cmd = "regist"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.player = NetProtoIsland.ST_player.parse(map[20]) -- 玩家信息
        ret.systime = map[21]-- 系统时间 long
        ret.session = map[22]-- 会话id
        return ret
    end,
    }
    --==============================
    NetProtoIsland.dispatch[14]={onReceive = NetProtoIsland.recive.release, send = NetProtoIsland.send.release}
    NetProtoIsland.dispatch[15]={onReceive = NetProtoIsland.recive.logout, send = NetProtoIsland.send.logout}
    NetProtoIsland.dispatch[16]={onReceive = NetProtoIsland.recive.login, send = NetProtoIsland.send.login}
    NetProtoIsland.dispatch[23]={onReceive = NetProtoIsland.recive.regist, send = NetProtoIsland.send.regist}
    --==============================
    NetProtoIsland.cmds = {
        release = "release",
        logout = "logout",
        login = "login",
        regist = "regist"
    }
    --==============================
    return NetProtoIsland
end