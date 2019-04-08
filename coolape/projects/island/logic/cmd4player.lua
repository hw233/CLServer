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
local NetProtoIsland = "NetProtoIsland"
require("dbplayer")

local table = table

---@type dbplayer
local myself;
local city
local agent
local isEditMode

cmd4player.CMD = {
    getEditMode = function()
        return isEditMode
    end,
    login = function(m, fd, _agent)
        local cmd = m.cmd
        isEditMode = m.isEditMode
        agent = _agent
        -- 登陆
        if m.uidx == nil then
            local ret = {}
            ret.msg = "参数错误！";
            ret.code = Errcode.error
            return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, nil, nil, dateEx.nowMS(), fd, m)
        end
        if myself == nil then
            myself = dbplayer.instanse(m.uidx)
        end
        if myself:isEmpty() then
            -- 说明是没有数据,新号
            local player = {}
            player.idx = m.uidx
            player.status = 1
            player.name = "new player"
            player.lev = 1
            player.money = 0
            player.diam = 100
            player.cityidx = 0
            player.unionidx = 0
            player.crtTime = dateEx.nowStr()
            player.lastEnTime = dateEx.nowStr()
            player.channel = m.channel
            player.deviceid = m.deviceID
            if myself:init(player, true) then
                local cityServer = skynet.call(agent, "lua", "getLogic", "cmd4city")
                city = skynet.call(cityServer, "lua", "new", m.uidx, agent)
                myself:set_cityidx(city.idx)
            else
                printe("create player err==" .. m.uidx)
                local ret = {}
                ret.msg = "create player err"
                ret.code = Errcode.error
                return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, nil, nil, dateEx.nowMS(), fd, m)
            end
        else
            -- 取得主城信息
            --city = cmd4city.getSelf(myself:getcityidx())
            local cityServer = skynet.call(agent, "lua", "getLogic", "cmd4city")
            city = skynet.call(cityServer, "lua", "getSelf", myself:get_cityidx(), agent)
            if city == nil then
                printe("get city is nil or empty==" .. m.uidx)
                local ret = {}
                ret.msg = "get city is nil or empty"
                ret.code = Errcode.error
                return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, nil, nil, dateEx.nowMS(), fd, m)
            end
        end
        -- 增加触发器
        myself:setTrigger(skynet.self(), "onPlayerChg")

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
            return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, nil, nil, dateEx.nowMS(), fd, m)
        end
        cityVal.tiles = tiles
        local cityServer = skynet.call(agent, "lua", "getLogic", "cmd4city")
        local buildings = skynet.call(cityServer, "lua", "getSelfBuildings")
        --local buildings = cmd4city.getSelfBuildings()
        if buildings == nil then
            printe("get buildings is nil==" .. m.uidx)
            local ret = {}
            ret.msg = "get buildings is nil"
            ret.code = Errcode.error
            return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, nil, nil, dateEx.nowMS(), fd, m)
        end
        cityVal.buildings = buildings

        local ret = {}
        ret.msg = nil;
        ret.code = Errcode.ok
        return skynet.call(NetProtoIsland, "lua", "send", cmd, ret, myself:value2copy(), cityVal, dateEx.nowMS(), fd, m)
    end,
    release = function(m, fd)
        print("player release")
        --TODO:把相关处理入库
        if myself then
            myself:unsetTrigger(skynet.self(), "onPlayerChg")
            myself:release();
            myself = nil;
        end
    end,

    logout = function(m, fd)
        skynet.call("watchdog", "lua", "close", fd, m)
    end,

    onPlayerChg = function(data, cmd)
        cmd = cmd or "onPlayerChg"
        local ret = {}
        ret.code = Errcode.ok
        local package = skynet.call(NetProtoIsland, "lua", "send", cmd, ret, myself:value2copy())
        skynet.call(agent, "lua", "sendPackage", package)
    end,

    getPlayer = function(m)
        -- 取得玩家信息
        return myself:value2copy()
    end,
    chgDiam = function(m)
        -- 修改宝石数量
        if m.diam == nil then
            return false
        end
        myself:set_diam(myself:get_diam() - m.diam)
        return true
    end
}

skynet.start(function()
    skynet.dispatch("lua", function(_, _, command, ...)
        local f = cmd4player.CMD[command]
        if f then
            skynet.ret(skynet.pack(f(...)))
        else
            error("cmd func is nil.cmd == " .. command)
        end
    end)
end)
