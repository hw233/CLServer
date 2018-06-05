---@class cmd4com 一些通用接口逻辑处理
local cmd4com = {}
local skynet = require("skynet")
require("Errcode")
---@type CLUtl
local CLUtl = require("CLUtl")
local DBUtl = require "DBUtl"
local NetProto = "NetProtoIsland"

cmd4com.CMD = {
--心跳
    heart = function()
        return skynet.call(NetProto, "lua", "send", "heart")
    end,

}
skynet.start(function()
    skynet.dispatch("lua", function(_, _, command, ...)
        local f = cmd4com.CMD[command]
        skynet.ret(skynet.pack(f(...)))
    end)
end)
