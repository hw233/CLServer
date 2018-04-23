if cmd4com ~= nil then
    return cmd4com
end

---@class cmd4com 一些通用接口逻辑处理
cmd4com = {}
local skynet = require("skynet")
require("Errcode")
---@type CLUtl
local CLUtl = require("CLUtl")
local DBUtl = require "DBUtl"
---@type NetProtoIsland
local NetProto = NetProtoIsland

cmd4com.CMD = {
    --心跳
    heart = function()
      return NetProto.send.heart()
    end,

}
return cmd4com