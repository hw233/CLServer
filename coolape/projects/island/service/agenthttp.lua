local skynet = require "skynet"
local socket = require "skynet.socket"
local urllib = require "http.url"
---@type BioUtl
local BioUtl = require("BioUtl")
require("NetProtoIslandServer")
---@type CLUtl
local CLUtl = require("CLUtl")
local json = require("json")
local table = table
local string = string

---@type NetProtoUsermgr
local NetProto = NetProtoUsermgr
local CMD = {}

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
    --print(ret)
    skynet.error(ret)
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
        if path and path:lower() == "/island/postbio" then
            if body then
                local map = BioUtl.readObject(body)
                local ok, result = pcall(NetProto.dispatcher, map, nil)
                if ok then
                    if result then
                        return BioUtl.writeObject(result)
                    end
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
        if path == "/island/stopserver" then
            -- 停服处理
            skynet.send("watchdog", "lua", "stop")
            return ""
        end
    end
end

-- ======================================================
skynet.start(function()
    skynet.dispatch("lua", function(_, _, command, ...)
        local f = CMD[command]
        skynet.ret(skynet.pack(f(...)))
    end)
end)
