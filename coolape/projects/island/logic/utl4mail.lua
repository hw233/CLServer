local skynet = require "skynet"
require "skynet.manager" -- import skynet.register
require("public.include")
require("Errcode")
require "db.dbcity"
require "db.dbfleet"

---@class utl4mail 邮件的处理
local logic = {}

local serverQueue = CLLQueue.new()

logic.borrowserver = function()
    if serverQueue:isEmpty() then
        return skynet.newservice("cmd4mail")
    else
        return serverQueue:deQueue()
    end
end

logic.returnserver = function(server)
    serverQueue:enQueue(server)
end
------------------------------------------------
------------------------------------------------
---public 发送战报
---@param type IDConst.BattleType
---@param reportIdx number 战报idx
---@param toPlayers list 需要收邮件的玩家
logic.sendBattleMail = function(type, attackName, targetName, reportIdx, toPlayers)
    local params = {attacker = attackName, target = targetName}
    local mailContent = {
        [dbmail.keys.parent] = 0, -- 父idx(其实就是邮件的idx，回复的邮件指向的主邮件的idx)
        [dbmail.keys.type] = IDConst.MailType.report, -- 类型，1：系统，2：战报；3：私信，4:联盟，5：客服
        [dbmail.keys.fromPidx] = IDConst.sysPidx, -- 发件人
        [dbmail.keys.toPidx] = 0, -- 收件人
        [dbmail.keys.titleKey] = (type == IDConst.BattleType.attackIsland) and "BattleReportTitle" or
            "BattleFleetReportTitle", -- 标题key
        [dbmail.keys.titleParams] = json.encode(params), -- 标题的参数(json的map)
        [dbmail.keys.contentKey] = "", -- 内容key
        [dbmail.keys.contentParams] = "", -- 内容参数(json的map)
        [dbmail.keys.rewardIdx] = 0, -- 奖励idx
        [dbmail.keys.comIdx] = reportIdx, -- 通用ID,可以关联到比如战报id等
        [dbmail.keys.backup] = "" -- 备用
    }
    local mailServer = logic.borrowserver()
    if mailServer then
        skynet.call(mailServer, "lua", "doSendMail", mailContent, toPlayers)
        logic.returnserver(mailServer)
    else
        printe("取得邮件服失败")
    end
end

---public 发送舰队沉没的邮件
logic.sendFleetSinkedMail = function(fidx)
    local fleet = dbfleet.instanse(fidx)
    if fleet:isEmpty() then
        fleet:release()
        return
    end
    local city = dbcity.instanse(fleet:get_cidx())
    local server = logic.borrowserver()
    if server then
        skynet.send(server, "lua", "sendFleetSinkedMail", fleet:get_name(), city:get_pidx())
        logic.returnserver(server)
    else
        printe("取得邮件服失败")
    end
    city:release()
    fleet:release()
end

---public 舰队返航
---@param reason IDConst.FleetBackReason
function logic.sendFleetBack(fidx, reason)
    --//TODO:
end

return logic
