local skynet = require "skynet"
require "skynet.manager"    -- import skynet.register
local sharedata = require "skynet.sharedata"
local urllib = require "http.url"
local fileEx = require "fileEx"
require("CLGlobal")
---@type CLUtl
local CLUtl = require("CLUtl")
local json = require("json")
local table = table
local string = string

local CMD = {}
local LogicMap = {}

-- ======================================================
local printhttp = function(url, method, header, body)
    local tmp = {}
    if header.host then
        table.insert(tmp, string.format("host: %s", header.host) .. "  " .. method)
    end
    local path, query = urllib.parse(url)
    table.insert(tmp, string.format("path: %s", path))
    if query then
        local q = urllib.parse_query(query)
        for k, v in pairs(q) do
            table.insert(tmp, string.format("query: %s= %s", k, v))
        end
    end
    table.insert(tmp, "-----header----")
    for k, v in pairs(header) do
        table.insert(tmp, string.format("%s = %s", k, v))
    end
    table.insert(tmp, "-----body----\n" .. body)
    local ret = table.concat(tmp, "\n")
    print(ret)
    return ret
end

local parseStrBody = function(body)
    local data = urllib.parse_query(body)
    return data
end

-- ======================================================
-- ======================================================
function CMD.onrequset(url, method, header, body)
    -- 有http请求
    --printhttp(url, method, header, body) -- debug log
    local path, query = urllib.parse(url)
    if method:upper() == "POST" then
        if path and path:lower() == "/frame/post" then
            if body then
                local content = parseStrBody(body)
                --TODO:
            else
                return nil
            end
        else
            local content = parseStrBody(body)
            -- TODO:
        end
    else
        if path == "/frame/stopserver" then
            -- 停服处理
            CMD.stop()
            return ""
        elseif path == "/frame/get" then
            -- 处理统一的get请求
            local requst = urllib.parse_query(query)
            local cmd = requst.cmd
            if CLUtl.isNilOrEmpty(cmd) then
                return "cmd == nil"
            end
            local cmdFunc = CMD[cmd]
            if cmdFunc == nil then
                printe("cannot deal the cmd==" .. cmd)
                return "cannot deal the cmd==" .. cmd
            end
            local ret = cmdFunc(requst)
            local jsoncallback = requst.callback
            if jsoncallback ~= nil then
                -- 说明ajax调用
                return jsoncallback .. "(" .. json.encode(ret) .. ")"
            else
                return json.encode(ret)
            end
        end
    end
end

-- 取得左边列表
function CMD.getLeftMenu (map)
    local projectsInfor = nil
    --sharedata.query("projectsInfor")
    if projectsInfor == nil then
        local dirs = fileEx.getDirs("coolape/projects")
        projectsInfor = {}
        local cfgPath = skynet.getenv("coolapeRoot") .. "projects/"
        for i, v in ipairs(dirs) do
            dofile(cfgPath .. v .. "/config_" .. v)
            local cfg = { name = v, desc = projectDesc, consolePort = consolePort, httpPort = httpPort, socketPort = socketPort }
            projectsInfor[v] = cfg
        end
        sharedata.new("projectsInfor", projectsInfor)
    end
    --local list = {}
    --for k, v in pairs(projectsInfor) do
    --    table.insert(list, k .. "." .. v.desc)
    --end
    return projectsInfor
end

function CMD.stop()
    -- kill进程
    local projectname = skynet.getenv("projectName")
    local stopcmd = "ps -ef|grep config_" .. projectname .. "|grep -v grep |awk '{print $2}'|xargs -n1 kill -9"
    io.popen(stopcmd)
    --skynet.exit()
end

-- 取得逻辑处理类
function CMD.getLogic(logicName)
    local logic = LogicMap[logicName]
    if logic == nil then
        logic = skynet.newservice(logicName)
        LogicMap[logicName] = logic
    end
    return logic
end

-- ======================================================
skynet.start(function()
    skynet.dispatch("lua", function(_, _, command, ...)
        local f = CMD[command]
        skynet.ret(skynet.pack(f(...)))
    end)
end)
