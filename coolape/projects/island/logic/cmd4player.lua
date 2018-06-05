if cmd4player ~= nil then
    printe("this logic may not entry")
end

-- 玩家的逻辑处理
local cmd4player = {}

local skynet = require("skynet")
require("Errcode")
---@type CLUtl
local CLUtl = require("CLUtl")
local DBUtl = require "DBUtl"
---@type dateEx
local dateEx = require("dateEx")
local NetProtoIsland = "NetProtoIsland"
require("dbplayer")
--if cmd4city == nil then
--    -- 保证一次会话只有一个cmd4city
    require("cmd4city")
--end

local table = table

---@type dbplayer
local myself;
---@type dbcity
local city

cmd4player.CMD = {
    login = function(m, fd)
        -- 登陆
        if m.uidx == nil then
            local ret = {}
            ret.msg = "参数错误！";
            ret.code = Errcode.error
            return skynet.call(NetProtoIsland, "lua", "send", "login", ret, nil, nil, dateEx.nowMS(), fd)
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
            if myself:init(player) then
                city = cmd4city.new(m.uidx)
                myself:setcityidx(city:getidx())
            else
                printe("create player err==" .. m.uidx)
                local ret = {}
                ret.msg = "create player err"
                ret.code = Errcode.error
                return skynet.call(NetProtoIsland, "lua", "send", "login", ret, nil, nil, dateEx.nowMS(), fd)
            end
        else
            -- 取得主城信息
            city = cmd4city.getSelf(myself:getcityidx())
            if city == nil or city:isEmpty() then
                printe("get city is nil or empty==" .. m.uidx)
                local ret = {}
                ret.msg = "get city is nil or empty"
                ret.code = Errcode.error
                return skynet.call(NetProtoIsland, "lua", "send", "login", ret, nil, nil, dateEx.nowMS(), fd)
            end
        end

        local cityVal = city:value2copy()
        cityVal.buildings = {}
        cityVal.tiles = {}
        local tiles = cmd4city.getSelfTiles()
        if tiles == nil then
            printe("get tiles is nil==" .. m.uidx)
            local ret = {}
            ret.msg = "get buildings is nil"
            ret.code = Errcode.error
            return skynet.call(NetProtoIsland, "lua", "send", "login", ret, nil, nil, dateEx.nowMS(), fd)
        end
        ---@type dbcity
        local _tile
        for i, v in pairs(tiles) do
            _tile = v
            cityVal.tiles[_tile:getidx()] = _tile:value2copy();
        end

        local buildings = cmd4city.getSelfBuildings()
        if buildings == nil then
            printe("get buildings is nil==" .. m.uidx)
            local ret = {}
            ret.msg = "get buildings is nil"
            ret.code = Errcode.error
            return skynet.call(NetProtoIsland, "lua", "send", "login", ret, nil, nil, dateEx.nowMS(), fd)
        end
        ---@type dbcity
        local _building
        for i, v in pairs(buildings) do
            _building = v
            cityVal.buildings[_building:getidx()] = _building:value2copy();
        end

        local ret = {}
        ret.msg = nil;
        ret.code = Errcode.ok
        return skynet.call(NetProtoIsland, "lua", "send", "login", ret, myself:value2copy(), cityVal, dateEx.nowMS(), fd)
    end,
    release = function(m, fd)
        print("player release")
        --TODO:把相关处理入库
        if myself then
            myself:release();
            myself = nil;
        end
        if cmd4city then
            cmd4city.release()
        end
    end,

    logout = function(m, fd)
        skynet.call("watchdog", "lua", "close", fd)
    end,

}

skynet.start(function()
    skynet.dispatch("lua", function(_, _, command, ...)
        local f = cmd4player.CMD[command]
        skynet.ret(skynet.pack(f(...)))
    end)
end)
