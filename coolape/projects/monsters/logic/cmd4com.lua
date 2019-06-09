---@class cmd4com 一些通用接口逻辑处理
local cmd4com = {}
local skynet = require("skynet")
require("Errcode")
require("public.include")
---@type CLUtl
local CLUtl = require("CLUtl")
local DBUtl = require "DBUtl"
local NetProto = skynet.getenv("NetProtoName")
local CMD = {}
--心跳
CMD.heart = function(map)
    return skynet.call(NetProto, "lua", "send", "heart", map)
end

-- 释放
CMD.release = function(map)
end

skynet.start(
    function()
        skynet.dispatch(
            "lua",
            function(_, _, command, ...)
                local f = CMD[command]
                if f == nil then
                    error("cmd func is nil.cmd == " .. command)
                else
                    skynet.ret(skynet.pack(f(...)))
                end
            end
        )
    end
)
