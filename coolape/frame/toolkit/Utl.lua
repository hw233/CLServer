
local skynet = require "skynet"
Utl = {}
-- 取得key的自增序列号
function Utl.nextVal(key)
    return skynet.call("CLDB", "lua", "nextVal", key);
end

return Utl