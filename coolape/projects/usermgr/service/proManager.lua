-- 工程管理后台逻辑处理
local skynet = require("skynet")
---@type CLUtl
local CLUtl = require("CLUtl")
local DBUtl = require "DBUtl"
---@type dateEx
local dateEx = require("dateEx")
local table = table

local clmanager = nil

local CMD = {}

-- 左边菜单
function CMD.getLeftMenu(map)
    local ret = {
        { name = "基本信息", key = "baseinfor", url="../../projectInfor.html?name=usermgr" },
        { name = "数据库", key = "database", feather = "database" },
        { name = "表设计", key = "tableDesin", feather = "edit" },
        { name = "接口设计", key = "interface", feather = "edit" },
        { name = "后台处理", key = "backconsole", feather = "command" },
    }
    return ret
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
