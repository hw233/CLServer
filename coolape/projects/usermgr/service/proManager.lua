-- 工程管理后台逻辑处理
local skynet = require("skynet")
---@type CLUtl
local CLUtl = require("CLUtl")
local DBUtl = require "DBUtl"
require("fileEx")
local json = require("json.json")
---@type dateEx
local dateEx = require("dateEx")
local table = table
require("dbservers")

local clmanager = nil

local CMD = {}

-- 左边菜单
function CMD.getLeftMenu(map)
    local ret = {
        { name = "基本信息", key = "baseinfor", url = "../../projectInfor.html?name=usermgr" },
        { name = "接口设计", key = "interface", isGroupMenu = true, feather = "edit" },
        { name = "表设计", key = "tableDesin", isGroupMenu = true, feather = "edit", url = "../../designtable.html?createmode=true" },
        { name = "数据库", key = "database", isGroupMenu = true, feather = "database", url = "../../database.html" },
        { name = "后台处理", key = "backconsole", isGroupMenu = true, feather = "command" },
    }
    return ret
end

-- 取得子菜单
function CMD.getLeftSubMenu(map)
    local key = map.groupKey
    local ret = {}
    if key == "database" then
        --local tableDesinPath = CLUtl.combinePath(skynet.getenv("projectPath"), "dbDesign")
        --local files = fileEx.getFiles(tableDesinPath, "lua")
        --table.sort(files)
        --for i, f in ipairs(files) do
        --    local t = dofile(CLUtl.combinePath(tableDesinPath, f))
        --    table.insert(ret, { name = t.name .. "." .. t.desc, key = t.name, url = "../../proctable.html", feather = "database" })
        --end
        local tabls = skynet.call(clmanager, "lua", "getAllTableDesign")
        for i, t in ipairs(tabls) do
            table.insert(ret, { name = t.name .. "." .. t.desc, key = t.name, url = "../../proctable.html", feather = "edit" })
        end
    elseif key == "tableDesin" then
        local tabls = skynet.call(clmanager, "lua", "getAllTableDesign")
        for i, t in ipairs(tabls) do
            table.insert(ret, { name = t.name .. "." .. t.desc, key = t.name, url = "../../designtable.html", feather = "edit" })
        end
    elseif key == "interface" then
    elseif key == "backconsole" then
        table.insert(ret, { name = "服务器管理", key = "proServers", url = "serversMgr.html", feather = "edit" })
    end
    return ret
end

function CMD.doSQL(map)
    local sql = map.sql
    return skynet.call("CLMySQL", "lua", "EXESQL", sql)
end

function CMD.getTableInfor(map)
    local tableName = map.tableName
    if CLUtl.isNilOrEmpty(tableName) then
        printe("tableName is nil")
        return
    end
    local ret = {}
    ret.design = skynet.call(clmanager, "lua", "getTableDesign", { tableName = tableName })
    local sql = "select count(*) as count from " .. tableName
    local result = skynet.call("CLMySQL", "lua", "EXESQL", sql)
    if result and result.errno then
        ret.count = 0
    else
        ret.count = result[1].count
    end
    return ret
end

---@public 取得服务器列表
function CMD.getServerList(map)
    local list = dbservers.getListByappid(map.appid)
    return list
end

---@public 新增服务
function CMD.newServer(map)
    local data = json.decode(map.data)
    data.idx = DBUtl.nextVal(DBUtl.Keys.server)
    local server = dbservers.new(data, true)
    server:release()
    server = nil
    return { success = true }
end

skynet.start(function()
    clmanager = skynet.newservice("CLManage")
    skynet.dispatch("lua", function(_, _, command, ...)
        local f = CMD[command]
        if f then
            skynet.ret(skynet.pack(f(...)))
        else
            skynet.ret(skynet.pack(skynet.call(clmanager, "lua", command, ...)))
        end
    end)
end)
