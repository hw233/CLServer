local skynet = require("skynet")
---@type CLUtl
local CLUtl = require("CLUtl")
local DBUtl = require "DBUtl"
---@type dateEx
local dateEx = require("dateEx")
require("CLGlobal")
require("fileEx")
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
        local ret = data:value2copy()
        data:release()
        data = nil
        return ret
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
        local func = db["set_" .. key]
        if func then
            func(data, val)
        else
            return "get set func is nil"
        end
        data:release()
        data = nil
    end
    return { success = true }
end

-- 取得table设计信息
function CMD.getTableDesign(map)
    local tableName = map.tableName
    local tableDesinPath = CLUtl.combinePath(skynet.getenv("projectPath"), "dbDesign/" .. tableName .. ".lua")
    --local t = dofile(tableDesinPath)
    local f = load(fileEx.readAll(tableDesinPath))
    if f then
        local t = f()
        return t
    end
    return nil
end

-- 取得所有表的设计
function CMD.getAllTableDesign()
    local tableDesinPath = CLUtl.combinePath(skynet.getenv("projectPath"), "dbDesign")
    local files = fileEx.getFiles(tableDesinPath, "lua")
    local ret = {}
    table.sort(files)
    for i, f in ipairs(files) do
        local t = dofile(CLUtl.combinePath(tableDesinPath, f))
        table.insert(ret, t)
    end
    return ret
end

-- 保存表设计
function CMD.saveTableDesign(map)
    local designinfor = json.decode(map.content)
    local tableName = designinfor.name
    local tableDesinPath = CLUtl.combinePath(skynet.getenv("projectPath"), "dbDesign")
    local filepath = CLUtl.combinePath(tableDesinPath, tableName .. ".lua")
    local str = {}
    table.insert(str, "local tab = {")
    table.insert(str, "    name = \"" .. designinfor.name .. "\",")
    table.insert(str, "    desc = \"" .. designinfor.desc .. "\",")
    table.insert(str, "    columns = {" )
    for i, v in ipairs(designinfor.columns) do
        table.insert(str, '        { "' .. v[1] .. '", "' .. v[2] .. '", "' .. v[3] .. '" },')
    end
    table.insert(str, "    }," )
    table.insert(str, "    primaryKey = {")
    for i, v in ipairs(designinfor.primaryKey) do
        table.insert(str, '        "' .. v .. '",')
    end
    table.insert(str, "    },")
    table.insert(str, "    cacheKey = { -- 缓存key")
    for i, v in ipairs(designinfor.cacheKey) do
        table.insert(str, '        "' .. v .. '",')
    end
    table.insert(str, "    },")

    table.insert(str, "    groupKey  = { -- 缓存组key")
    for i, v in ipairs(designinfor.groupKey or {}) do
        table.insert(str, "    {")
        for j, k in ipairs(v) do
            table.insert(str, '        "' .. k .. '",')
        end
        table.insert(str, "    },")
    end
    table.insert(str, "    },")

    table.insert(str, "    defaultData = {}, -- 初始数据")
    table.insert(str, "}")
    table.insert(str, "return tab\n")
    fileEx.writeAll(filepath, table.concat(str, "\n"))
    return { success = true }
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
