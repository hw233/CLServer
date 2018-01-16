local skynet = require "skynet"
local socket = require "skynet.socket"
local urllib = require "http.url"
local BioUtl = require("BioUtl")
local NetProto = require("NetProtoServer")
local CLUtl = require("CLUtl")
local json = require("json")
local table = table
local string = string
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
    print(ret)
    return ret
end

-- ======================================================
-- ======================================================
function CMD.get(url, method, header, body)
    printhttp(url, method, header, body) -- debug log

    -- 有http请求
    return json.encode({name="陈彬",dd=123})
end

-- ======================================================
skynet.start(function()
    skynet.dispatch("lua", function(_, _, command, ...)
        local f = CMD[command]
        skynet.ret(skynet.pack(f(...)))
    end)
end)
