local skynet = require "skynet"
local socket = require "skynet.socket"
local urllib = require "http.url"
local BioUtl = require("BioUtl")
require("UsermgrHttpProtoServer")
---@type CLUtl
local CLUtl = require("CLUtl")
local json = require("json")
local table = table
local string = string

---@type UsermgrHttpProto
local NetProto = UsermgrHttpProto
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

local parseBody = function(body)
    --local contents = CLUtl.strSplit(body, "&")
    --local data = {}
    --local strs
    --for i, v in ipairs(contents) do
    --    strs = CLUtl.strSplit(v, "=")
    --    data[urllib.decode(strs[1])] = urllib.decode(strs[2])
    --end
    local data = urllib.parse_query(body)
    for k, v in pairs(data) do
        print(k)
    end
    return data
end

-- ======================================================
-- ======================================================
function CMD.onrequset(url, method, header, body)
    -- 有http请求
    printhttp(url, method, header, body) -- debug log
    if method:upper() == "POST" then
        local content = parseBody(body)
        if content and content.data then
            local map = BioUtl.readObject(content.data)

            local ok, result = pcall(NetProto.dispatcher, map, nil)
            if ok then
                if result then
                    return result
                end
            else
                skynet.error(result)
            end
        else
            skynet.error("get post url, but body content id nil. url=" .. url)
        end
    else
        -- TODO: get
    end
end

-- ======================================================
skynet.start(function()
    skynet.dispatch("lua", function(_, _, command, ...)
        local f = CMD[command]
        skynet.ret(skynet.pack(f(...)))
    end)
end)
