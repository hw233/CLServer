--if cmd4player ~= nil then
--    printe("this logic may not entry")
--end

-- 玩家的逻辑处理
local cmd4player = {}

local skynet = require("skynet")
require("public.include")
require("Errcode")
---@type CLUtl
local CLUtl = require("CLUtl")
local DBUtl = require "DBUtl"
---@type dateEx
local dateEx = require("dateEx")
local NetProtoIsland = skynet.getenv("NetProtoName")
require("dbplayer")
require("dbtech")

local table = table

---@type dbplayer
local myself
local city
local agent
local isEditMode
-- 客户端接口
local CMD = {}

---public 编辑器模式
cmd4player.getEditMode = function()
    return isEditMode
end

---public 是否是可用的玩家名
cmd4player.isAvailableName = function(name)
    --//TODO:
end

---@param m NetProtoIsland.RC_login
cmd4player.newPlayer = function(m, type)
    local player = {}
    player.idx = m.uidx
    player.status = IDConst.PlayerState.normal
    player.type = type or IDConst.PlayerType.player
    if player.type == IDConst.PlayerType.gm then
        player.name = "GM"
    else
        player.name = m.name or "pl-" .. m.uidx
    end
    player[dbplayer.keys.icon] = 1
    player.lev = 1
    player.money = 0
    player.diam = 90000
    player.cityidx = 0
    player.unionidx = 0
    player.crtTime = dateEx.nowStr()
    player.lastEnTime = dateEx.nowStr()
    player.channel = m.channel
    player.deviceid = m.deviceID
    player[dbplayer.keys.pvptimesTody] = 0
    player[dbplayer.keys.language] = m.language or 1
    player[dbplayer.keys.beingattacked] = false
    player[dbplayer.keys.attacking] = false

    local p = dbplayer.new()
    p:init(player, true)

    local val = p:value2copy()
    p:release()
    return val
end

cmd4player.release = function()
    print("player release")
    if myself then
        myself:unsetTrigger(skynet.self(), "onPlayerChg")
        myself:release()
        myself = nil
    end
end

---public 取得玩家信息
cmd4player.getPlayer = function(m)
    return myself:value2copy()
end

---public 修改宝石数量
cmd4player.chgDiam = function(m)
    if m.diam == nil then
        return false
    end
    myself:set_diam(myself:get_diam() - m.diam)
    return true
end

cmd4player.onPlayerChg = function(data, cmd)
    cmd = cmd or "onPlayerChg"
    local ret = {}
    ret.code = Errcode.ok
    local package = pkg4Client({cmd = cmd}, ret, myself:value2copy())
    skynet.call(agent, "lua", "sendPackage", package)
end

---public 处理一些登陆时需要重置数据的操作
cmd4player.resetData = function()
    if myself == nil or myself:isEmpty() then
        return
    end
    ------------------------------------------
    -- 如果上次登陆日期是一天前，重置pvp次数
    local Y, M, D = dateEx.getYYMMDDHHmmss() -- 当前年月日
    local lastEnTime = myself:get_lastEnTime()
    local Y1, M2, D2 = dateEx.getYYMMDDHHmmss(lastEnTime) -- 上次登陆的年月日
    if Y ~= Y1 or M ~= M2 or D ~= D2 then
        -- 说明是跨天登陆
        myself:set_pvptimesTody(0)
    end
    ------------------------------------------
    --//TODO:其它的重置处理
end
------------------------------------------
------------------------------------------
------------------------------------------
---@param m NetProtoIsland.RC_login
CMD.login = function(m, fd, _agent)
    local cmd = m.cmd
    isEditMode = m.isEditMode
    agent = _agent
    -- 登陆
    if m.uidx == nil then
        local ret = {}
        ret.msg = "参数错误！"
        ret.code = Errcode.error
        return pkg4Client(m, ret, nil, nil, dateEx.nowMS(), fd)
    end
    if myself == nil then
        myself = dbplayer.instanse(m.uidx)
    end
    if myself:isEmpty() then
        -- 说明是没有数据,新号
        cmd4player.newPlayer(m)
        myself = dbplayer.instanse(m.uidx)
        if not myself:isEmpty() then
            local cityServer = skynet.call(agent, "lua", "getLogic", "cmd4city")
            city = skynet.call(cityServer, "lua", "new", m.uidx, agent)
            myself:set_cityidx(city.idx)
        else
            printe("create player err==" .. m.uidx)
            local ret = {}
            ret.msg = "create player err"
            ret.code = Errcode.error
            return pkg4Client(m, ret, nil, nil, dateEx.nowMS(), fd)
        end
    else
        cmd4player.resetData() -- 登陆前的数据重置
        -- 取得主城信息
        local cityServer = skynet.call(agent, "lua", "getLogic", "cmd4city")
        if myself:get_cityidx() <= 0 then
            -- 说明没有主城，重新创建主城
            local cityServer = skynet.call(agent, "lua", "getLogic", "cmd4city")
            city = skynet.call(cityServer, "lua", "new", m.uidx, agent)
            myself:set_cityidx(city.idx)
        else
            city = skynet.call(cityServer, "lua", "getSelf", myself:get_cityidx(), agent)
            if city == nil then
                printe("get city is nil or empty==" .. m.uidx)
                local ret = {}
                ret.msg = "get city is nil or empty"
                ret.code = Errcode.error
                return pkg4Client(m, ret, nil, nil, dateEx.nowMS(), fd)
            end
        end
    end
    -- 更新最新登陆时间
    myself:set_lastEnTime(dateEx.nowMS())
    -- 增加触发器
    myself:setTrigger(skynet.self(), "onPlayerChg")

    ---@type NetProtoIsland.ST_city
    local cityVal = city
    cityVal.buildings = {}
    cityVal.tiles = {}
    --local tiles = cmd4city.getSelfTiles()
    local cityServer = skynet.call(agent, "lua", "getLogic", "cmd4city")
    local tiles = skynet.call(cityServer, "lua", "getSelfTiles")
    if tiles == nil then
        printe("get tiles is nil==" .. m.uidx)
        local ret = {}
        ret.msg = "get buildings is nil"
        ret.code = Errcode.error
        return pkg4Client(m, ret, nil, nil, dateEx.nowMS(), fd)
    end
    cityVal.tiles = tiles
    -- local cityServer = skynet.call(agent, "lua", "getLogic", "cmd4city")
    local buildings = skynet.call(cityServer, "lua", "getSelfBuildings")
    --local buildings = cmd4city.getSelfBuildings()
    if buildings == nil then
        printe("get buildings is nil==" .. m.uidx)
        local ret = {}
        ret.msg = "get buildings is nil"
        ret.code = Errcode.error
        return pkg4Client(m, ret, nil, nil, dateEx.nowMS(), fd)
    end
    cityVal.buildings = buildings
    cityVal.techs = dbtech.getListBycidx(cityVal.idx)

    -- 设置一次数据
    skynet.call(agent, "lua", "onLogin", myself:value2copy())

    local ret = {}
    ret.msg = nil
    ret.code = Errcode.ok
    return pkg4Client(m, ret, myself:value2copy(), cityVal, dateEx.nowMS(), fd)
end

CMD.logout = function(m, fd)
    skynet.call("watchdog", "lua", "close", fd, m)
end

---@param m NetProtoIsland.RC_getPlayerSimple
CMD.getPlayerSimple = function(m, fd, agent)
    local player = dbplayer.instanse(m.pidx)
    if player:isEmpty() then
        player:release()
        return pkg4Client(m, {code = Errcode.playerIsNil})
    end
    return pkg4Client(m, {code = Errcode.ok}, player:release(true))
end

skynet.start(
    function()
        skynet.dispatch(
            "lua",
            function(_, _, command, ...)
                local f = CMD[command] or cmd4player[command]
                if f then
                    skynet.ret(skynet.pack(f(...)))
                else
                    error("cmd func is nil.cmd == " .. command)
                end
            end
        )
    end
)
