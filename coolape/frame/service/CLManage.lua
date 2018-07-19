local skynet = require("skynet")
---@type CLUtl
local CLUtl = require("CLUtl")
local DBUtl = require "DBUtl"
---@type dateEx
local dateEx = require("dateEx")
local table = table

local CMD = {}

local function adjust_address(address)
    if address:sub(1, 1) ~= ":" then
        address = assert(tonumber("0x" .. address), "Need an address") | (skynet.harbor(skynet.self()) << 24)
    end
    return address
end

-- 取得服务列表
function CMD.serviceList(map)
    return skynet.call(".launcher", "lua", "LIST")
end

-- List unique service
function CMD.uniqueServiceList()
    return skynet.call("SERVICE", "lua", "LIST")
end

function CMD.serviceStat()
    return skynet.call(".launcher", "lua", "STAT")
end

function CMD.memory()
    return skynet.call(".launcher", "lua", "MEM")
end

function CMD.gc()
    return skynet.call(".launcher", "lua", "GC")
end

function CMD.serviceInfo(address, ...)
    address = adjust_address(address)
    return skynet.call(address, "debug", "INFO", ...)
end

-- 数据库的基本信息
function CMD.getMysqlInfor()
    local ret = skynet.call("CLMySQL", "lua", "GETINFOR")
    return ret
end

function CMD.synMySQL()
    return skynet.call("CLMySQL", "lua", "FLUSHALL")
end

skynet.start(function()
    skynet.dispatch("lua", function(_, _, command, ...)
        local f = CMD[command]
        if f then
            skynet.ret(skynet.pack(f(...)))
        else
            skynet.ret(skynet.pack("no cmd func got"))
        end
    end)
end)
