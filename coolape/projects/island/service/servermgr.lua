local skynet = require "skynet"
require "skynet.manager"    -- import skynet.register
local dbservers = require("dbservers")

local CMD = {}
local serverlist = {}  -- 缓存服务器列表

function CMD.getServers(appid, channel)
    local key = appid .. "_" .. channel
    local list = serverlist[key]
    if list then
        return list;
    end

    list = dbservers.getList(appid, " idx desc ")
    local result = {}
    if list and #list > 0 then
        if channel then
            for i, v in ipairs(list) do
                if v.channel == channel then
                    table.insert(result, v)
                end
            end
        else
            result = list
        end
    end
    serverlist[key] = result;
    return result;
end



skynet.start(
function()
    skynet.dispatch("lua",
    function(_, _, command, ...)
        local f = CMD[command]
        skynet.ret(skynet.pack(f(...)))
    end)
    skynet.register "servermgr"
end
)
