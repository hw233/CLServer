
local skynet = require("skynet")
require("Errcode")
---@type CLUtl
local CLUtl = require("CLUtl")
local DBUtl = require "DBUtl"
---@type NetProtoIsland
local NetProto = NetProtoIsland

cmd4com = {}

cmd4com.CMD = {
    --心跳
    heart = function()
      return NetProto.send.heart()
    end,

}
return cmd4com