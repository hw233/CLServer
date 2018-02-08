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
                local ret = {}
                ret.msg = "create player err"
                ret.code = Errcode.error
                local ret = NetProto.send.login(ret, nil, dateEx.nowMS(), fd)
            end
        end

        local ret = {}
        ret.msg = nil;
        ret.code = Errcode.ok
        local ret = NetProto.send.login(ret, myself:value2copy(), dateEx.nowMS(), fd)
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
    stopserver = function(m, fd)
        --  停服处理
        skynet.send("watchdog", "lua", "stop")
    end
}

return cmd4player
