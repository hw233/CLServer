---@class logic4player
local logic4player = {}
local skynet = require("skynet")
require "skynet.manager" -- import skynet.register
require("public.include")
require("Errcode")
require("dbplayer")
local IDConst = require("IDConst")
---@type logic4fleet
local logic4fleet = require "logic4fleet"

---public 包装成玩家的简单信息
---@param player dbplayer
---@return NetProtoIsland.ST_playerSimple
function logic4player.wrapSimplePlayer(player)
    ---@type NetProtoIsland.ST_playerSimple
    local simplePlayer = {}
    simplePlayer.idx = player:get_idx()
    simplePlayer.name = player:get_name()
    simplePlayer.unionidx = player:get_unionidx()
    simplePlayer.exp = player:get_exp()
    simplePlayer.honor = player:get_honor()
    simplePlayer.cityidx = player:get_cityidx()
    simplePlayer.lev = player:get_lev()
    simplePlayer.status = player:get_status()
    return simplePlayer
end

---public 通过舰队idx取得玩家的idx
function logic4player.getPidxByFidx(fidx)
    return logic4fleet.getPlayerIdx(fidx)
end

return logic4player
