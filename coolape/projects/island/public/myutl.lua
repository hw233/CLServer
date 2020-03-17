local skynet = require "skynet"
local WATCHDOG = "watchdog"
local NetProtoIsland = skynet.getenv("NetProtoName")
local string = string

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

---@public 取得本地化
---@return string
LGet = function(language, key)
    return skynet.call("USLanguage", "lua", "get", language, key)
end

---@public 包装语言内容
---@param content string 原始内容，支持${xxx}的格式化
---@param paramsJson string 内容参数，是json格式map
LWrap = function(content, paramsJson)
    if not CLUtl.isNilOrEmpty(paramsJson) then
        local paramMap = json.decode(paramsJson)
        if paramMap then
            local key
            for k, v in pairs(paramMap) do
                key = "${" .. k .. "}"
                content = string.gsub(content, key, v)
            end
        end
    end
    return content
end
