do
    ---@class NetProtoIsland
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
            r[12] = m.idx  -- 唯一标识 int int
            r[26] = m.status  -- 状态 1：正常 int int
            r[13] = m.name  -- 名字 string
            r[27] = m.unionidx  -- 联盟id int int
            r[28] = m.cityidx  -- 城池id int int
            r[29] = m.diam  -- 钻石 long int
            r[30] = m.lev  -- 等级 long int
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
            r[12] = m.idx  -- 唯一标识 int int
            r[31] = m.levpos  -- 等级 int int
            r[13] = m.name  -- 名称 string
            r[32] = NetProtoIsland._toMap(NetProtoIsland.ST_building, m.buildings)  -- 建筑信息 key=idx, map
            r[33] = m.pos  -- 城所在世界grid的index int int
            r[34] = m.statuspos  -- 状态 1:正常; int int
            r[35] = m.pidx  -- 玩家idx int int
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
            r[12] = m.idx  -- 唯一标识 int int
            r[36] = m.levidx  -- 等级 int int
            r[37] = m.validx  -- 值。如:产量，仓库的存储量等 int int
            r[38] = m.cidxidx  -- 主城idx int int
            r[39] = m.val2idx  -- 值2。如:产量，仓库的存储量等 int int
            r[40] = m.val3idx  -- 值3。如:产量，仓库的存储量等 int int
            r[41] = m.val4idx  -- 值4。如:产量，仓库的存储量等 int int
            r[42] = m.attrididx  -- 属性配置id int int
            r[43] = m.posidx  -- 位置，即在城的gird中的index int int
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
    NetProtoIsland.send = {
    -- 数据释放，客户端不用调用，服务器内部调用的指令
    release = function()
        local ret = {}
        ret[0] = 14
        ret[1] = NetProtoIsland.__sessionID
        return ret
    end,
    -- 登出
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
    -- 停服，客户端不用调用，服务器内部调用的指令
    stopserver = function()
        local ret = {}
        ret[0] = 25
        ret[1] = NetProtoIsland.__sessionID
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
        ret.city = NetProtoIsland.ST_city.parse(map[44]) -- 主城信息
        ret.systime = map[21]-- 系统时间 long
        ret.session = map[22]-- 会话id
        return ret
    end,
    stopserver = function(map)
        local ret = {}
        ret.cmd = "stopserver"
        return ret
    end,
    }
    --==============================
    NetProtoIsland.dispatch[14]={onReceive = NetProtoIsland.recive.release, send = NetProtoIsland.send.release}
    NetProtoIsland.dispatch[15]={onReceive = NetProtoIsland.recive.logout, send = NetProtoIsland.send.logout}
    NetProtoIsland.dispatch[16]={onReceive = NetProtoIsland.recive.login, send = NetProtoIsland.send.login}
    NetProtoIsland.dispatch[25]={onReceive = NetProtoIsland.recive.stopserver, send = NetProtoIsland.send.stopserver}
    --==============================
    NetProtoIsland.cmds = {
        release = "release",
        logout = "logout",
        login = "login",
        stopserver = "stopserver"
    }
    --==============================
    return NetProtoIsland
end