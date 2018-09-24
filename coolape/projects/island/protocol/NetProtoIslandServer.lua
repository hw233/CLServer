do
    ---@class NetProtoIsland
    local NetProtoIsland = {}
    local table = table
    local CMD = {}
    local skynet = require "skynet"

    require "skynet.manager"    -- import skynet.register
    require("BioUtl")

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
    ---@class NetProtoIsland.ST_retInfor 返回信息
    NetProtoIsland.ST_retInfor = {
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
    ---@class NetProtoIsland.ST_player 用户信息
    NetProtoIsland.ST_player = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[12] =  BioUtl.number2bio(m.idx)  -- 唯一标识 int int
            r[29] =  BioUtl.number2bio(m.diam)  -- 钻石 long int
            r[13] = m.name  -- 名字 string
            r[27] =  BioUtl.number2bio(m.unionidx)  -- 联盟id int int
            r[26] =  BioUtl.number2bio(m.status)  -- 状态 1：正常 int int
            r[28] =  BioUtl.number2bio(m.cityidx)  -- 城池id int int
            r[30] =  BioUtl.number2bio(m.lev)  -- 等级 long int
            return r;
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[12] --  int
            r.diam = m[29] --  int
            r.name = m[13] --  string
            r.unionidx = m[27] --  int
            r.status = m[26] --  int
            r.cityidx = m[28] --  int
            r.lev = m[30] --  int
            return r;
        end,
    }
    ---@class NetProtoIsland.ST_city 主城
    NetProtoIsland.ST_city = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[12] =  BioUtl.number2bio(m.idx)  -- 唯一标识 int int
            r[45] = NetProtoIsland._toMap(NetProtoIsland.ST_tile, m.tiles)  -- 地块信息 key=idx, map
            r[13] = m.name  -- 名称 string
            r[32] = NetProtoIsland._toMap(NetProtoIsland.ST_building, m.buildings)  -- 建筑信息 key=idx, map
            r[30] =  BioUtl.number2bio(m.lev)  -- 等级 int int
            r[26] =  BioUtl.number2bio(m.status)  -- 状态 1:正常; int int
            r[33] =  BioUtl.number2bio(m.pos)  -- 城所在世界grid的index int int
            r[35] =  BioUtl.number2bio(m.pidx)  -- 玩家idx int int
            return r;
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[12] --  int
            r.tiles = NetProtoIsland._parseMap(NetProtoIsland.ST_tile, m[45])  -- 地块信息 key=idx, map
            r.name = m[13] --  string
            r.buildings = NetProtoIsland._parseMap(NetProtoIsland.ST_building, m[32])  -- 建筑信息 key=idx, map
            r.lev = m[30] --  int
            r.status = m[26] --  int
            r.pos = m[33] --  int
            r.pidx = m[35] --  int
            return r;
        end,
    }
    ---@class NetProtoIsland.ST_tile 建筑信息对象
    NetProtoIsland.ST_tile = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[12] =  BioUtl.number2bio(m.idx)  -- 唯一标识 int int
            r[46] =  BioUtl.number2bio(m.attrid)  -- 属性配置id int int
            r[47] =  BioUtl.number2bio(m.cidx)  -- 主城idx int int
            r[33] =  BioUtl.number2bio(m.pos)  -- 位置，即在城的gird中的index int int
            return r;
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[12] --  int
            r.attrid = m[46] --  int
            r.cidx = m[47] --  int
            r.pos = m[33] --  int
            return r;
        end,
    }
    ---@class NetProtoIsland.ST_building 建筑信息对象
    NetProtoIsland.ST_building = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[12] =  BioUtl.number2bio(m.idx)  -- 唯一标识 int int
            r[48] =  BioUtl.number2bio(m.val4)  -- 值4。如:产量，仓库的存储量等 int int
            r[49] =  BioUtl.number2bio(m.val3)  -- 值3。如:产量，仓库的存储量等 int int
            r[50] =  BioUtl.number2bio(m.val2)  -- 值2。如:产量，仓库的存储量等 int int
            r[64] =  BioUtl.number2bio(m.endtime)  -- 完成升级、恢复、采集等的时间点 long int
            r[30] =  BioUtl.number2bio(m.lev)  -- 等级 int int
            r[51] =  BioUtl.number2bio(m.val)  -- 值。如:产量，仓库的存储量等 int int
            r[47] =  BioUtl.number2bio(m.cidx)  -- 主城idx int int
            r[61] =  BioUtl.number2bio(m.val5)  -- 值5。如:产量，仓库的存储量等 int int
            r[46] =  BioUtl.number2bio(m.attrid)  -- 属性配置id int int
            r[65] =  BioUtl.number2bio(m.starttime)  -- 开始升级、恢复、采集等的时间点 long int
            r[63] =  BioUtl.number2bio(m.state)  -- 状态. 0：正常；1：升级中；9：恢复中 int
            r[33] =  BioUtl.number2bio(m.pos)  -- 位置，即在城的gird中的index int int
            return r;
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[12] --  int
            r.val4 = m[48] --  int
            r.val3 = m[49] --  int
            r.val2 = m[50] --  int
            r.endtime = m[64] --  int
            r.lev = m[30] --  int
            r.val = m[51] --  int
            r.cidx = m[47] --  int
            r.val5 = m[61] --  int
            r.attrid = m[46] --  int
            r.starttime = m[65] --  int
            r.state = m[63] --  int
            r.pos = m[33] --  int
            return r;
        end,
    }
    ---@class NetProtoIsland.ST_resInfor 资源信息
    NetProtoIsland.ST_resInfor = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[66] =  BioUtl.number2bio(m.oil)  -- 油 int
            r[67] =  BioUtl.number2bio(m.gold)  -- 金 int
            r[68] =  BioUtl.number2bio(m.food)  -- 粮 int
            return r;
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.oil = m[66] --  int
            r.gold = m[67] --  int
            r.food = m[68] --  int
            return r;
        end,
    }
    --==============================
    NetProtoIsland.recive = {
    -- 资源变化时推送
    onResChg = function(map)
        local ret = {}
        ret.cmd = "onResChg"
        ret.__session__ = map[1]
        return ret
    end,
    -- 建筑升级完成
    onFinishBuildingUpgrade = function(map)
        local ret = {}
        ret.cmd = "onFinishBuildingUpgrade"
        ret.__session__ = map[1]
        return ret
    end,
    -- 移动建筑
    moveBuilding = function(map)
        local ret = {}
        ret.cmd = "moveBuilding"
        ret.__session__ = map[1]
        ret.idx = map[12]-- 建筑idx int
        ret.pos = map[33]-- 位置 int
        return ret
    end,
    -- 登出
    logout = function(map)
        local ret = {}
        ret.cmd = "logout"
        ret.__session__ = map[1]
        return ret
    end,
    -- 玩家信息变化时推送
    onPlayerChg = function(map)
        local ret = {}
        ret.cmd = "onPlayerChg"
        ret.__session__ = map[1]
        return ret
    end,
    -- 升级建筑
    upLevBuilding = function(map)
        local ret = {}
        ret.cmd = "upLevBuilding"
        ret.__session__ = map[1]
        ret.idx = map[12]-- 建筑idx int
        return ret
    end,
    -- 新建建筑
    newBuilding = function(map)
        local ret = {}
        ret.cmd = "newBuilding"
        ret.__session__ = map[1]
        ret.attrid = map[46]-- 建筑配置id int
        ret.pos = map[33]-- 位置 int
        return ret
    end,
    -- 建筑变化时推送
    onBuildingChg = function(map)
        local ret = {}
        ret.cmd = "onBuildingChg"
        ret.__session__ = map[1]
        return ret
    end,
    -- 登陆
    login = function(map)
        local ret = {}
        ret.cmd = "login"
        ret.__session__ = map[1]
        ret.uidx = map[17]-- 用户id
        ret.channel = map[18]-- 渠道号
        ret.deviceID = map[19]-- 机器码
        return ret
    end,
    -- 心跳
    heart = function(map)
        local ret = {}
        ret.cmd = "heart"
        ret.__session__ = map[1]
        return ret
    end,
    -- 新建地块
    newTile = function(map)
        local ret = {}
        ret.cmd = "newTile"
        ret.__session__ = map[1]
        ret.pos = map[33]-- 位置 int
        return ret
    end,
    -- 移动地块
    moveTile = function(map)
        local ret = {}
        ret.cmd = "moveTile"
        ret.__session__ = map[1]
        ret.idx = map[12]-- 地块idx int
        ret.pos = map[33]-- 位置 int
        return ret
    end,
    -- 取得建筑
    getBuilding = function(map)
        local ret = {}
        ret.cmd = "getBuilding"
        ret.__session__ = map[1]
        ret.idx = map[12]-- 建筑idx int
        return ret
    end,
    -- 移除地块
    rmTile = function(map)
        local ret = {}
        ret.cmd = "rmTile"
        ret.__session__ = map[1]
        ret.idx = map[12]-- 地块idx int
        return ret
    end,
    }
    --==============================
    NetProtoIsland.send = {
    onResChg = function(retInfor, resInfor)
        local ret = {}
        ret[0] = 69
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[70] = NetProtoIsland.ST_resInfor.toMap(resInfor); -- 资源信息
        return ret
    end,
    onFinishBuildingUpgrade = function(retInfor, building)
        local ret = {}
        ret[0] = 73
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[53] = NetProtoIsland.ST_building.toMap(building); -- 建筑信息
        return ret
    end,
    moveBuilding = function(retInfor, building)
        local ret = {}
        ret[0] = 56
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[53] = NetProtoIsland.ST_building.toMap(building); -- 建筑信息
        return ret
    end,
    logout = function(retInfor)
        local ret = {}
        ret[0] = 15
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        return ret
    end,
    onPlayerChg = function(retInfor, player)
        local ret = {}
        ret[0] = 72
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[20] = NetProtoIsland.ST_player.toMap(player); -- 玩家信息
        return ret
    end,
    upLevBuilding = function(retInfor, building)
        local ret = {}
        ret[0] = 54
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[53] = NetProtoIsland.ST_building.toMap(building); -- 建筑信息
        return ret
    end,
    newBuilding = function(retInfor, building)
        local ret = {}
        ret[0] = 52
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[53] = NetProtoIsland.ST_building.toMap(building); -- 建筑信息对象
        return ret
    end,
    onBuildingChg = function(retInfor, building)
        local ret = {}
        ret[0] = 71
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[53] = NetProtoIsland.ST_building.toMap(building); -- 建筑信息
        return ret
    end,
    login = function(retInfor, player, city, systime, session)
        local ret = {}
        ret[0] = 16
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[20] = NetProtoIsland.ST_player.toMap(player); -- 玩家信息
        ret[44] = NetProtoIsland.ST_city.toMap(city); -- 主城信息
        if type(systime) == "number" then
            ret[21] = BioUtl.number2bio(systime); -- 系统时间 long
        else
            ret[21] = systime; -- 系统时间 long
        end
        if type(session) == "number" then
            ret[22] = BioUtl.number2bio(session); -- 会话id
        else
            ret[22] = session; -- 会话id
        end
        return ret
    end,
    heart = function()
        local ret = {}
        ret[0] = 59
        return ret
    end,
    newTile = function(retInfor, tile)
        local ret = {}
        ret[0] = 74
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[58] = NetProtoIsland.ST_tile.toMap(tile); -- 地块信息对象
        return ret
    end,
    moveTile = function(retInfor, tile)
        local ret = {}
        ret[0] = 57
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[58] = NetProtoIsland.ST_tile.toMap(tile); -- 地块信息
        return ret
    end,
    getBuilding = function(retInfor, building)
        local ret = {}
        ret[0] = 55
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[53] = NetProtoIsland.ST_building.toMap(building); -- 建筑信息对象
        return ret
    end,
    rmTile = function(retInfor, idx)
        local ret = {}
        ret[0] = 75
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        if type(idx) == "number" then
            ret[12] = BioUtl.number2bio(idx); -- 被移除地块的idx int
        else
            ret[12] = idx; -- 被移除地块的idx int
        end
        return ret
    end,
    }
    --==============================
    NetProtoIsland.dispatch[69]={onReceive = NetProtoIsland.recive.onResChg, send = NetProtoIsland.send.onResChg, logicName = "cmd4city"}
    NetProtoIsland.dispatch[73]={onReceive = NetProtoIsland.recive.onFinishBuildingUpgrade, send = NetProtoIsland.send.onFinishBuildingUpgrade, logicName = "cmd4city"}
    NetProtoIsland.dispatch[56]={onReceive = NetProtoIsland.recive.moveBuilding, send = NetProtoIsland.send.moveBuilding, logicName = "cmd4city"}
    NetProtoIsland.dispatch[15]={onReceive = NetProtoIsland.recive.logout, send = NetProtoIsland.send.logout, logicName = "cmd4player"}
    NetProtoIsland.dispatch[72]={onReceive = NetProtoIsland.recive.onPlayerChg, send = NetProtoIsland.send.onPlayerChg, logicName = "cmd4player"}
    NetProtoIsland.dispatch[54]={onReceive = NetProtoIsland.recive.upLevBuilding, send = NetProtoIsland.send.upLevBuilding, logicName = "cmd4city"}
    NetProtoIsland.dispatch[52]={onReceive = NetProtoIsland.recive.newBuilding, send = NetProtoIsland.send.newBuilding, logicName = "cmd4city"}
    NetProtoIsland.dispatch[71]={onReceive = NetProtoIsland.recive.onBuildingChg, send = NetProtoIsland.send.onBuildingChg, logicName = "cmd4city"}
    NetProtoIsland.dispatch[16]={onReceive = NetProtoIsland.recive.login, send = NetProtoIsland.send.login, logicName = "cmd4player"}
    NetProtoIsland.dispatch[59]={onReceive = NetProtoIsland.recive.heart, send = NetProtoIsland.send.heart, logicName = "cmd4com"}
    NetProtoIsland.dispatch[74]={onReceive = NetProtoIsland.recive.newTile, send = NetProtoIsland.send.newTile, logicName = "cmd4city"}
    NetProtoIsland.dispatch[57]={onReceive = NetProtoIsland.recive.moveTile, send = NetProtoIsland.send.moveTile, logicName = "cmd4city"}
    NetProtoIsland.dispatch[55]={onReceive = NetProtoIsland.recive.getBuilding, send = NetProtoIsland.send.getBuilding, logicName = "cmd4city"}
    NetProtoIsland.dispatch[75]={onReceive = NetProtoIsland.recive.rmTile, send = NetProtoIsland.send.rmTile, logicName = "cmd4city"}
    --==============================
    NetProtoIsland.cmds = {
        onResChg = "onResChg",
        onFinishBuildingUpgrade = "onFinishBuildingUpgrade",
        moveBuilding = "moveBuilding",
        logout = "logout",
        onPlayerChg = "onPlayerChg",
        upLevBuilding = "upLevBuilding",
        newBuilding = "newBuilding",
        onBuildingChg = "onBuildingChg",
        login = "login",
        heart = "heart",
        newTile = "newTile",
        moveTile = "moveTile",
        getBuilding = "getBuilding",
        rmTile = "rmTile"
    }

    --==============================
    function CMD.dispatcher(agent, map, client_fd)
        if map == nil then
            skynet.error("[dispatcher] mpa == nil")
            return nil
        end
        local cmd = map[0]
        if cmd == nil then
            skynet.error("get cmd is nil")
            return nil;
        end
        local dis = NetProtoIsland.dispatch[cmd]
        if dis == nil then
            skynet.error("get protocol cfg is nil")
            return nil;
        end
        local m = dis.onReceive(map)
        local logicProc = skynet.call(agent, "lua", "getLogic", dis.logicName)
        if logicProc == nil then
            printe("get logicServe is nil. serverName=[" .. dis.loginAccount .."]")
            return nil
        else
            return skynet.call(logicProc, "lua", m.cmd, m, client_fd, agent)
        end
    end
    --==============================
    skynet.start(function()
        skynet.dispatch("lua", function(_, _, command, command2, ...)
            if command == "send" then
                local f = NetProtoIsland.send[command2]
                skynet.ret(skynet.pack(f(...)))
            else
                local f = CMD[command]
                skynet.ret(skynet.pack(f(command2, ...)))
            end
        end)
    
        skynet.register "NetProtoIsland"
    end)
end
