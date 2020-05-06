    ---@class NetProtoUsermgr 网络协议
    local NetProtoUsermgr = {}
    local table = table
    local CMD = {}
    local skynet = require "skynet"

    require "skynet.manager"    -- import skynet.register
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
    ---@class NetProtoUsermgr.ST_retInfor 返回信息
    ---@field public msg string 返回消息
    ---@field public code number 返回值
    NetProtoUsermgr.ST_retInfor = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[10] = m.msg  -- 返回消息 string
            r[11] = m.code  -- 返回值 int
            return r
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.msg = m[10] or m["10"] --  string
            r.code = m[11] or m["11"] --  int
            return r
        end,
    }
    ---@class NetProtoUsermgr.ST_server 服务器
    ---@field public idx number id
    ---@field public port number 端口
    ---@field public name string 名称
    ---@field public host string ip地址
    ---@field public iosVer string 客户端ios版本
    ---@field public androidVer string 客户端android版本
    ---@field public isnew useData 新服
    ---@field public status number 状态 1:正常; 2:爆满; 3:维护
    NetProtoUsermgr.ST_server = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[12] = m.idx  -- id int
            r[15] = m.port  -- 端口 int
            r[14] = m.name  -- 名称 string
            r[16] = m.host  -- ip地址 string
            r[17] = m.iosVer  -- 客户端ios版本 string
            r[18] = m.androidVer  -- 客户端android版本 string
            r[19] = m.isnew  -- 新服 boolean
            r[13] = m.status  -- 状态 1:正常; 2:爆满; 3:维护 int
            return r
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[12] or m["12"] --  int
            r.port = m[15] or m["15"] --  int
            r.name = m[14] or m["14"] --  string
            r.host = m[16] or m["16"] --  string
            r.iosVer = m[17] or m["17"] --  string
            r.androidVer = m[18] or m["18"] --  string
            r.isnew = m[19] or m["19"] --  boolean
            r.status = m[13] or m["13"] --  int
            return r
        end,
    }
    ---@class NetProtoUsermgr.ST_userInfor 用户信息
    ---@field public idx number 唯一标识
    NetProtoUsermgr.ST_userInfor = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[12] = m.idx  -- 唯一标识 int
            return r
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[12] or m["12"] --  int
            return r
        end,
    }
    --==============================
    ---@class NetProtoUsermgr.RC_Base
    ---@field public cmd number
    ---@field public __session__ string

    NetProtoUsermgr.recive = {
    -- 注册
    ---@class NetProtoUsermgr.RC_registAccount : NetProtoUsermgr.RC_Base
    ---@field public userId  用户名
    ---@field public password  密码
    ---@field public email  邮箱
    ---@field public appid  应用id
    ---@field public channel  渠道号
    ---@field public deviceID  机器码
    ---@field public deviceInfor  机器信息
    registAccount = function(map)
        local ret = {}
        ret.cmd = "registAccount"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.userId = map[21] or map["21"] -- 用户名
        ret.password = map[22] or map["22"] -- 密码
        ret.email = map[23] or map["23"] -- 邮箱
        ret.appid = map[24] or map["24"] -- 应用id
        ret.channel = map[25] or map["25"] -- 渠道号
        ret.deviceID = map[26] or map["26"] -- 机器码
        ret.deviceInfor = map[27] or map["27"] -- 机器信息
        return ret
    end,
    -- 取得服务器列表
    ---@class NetProtoUsermgr.RC_getServers : NetProtoUsermgr.RC_Base
    ---@field public appid  应用id
    ---@field public channel  渠道号
    getServers = function(map)
        local ret = {}
        ret.cmd = "getServers"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.appid = map[24] or map["24"] -- 应用id
        ret.channel = map[25] or map["25"] -- 渠道号
        return ret
    end,
    -- session是否有效
    ---@class NetProtoUsermgr.RC_isSessionAlived : NetProtoUsermgr.RC_Base
    isSessionAlived = function(map)
        local ret = {}
        ret.cmd = "isSessionAlived"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        return ret
    end,
    -- 取得服务器信息
    ---@class NetProtoUsermgr.RC_getServerInfor : NetProtoUsermgr.RC_Base
    ---@field public idx  服务器id
    getServerInfor = function(map)
        local ret = {}
        ret.cmd = "getServerInfor"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.idx = map[12] or map["12"] -- 服务器id
        return ret
    end,
    -- 保存所选服务器
    ---@class NetProtoUsermgr.RC_setEnterServer : NetProtoUsermgr.RC_Base
    ---@field public sidx  服务器id
    ---@field public uidx  用户id
    ---@field public appid  应用id
    setEnterServer = function(map)
        local ret = {}
        ret.cmd = "setEnterServer"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.sidx = map[36] or map["36"] -- 服务器id
        ret.uidx = map[37] or map["37"] -- 用户id
        ret.appid = map[24] or map["24"] -- 应用id
        return ret
    end,
    -- 登陆
    ---@class NetProtoUsermgr.RC_loginAccount : NetProtoUsermgr.RC_Base
    ---@field public userId  用户名
    ---@field public password  密码
    ---@field public appid  应用id int
    ---@field public channel  渠道号 string
    loginAccount = function(map)
        local ret = {}
        ret.cmd = "loginAccount"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.userId = map[21] or map["21"] -- 用户名
        ret.password = map[22] or map["22"] -- 密码
        ret.appid = map[24] or map["24"] -- 应用id int
        ret.channel = map[25] or map["25"] -- 渠道号 string
        return ret
    end,
    -- 渠道登陆
    ---@class NetProtoUsermgr.RC_loginAccountChannel : NetProtoUsermgr.RC_Base
    ---@field public userId  用户名
    ---@field public appid  应用id int
    ---@field public channel  渠道号 string
    ---@field public deviceID  
    ---@field public deviceInfor  
    loginAccountChannel = function(map)
        local ret = {}
        ret.cmd = "loginAccountChannel"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.userId = map[21] or map["21"] -- 用户名
        ret.appid = map[24] or map["24"] -- 应用id int
        ret.channel = map[25] or map["25"] -- 渠道号 string
        ret.deviceID = map[26] or map["26"] -- 
        ret.deviceInfor = map[27] or map["27"] -- 
        return ret
    end,
    }
    --==============================
    NetProtoUsermgr.send = {
    registAccount = function(mapOrig, retInfor, userInfor, serverid, systime, session) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 20
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoUsermgr.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[28] = NetProtoUsermgr.ST_userInfor.toMap(userInfor) -- 用户信息
        ret[29] = serverid -- 服务器id int
        ret[30] = systime -- 系统时间 long
        ret[40] = session -- 会话id
        return ret
    end,
    getServers = function(mapOrig, retInfor, servers) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 31
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoUsermgr.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[32] = NetProtoUsermgr._toList(NetProtoUsermgr.ST_server, servers)  -- 服务器列表
        return ret
    end,
    isSessionAlived = function(mapOrig, retInfor) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 41
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoUsermgr.ST_retInfor.toMap(retInfor) -- 返回信息
        return ret
    end,
    getServerInfor = function(mapOrig, retInfor, server) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 33
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoUsermgr.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[34] = NetProtoUsermgr.ST_server.toMap(server) -- 服务器信息
        return ret
    end,
    setEnterServer = function(mapOrig, retInfor) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 35
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoUsermgr.ST_retInfor.toMap(retInfor) -- 返回信息
        return ret
    end,
    loginAccount = function(mapOrig, retInfor, userInfor, serverid, systime, session) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 38
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoUsermgr.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[28] = NetProtoUsermgr.ST_userInfor.toMap(userInfor) -- 用户信息
        ret[29] = serverid -- 服务器id int
        ret[30] = systime -- 系统时间 long
        ret[40] = session -- 会话id
        return ret
    end,
    loginAccountChannel = function(mapOrig, retInfor, userInfor, serverid, systime, session) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 39
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoUsermgr.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[28] = NetProtoUsermgr.ST_userInfor.toMap(userInfor) -- 用户信息
        ret[29] = serverid -- 服务器id int
        ret[30] = systime -- 系统时间 long
        ret[40] = session -- 会话id
        return ret
    end,
    }
    --==============================
    NetProtoUsermgr.dispatch[20]={onReceive = NetProtoUsermgr.recive.registAccount, send = NetProtoUsermgr.send.registAccount, logicName = "cmd4user"}
    NetProtoUsermgr.dispatch[31]={onReceive = NetProtoUsermgr.recive.getServers, send = NetProtoUsermgr.send.getServers, logicName = "cmd4server"}
    NetProtoUsermgr.dispatch[41]={onReceive = NetProtoUsermgr.recive.isSessionAlived, send = NetProtoUsermgr.send.isSessionAlived, logicName = "cmd4user"}
    NetProtoUsermgr.dispatch[33]={onReceive = NetProtoUsermgr.recive.getServerInfor, send = NetProtoUsermgr.send.getServerInfor, logicName = "cmd4server"}
    NetProtoUsermgr.dispatch[35]={onReceive = NetProtoUsermgr.recive.setEnterServer, send = NetProtoUsermgr.send.setEnterServer, logicName = "cmd4server"}
    NetProtoUsermgr.dispatch[38]={onReceive = NetProtoUsermgr.recive.loginAccount, send = NetProtoUsermgr.send.loginAccount, logicName = "cmd4user"}
    NetProtoUsermgr.dispatch[39]={onReceive = NetProtoUsermgr.recive.loginAccountChannel, send = NetProtoUsermgr.send.loginAccountChannel, logicName = "cmd4user"}
    --==============================
    NetProtoUsermgr.cmds = {
        registAccount = "registAccount", -- 注册,
        getServers = "getServers", -- 取得服务器列表,
        isSessionAlived = "isSessionAlived", -- session是否有效,
        getServerInfor = "getServerInfor", -- 取得服务器信息,
        setEnterServer = "setEnterServer", -- 保存所选服务器,
        loginAccount = "loginAccount", -- 登陆,
        loginAccountChannel = "loginAccountChannel", -- 渠道登陆
    }

    --==============================
    function CMD.dispatcher(agent, map, client_fd)
        if map == nil then
            skynet.error("[dispatcher] map == nil")
            return nil
        end
        local cmd = map[0] or map["0"]
        if cmd == nil then
            skynet.error("get cmd is nil")
            return nil
        end
        cmd = tonumber(cmd)
        local dis = NetProtoUsermgr.dispatch[cmd]
        if dis == nil then
            skynet.error("get protocol cfg is nil")
            return nil
        end
        local m = dis.onReceive(map)
        -- 执行逻辑处理
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
                local f = NetProtoUsermgr.send[command2]
                skynet.ret(skynet.pack(f(...)))
            else
                local f = CMD[command]
                skynet.ret(skynet.pack(f(command2, ...)))
            end
        end)
    
        skynet.register "NetProtoUsermgr"
    end)

