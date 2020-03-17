local skynet = require "skynet"
---@class Utl
DBUtl = {}
DBUtl.Keys = {
    default = "default",
    user = "user",
    city = "city",
    building = "building",
    server = "server",
    fleet = "fleet", -- 舰队
    unit = "unit", -- 战斗单元
    mail = "mail",
    report = "report", -- 战报
}
-- 取得key的自增序列号
function DBUtl.nextVal(key)
    return skynet.call("CLDB", "lua", "nextVal", key)
end

return DBUtl
