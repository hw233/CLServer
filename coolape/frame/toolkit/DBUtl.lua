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
    reward = "reward", -- 奖励包
    item = "item", -- 道具
    itemused = "itemused", -- 道具
    box = "box", -- 宝箱
    chat = "chat", -- 聊天
    tech = "tech", -- 科技
}
-- 取得key的自增序列号
function DBUtl.nextVal(key)
    return skynet.call("CLDB", "lua", "nextVal", key)
end

return DBUtl
