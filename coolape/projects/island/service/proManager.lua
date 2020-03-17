-- 工程管理后台逻辑处理
local skynet = require("skynet")
local reload = require "reload"
---@type CLUtl
local CLUtl = require("CLUtl")
local DBUtl = require "DBUtl"
require("fileEx")
---@type dateEx
local dateEx = require("dateEx")
local table = table

local clmanager = nil

local CMD = {}

-- 左边菜单
function CMD.getLeftMenu(map)
    local ret = {
        {name = "基本信息", key = "baseinfor", url = "../../projectInfor.html?name=island"},
        {name = "接口设计", key = "interface", isGroupMenu = true, feather = "edit"},
        {
            name = "表设计",
            key = "tableDesin",
            isGroupMenu = true,
            feather = "edit",
            url = "../../designtable.html?createmode=true"
        },
        {name = "数据库", key = "database", isGroupMenu = true, feather = "database", url = "../../database.html"},
        {name = "后台处理", key = "backconsole", isGroupMenu = true, feather = "command", url = "console.html"}
    }
    return ret
end

-- 取得子菜单
function CMD.getLeftSubMenu(map)
    local key = map.groupKey
    local ret = {}
    if key == "database" then
        local tabls = skynet.call(clmanager, "lua", "getAllTableDesign")
        for i, t in ipairs(tabls) do
            table.insert(
                ret,
                {name = t.name .. "." .. t.desc, key = t.name, url = "../../proctable.html", feather = "edit"}
            )
        end
    elseif key == "tableDesin" then
        local tabls = skynet.call(clmanager, "lua", "getAllTableDesign")
        for i, t in ipairs(tabls) do
            table.insert(
                ret,
                {name = t.name .. "." .. t.desc, key = t.name, url = "../../designtable.html", feather = "edit"}
            )
        end
    elseif key == "interface" then
    elseif key == "backconsole" then
        table.insert(ret, {name = "多语言.国际化", key = "language", url = "language.html", feather = "edit"})
        table.insert(ret, {name = "邮件管理", key = "mailmanage", url = "mail.html", feather = "edit"})
        table.insert(ret, {name = "公告管理", key = "announcement", url = "announcement.html", feather = "edit"})
        table.insert(ret, {name = "GM客服", key = "gmmanage", url = "GM.html", feather = "edit"})
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
    ret.design = skynet.call(clmanager, "lua", "getTableDesign", {tableName = tableName})
    local sql = "select count(*) as count from " .. tableName
    local result = skynet.call("CLMySQL", "lua", "EXESQL", sql)
    if result and result.errno then
        ret.count = 0
    else
        ret.count = result[1].count
    end
    return ret
end

---@public 取得语言种类
CMD.getLanguages = function(map)
    return skynet.call("USLanguage", "lua", "getLanguageTypes")
end

---@public 设置语言内容
CMD.setLanguage = function(map)
    return skynet.call("USLanguage", "lua", "set", tonumber(map.language), map.ckey, map.content)
end

---@public 是否是新语言key
CMD.isNewLanguageKey = function(map)
    return skynet.call("USLanguage", "lua", "isNewKey", tonumber(map.language), map.ckey)
end

---@public 查询数据语言内容
CMD.seekLanguage = function(map)
    return skynet.call("USLanguage", "lua", "seek", map.seekStr, true)
end

---@public 删除数据
CMD.delLanguages = function(map)
    return skynet.call("USLanguage", "lua", "del", tonumber(map.language), map.ckey)
end

---@public 重启后台管理服务
CMD.reloadConsole = function(map)
    skynet.send("myweb", "lua", "reloadConsole", "proManager")
    return true
end

-- 重载自己
CMD.reload = function(killSelf)
    reload() -- 自己也要重载
    return true
end

---@public test
CMD.print = function(map)
    return "CMD.print 这是一个测试"
end


skynet.start(
    function()
        clmanager = skynet.newservice("CLManage")
        skynet.dispatch(
            "lua",
            function(_, _, command, ...)
                local f = CMD[command]
                if f then
                    skynet.ret(skynet.pack(f(...)))
                else
                    skynet.ret(skynet.pack(skynet.call(clmanager, "lua", command, ...)))
                end
            end
        )
    end
)
