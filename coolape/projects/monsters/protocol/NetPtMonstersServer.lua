do
    ---@class NetPtMonsters
    local NetPtMonsters = {}
    local table = table
    local CMD = {}
    local skynet = require "skynet"

    require "skynet.manager"    -- import skynet.register
    require("BioUtl")

    NetPtMonsters.dispatch = {}
    --==============================
    -- public toMap
    NetPtMonsters._toMap = function(stuctobj, m)
        local ret = {}
        if m == nil then return ret end
        for k,v in pairs(m) do
            ret[k] = stuctobj.toMap(v)
        end
        return ret
    end
    -- public toList
    NetPtMonsters._toList = function(stuctobj, m)
        local ret = {}
        if m == nil then return ret end
        for i,v in ipairs(m) do
            table.insert(ret, stuctobj.toMap(v))
        end
        return ret
    end
    -- public parse
    NetPtMonsters._parseMap = function(stuctobj, m)
        local ret = {}
        if m == nil then return ret end
        for k,v in pairs(m) do
            ret[k] = stuctobj.parse(v)
        end
        return ret
    end
    -- public parse
    NetPtMonsters._parseList = function(stuctobj, m)
        local ret = {}
        if m == nil then return ret end
        for i,v in ipairs(m) do
            table.insert(ret, stuctobj.parse(v))
        end
        return ret
    end
  --==================================
  --==================================
    ---@class NetPtMonsters.ST_retInfor 返回信息
    ---@field public msg string 返回消息
    ---@field public code number 返回值
    NetPtMonsters.ST_retInfor = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[10] = m.msg  -- 返回消息 string
            r[11] =  BioUtl.number2bio(m.code)  -- 返回值 int
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
    ---@class NetPtMonsters.ST_player 用户信息
    ---@field public idx number 唯一标识 int
    ---@field public diam number 钻石 long
    ---@field public name string 名字
    ---@field public unionidx number 联盟id int
    ---@field public cityidx number 城池id int
    ---@field public lev number 等级 long
    ---@field public status number 状态 1：正常 int
    NetPtMonsters.ST_player = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[12] =  BioUtl.number2bio(m.idx)  -- 唯一标识 int int
            r[13] =  BioUtl.number2bio(m.diam)  -- 钻石 long int
            r[14] = m.name  -- 名字 string
            r[15] =  BioUtl.number2bio(m.unionidx)  -- 联盟id int int
            r[16] =  BioUtl.number2bio(m.cityidx)  -- 城池id int int
            r[17] =  BioUtl.number2bio(m.lev)  -- 等级 long int
            r[18] =  BioUtl.number2bio(m.status)  -- 状态 1：正常 int int
            return r;
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[12] --  int
            r.diam = m[13] --  int
            r.name = m[14] --  string
            r.unionidx = m[15] --  int
            r.cityidx = m[16] --  int
            r.lev = m[17] --  int
            r.status = m[18] --  int
            return r;
        end,
    }
    ---@class NetPtMonsters.ST_netCfg 网络协议解析配置
    ---@field public encryptType number 加密类别，1：只加密客户端，2：只加密服务器，3：前后端都加密，0及其它情况：不加密
    ---@field public checkTimeStamp useData 检测时间戳
    ---@field public secretKey string 密钥
    NetPtMonsters.ST_netCfg = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[19] =  BioUtl.number2bio(m.encryptType)  -- 加密类别，1：只加密客户端，2：只加密服务器，3：前后端都加密，0及其它情况：不加密 int
            r[20] = m.checkTimeStamp  -- 检测时间戳 boolean
            r[21] = m.secretKey  -- 密钥 string
            return r;
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.encryptType = m[19] --  int
            r.checkTimeStamp = m[20] --  boolean
            r.secretKey = m[21] --  string
            return r;
        end,
    }
    --==============================
    NetPtMonsters.recive = {
    -- 登陆
    login = function(map)
        local ret = {}
        ret.cmd = "login"
        ret.__session__ = map[1]
        ret.callback = map[3]
        ret.uidx = map[23]-- 用户id
        ret.channel = map[24]-- 渠道号
        ret.deviceID = map[25]-- 机器码
        ret.isEditMode = map[26]-- 编辑模式
        return ret
    end,
    -- 心跳
    heart = function(map)
        local ret = {}
        ret.cmd = "heart"
        ret.__session__ = map[1]
        ret.callback = map[3]
        return ret
    end,
    -- 网络协议配置
    sendNetCfg = function(map)
        local ret = {}
        ret.cmd = "sendNetCfg"
        ret.__session__ = map[1]
        ret.callback = map[3]
        return ret
    end,
    -- 玩家信息变化时推送
    onPlayerChg = function(map)
        local ret = {}
        ret.cmd = "onPlayerChg"
        ret.__session__ = map[1]
        ret.callback = map[3]
        return ret
    end,
    -- 登出
    logout = function(map)
        local ret = {}
        ret.cmd = "logout"
        ret.__session__ = map[1]
        ret.callback = map[3]
        return ret
    end,
    }
    --==============================
    NetPtMonsters.send = {
    login = function(retInfor, player, systime, session, mapOrig) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 22
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetPtMonsters.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[27] = NetPtMonsters.ST_player.toMap(player); -- 玩家信息
        if type(systime) == "number" then
            ret[28] = BioUtl.number2bio(systime); -- 系统时间 long
        else
            ret[28] = systime; -- 系统时间 long
        end
        if type(session) == "number" then
            ret[29] = BioUtl.number2bio(session); -- 会话id
        else
            ret[29] = session; -- 会话id
        end
        return ret
    end,
    heart = function(mapOrig) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 30
        ret[3] = mapOrig and mapOrig.callback or nil
        return ret
    end,
    sendNetCfg = function(retInfor, netCfg, systime, mapOrig) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 31
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetPtMonsters.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[32] = NetPtMonsters.ST_netCfg.toMap(netCfg); -- 网络协议解析配置
        if type(systime) == "number" then
            ret[28] = BioUtl.number2bio(systime); -- 系统时间 long
        else
            ret[28] = systime; -- 系统时间 long
        end
        return ret
    end,
    onPlayerChg = function(retInfor, player, mapOrig) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 33
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetPtMonsters.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[27] = NetPtMonsters.ST_player.toMap(player); -- 玩家信息
        return ret
    end,
    logout = function(retInfor, mapOrig) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 34
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetPtMonsters.ST_retInfor.toMap(retInfor); -- 返回信息
        return ret
    end,
    }
    --==============================
    NetPtMonsters.dispatch[22]={onReceive = NetPtMonsters.recive.login, send = NetPtMonsters.send.login, logicName = "cmd4player"}
    NetPtMonsters.dispatch[30]={onReceive = NetPtMonsters.recive.heart, send = NetPtMonsters.send.heart, logicName = "cmd4com"}
    NetPtMonsters.dispatch[31]={onReceive = NetPtMonsters.recive.sendNetCfg, send = NetPtMonsters.send.sendNetCfg, logicName = ""}
    NetPtMonsters.dispatch[33]={onReceive = NetPtMonsters.recive.onPlayerChg, send = NetPtMonsters.send.onPlayerChg, logicName = "cmd4player"}
    NetPtMonsters.dispatch[34]={onReceive = NetPtMonsters.recive.logout, send = NetPtMonsters.send.logout, logicName = "cmd4player"}
    --==============================
    NetPtMonsters.cmds = {
        login = "login", -- 登陆,
        heart = "heart", -- 心跳,
        sendNetCfg = "sendNetCfg", -- 网络协议配置,
        onPlayerChg = "onPlayerChg", -- 玩家信息变化时推送,
        logout = "logout", -- 登出
    }

    --==============================
    function CMD.dispatcher(agent, map, client_fd)
        if map == nil then
            skynet.error("[dispatcher] map == nil")
            return nil
        end
        local cmd = map[0]
        if cmd == nil then
            skynet.error("get cmd is nil")
            return nil;
        end
        local dis = NetPtMonsters.dispatch[cmd]
        if dis == nil then
            skynet.error("get protocol cfg is nil")
            return nil;
        end
        local m = dis.onReceive(map)
        local logicProc = skynet.call(agent, "lua", "getLogic", dis.logicName)
        if logicProc == nil then
            skynet.error("get logicServe is nil. serverName=[" .. dis.loginAccount .."]")
            return nil
        else
            return skynet.call(logicProc, "lua", m.cmd, m, client_fd, agent)
        end
    end
    --==============================
    skynet.start(function()
        skynet.dispatch("lua", function(_, _, command, command2, ...)
            if command == "send" then
                local f = NetPtMonsters.send[command2]
                skynet.ret(skynet.pack(f(...)))
            else
                local f = CMD[command]
                skynet.ret(skynet.pack(f(command2, ...)))
            end
        end)
    
        skynet.register "NetPtMonsters"
    end)
end
