---@class cmd4com 一些通用接口逻辑处理
local cmd4com = {}
local skynet = require("skynet")
require("Errcode")
require("public.include")
---@type CLUtl
local CLUtl = require("CLUtl")
local DBUtl = require "DBUtl"
local NetProto = "NetProtoIsland"

cmd4com.CMD = {
    --心跳
    heart = function(map)
        return skynet.call(NetProto, "lua", "send", "heart", map)
    end,

    -- 释放
    release = function(map)
        --todo:
        skynet.exit()
    end,

}
skynet.start(function()
    skynet.dispatch("lua", function(_, _, command, ...)
        local f = cmd4com.CMD[command]
        if f == nil then
            error("cmd func is nil.cmd == " .. command)
        else
            skynet.ret(skynet.pack(f(...)))
        end
    end)
end)
