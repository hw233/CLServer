-- 玩家的逻辑处理
local skynet = require("skynet")
require("Errcode")
---@type CLUtl
local CLUtl = require("CLUtl")
local DBUtl = require "DBUtl"
---@type dateEx
local dateEx = require("dateEx")
---@type NetProtoIsland
local NetProto = NetProtoIsland
require("dbplayer")
require("cmd4city")

local table = table

local cmd4player = {}
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
            return NetProto.send.login(ret, nil, dateEx.nowMS(), fd)
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
                return NetProto.send.login(ret, nil, nil, dateEx.nowMS(), fd)
            end
        else
            -- 取得主城信息
            city = cmd4city.getSelf(myself:getcityidx())
            if city == nil or city:isEmpty() then
                printe("get city is nil or empty==" .. m.uidx)
                local ret = {}
                ret.msg = "get city is nil or empty"
                ret.code = Errcode.error
                return NetProto.send.login(ret, nil, nil, dateEx.nowMS(), fd)
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
            return NetProto.send.login(ret, nil, nil, dateEx.nowMS(), fd)
        end
        ---@type dbcity
        local _tile
        for i, v in ipairs(tiles) do
            _tile = v
            cityVal.tiles[_tile:getidx()] = _tile:value2copy();
        end

        local buildings = cmd4city.getSelfBuildings()
        if buildings == nil then
            printe("get buildings is nil==" .. m.uidx)
            local ret = {}
            ret.msg = "get buildings is nil"
            ret.code = Errcode.error
            return NetProto.send.login(ret, nil, nil, dateEx.nowMS(), fd)
        end
        ---@type dbcity
        local _building
        for i, v in ipairs(buildings) do
            _building = v
            cityVal.buildings[_building:getidx()] = _building:value2copy();
        end

        local ret = {}
        ret.msg = nil;
        ret.code = Errcode.ok
        local ret = NetProto.send.login(ret, myself:value2copy(), cityVal, dateEx.nowMS(), fd)
        return ret
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

return cmd4player
