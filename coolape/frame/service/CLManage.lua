local skynet = require("skynet")
---@type CLUtl
local CLUtl = require("CLUtl")
local DBUtl = require "DBUtl"
---@type dateEx
local dateEx = require("dateEx")
local json = require("json.json")
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

-- 同步mysql数据
function CMD.synMySQL()
    return skynet.call("CLMySQL", "lua", "FLUSHALL")
end

---@public 取得表数据
function CMD.getTableData(map)
    local tableName = map.tableName
    local condions = json.decode(map.conditions)
    local db = require("db" .. tableName)
    if db then
        local data = db.instanse(condions)
        if data:isEmpty() then
            return nil
        end
        return data:value2copy()
    else
        return nil
    end
end

---@public 设置表数据
function CMD.setTableData(map)
    local tableName = map.tableName
    local condions = json.decode(map.conditions)
    local key = map.key
    local val = map.val
    local db = require("db" .. tableName)
    if db then
        local data = db.instanse(condions)
        if data:isEmpty() then
            return "get db error"
        end
        local func = db["set" .. key]
        if func then
            func(data, val)
        else
            return "get set func is nil"
        end
    end
    return { success = true }
end

-- 取得table设计信息
function CMD.getTableDesign(tableName)
    local tableDesinPath = CLUtl.combinePath(skynet.getenv("projectPath"), "dbDesign/" .. tableName .. ".lua")
    local t = dofile(tableDesinPath)
    return t
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
