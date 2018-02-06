local skynet = require "skynet"
---@class Utl
DBUtl = {}
-- 取得key的自增序列号
function DBUtl.nextVal(key)
    return skynet.call("CLDB", "lua", "nextVal", key);
end

return DBUtl