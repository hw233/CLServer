local skynet = require "skynet"
---@class Utl
Utl = {}
-- 取得key的自增序列号
function Utl.nextVal(key)
    return skynet.call("CLDB", "lua", "nextVal", key);
end

return Utl