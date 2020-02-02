local skynet = require "skynet"
local WATCHDOG = "watchdog"
local NetProtoIsland = skynet.getenv("NetProtoName")

---@public 玩家是否在线
isPlayerOnline = function(pidx)
    if skynet.address(WATCHDOG) then
        return skynet.call(WATCHDOG, "lua", "isPlayerOnline", pidx)
    end
    return nil
end

---@public 取得玩家的agent
getPlayerAgent = function(pidx)
    if skynet.address(WATCHDOG) then
        return skynet.call(WATCHDOG, "lua", "getAgent", pidx)
    end
    return nil
end

---@public 取得玩家的idx
getPlayerIdx = function(session)
    if skynet.address(WATCHDOG) then
        return skynet.call(WATCHDOG, "lua", "getPidx", session)
    end
    return nil
end

---@public 组装发送客户端数据包
---@param mapOrig table 请求原始数据
---@param ret NetProtoIsland.ST_retInfor 返回数据
---@param ... ... 其它的返回数据
pkg4Client = function(mapOrig, ret, ...)
    if skynet.address(NetProtoIsland) then
        return skynet.call(NetProtoIsland, "lua", "send", mapOrig.cmd, mapOrig, ret, ...)
    end
    return nil
end
