﻿local skynet = require "skynet"
require "skynet.manager" -- import skynet.register
local socket = require "skynet.socket"
local urllib = require "http.url"
---@type BioUtl
local BioUtl = require("BioUtl")
---@type CLUtl
local CLUtl = require("CLUtl")
local json = require("json")
local table = table
local string = string

local NetProtoName = skynet.getenv("NetProtoName")
local projectName = skynet.getenv("projectName")
local httpCMD = {
    httpPostBio = "/" .. projectName .. "/postbio",
    httpStopserver = "/" .. projectName .. "/stopserver",
    httpManage = "/" .. projectName .. "/manage"
}
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
---public 有http请求
CMD.onrequset = function(url, method, header, body)
    --printhttp(url, method, header, body) -- debug log
    local path, query = urllib.parse(url)
    if method:upper() == "POST" then
        if path and path:lower() == httpCMD.httpPostBio then
            if body then
                local map = BioUtl.readObject(body)
                local result = skynet.call(NetProtoName, "lua", "dispatcher", skynet.self(), map, nil)
                if result then
                    return BioUtl.writeObject(result)
                else
                    skynet.error(result)
                end
            else
                skynet.error("get post url, but body content id nil. url=" .. url)
            end
        else
            local content = parseStrBody(body)
        end
    else
        -- TODO: get
        if path == httpCMD.httpStopserver then
            -- 停服处理
            skynet.send("watchdog", "lua", "stop")
            return ""
        elseif path == httpCMD.httpManage then
            -- 后台管理的请求
            local requst = urllib.parse_query(query)
            -- //TODO:把后台的处理请求都记录，以备查询操作日志
            local cmd = requst.cmd
            local service = CMD.getLogic("proManager")
            if service == nil then
                return "no cmd4Manage server!!"
            end
            local ret = skynet.call(service, "lua", cmd, requst)
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

---public  取得逻辑处理类
CMD.getLogic = function(logicName)
    if CLUtl.startswith(logicName, "US") then
        -- 说明是全局服务器
        return logicName
    end

    local logic = LogicMap[logicName]
    if logic == nil then
        logic = skynet.newservice(logicName)
        LogicMap[logicName] = logic
    end
    return logic
end

---public 停止
CMD.stop = function()
    for k, v in pairs(LogicMap) do
        if skynet.address(v) then
            skynet.kill(v)
        end
    end
    LogicMap = {}
    skynet.exit()
end

CMD.reloadServer = function(serverName)
    local server = CMD.getLogic(serverName)
    skynet.send(server, "lua", "reload")
end
-- ======================================================
skynet.start(
    function()
        skynet.dispatch(
            "lua",
            function(_, _, command, ...)
                local f = CMD[command]
                skynet.ret(skynet.pack(f(...)))
            end
        )
    end
)
