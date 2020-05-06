---@class USClearData 清除数据（过期数据）
local skynet = require "skynet"
require "skynet.manager" -- import skynet.register
require("public.include")
require("Errcode")
require("db.dbplayer")
require("db.dbmail")
require("db.dbmailplayer")
require("db.dbrewardpkg")
require("db.dbrewardpkgplayer")
require("db.dbreport")
require("db.dbbox")

local logic = {}
local CMD = {}
local bakMysql = nil -- 备份库
local _OneDaySec = 24 * 60 * 60 -- 一天的秒数
local _MailExpiredSec = 10 * _OneDaySec -- 邮件过期秒数

local clearDataTimer = function()
    local Y, M, D, hh, mm, ss = dateEx.getYYMMDDHHmmss()
    local date1 = dateEx.newDate(Y, M, D, 2, 0, 0) -- 凌晨2点开始
    local diff = date1 - dateEx.now()
    if diff <= 10 then
        local date1 = date1 + _OneDaySec
        diff = date1 - dateEx.now()
    end
    timerEx.new(diff, logic.doClearData)
end

local resetDataTimer = function()
    local Y, M, D, hh, mm, ss = dateEx.getYYMMDDHHmmss()
    local date1 = dateEx.newDate(Y, M, D, 0, 0, 10) -- 凌晨0点开始
    local diff = date1 - dateEx.now()
    if diff <= 10 then
        local date1 = date1 + _OneDaySec
        diff = date1 - dateEx.now()
    end
    timerEx.new(diff, logic.doResetData)
end

---public 重置
logic.doResetData = function()
    -- 重置在线玩家的pvptime
    logic.resetOnlinePlayersPvpTimes()
    --//TODO:其它0点后需要重轩的处理
    ---------------------------------------------------------
    --处理下次重置
    resetDataTimer()
end

---public 重置在线玩家的pvptime
logic.resetOnlinePlayersPvpTimes = function()
    local agents = skynet.call("watchdog", "lua", "getAllAgents")
    local pidx = 0
    ---@type dbplayer
    local player = nil
    for fd, a in pairs(agents) do
        pidx = skynet.call("watchdog", "lua", "getPidx", fd)
        player = dbplayer.instanse(pidx)
        if not player:isEmpty() then
            player:set_pvptimesTody(0)
        end
        player:release()
    end
end
----------------------------------------------------
---public 连接备份库
logic.connectBakMySql = function()
    -- 连接mysql
    bakMysql = skynet.newservice("CLMySQL", "false") -- 好像不能直接传boolean类型
    skynet.call(
        bakMysql,
        "lua",
        "connect",
        {
            host = "127.0.0.1",
            port = 3306,
            database = "island_bak",
            user = "root",
            password = "123.",
            max_packet_size = 1024 * 1024,
            synchrotime = 10 * 100, -- 同步数据时间间隔 100=1秒
            isDebug = true
        }
    )
end

---public 断开备份库的连接
logic.disConnectBakMySql = function()
    if bakMysql then
        skynet.call(bakMysql, "lua", "stop", false)
        skynet.kill(bakMysql)
    end
    bakMysql = nil
end

---public 备份数据
logic.bakData = function(insertSql)
    if (not CLUtl.isNilOrEmpty(insertSql)) and bakMysql then
        skynet.call(bakMysql, "lua", "SAVE", insertSql)
    end
end

logic.doClearData = function()
    -- 连接备份库
    logic.connectBakMySql()
    ---------------------------------------------------------
    logic.clearMails()
    logic.clearReports()
    logic.clearRewards()
    logic.clearPlayers()

    -- 断开备份库
    logic.disConnectBakMySql()
    ---------------------------------------------------------
    -- 处理下次清理
    clearDataTimer()
end

---public 清除邮件
logic.clearMails = function()
    local timeOutSec = dateEx.now() - _MailExpiredSec -- n天前的邮件
    local day = dateEx.seconds2Str(timeOutSec, dateEx.yy_mm_dd)
    local sql = "select * from mail where Date(`date`) <= '" .. day .. "' and parent <= 0;"
    printw("清除邮件 ===" .. sql)
    local list = skynet.call("CLMySQL", "lua", "exesql", sql)
    if list and list.errno then
        skynet.error("sql error==" .. sql)
        return
    end
    ---@type dbmail
    local mailIns
    for i, mail in ipairs(list) do
        mailIns = dbmail.instanse(mail[dbmail.keys.idx])
        if not mailIns:isEmpty() then
            -- 如果有回复信息，判断最新回复的时间
            local hisList = dbmail.getListByparent(mailIns:get_idx())
            if #hisList > 0 then
                local isTimeOut = true
                -- 有回复邮件
                for j, subMail in ipairs(hisList) do
                    if subMail[dbmail.keys.date] > timeOutSec then
                        -- 只要有一封邮件的时间未超时，就不能删除
                        isTimeOut = false
                        break
                    end
                end
                if isTimeOut then
                    logic.clearOneMail(mailIns)
                end
            else
                -- 没有回复信息，直接清理
                logic.clearOneMail(mailIns)
            end
        end
        mailIns:release()
        mailIns = nil
    end
end

---@param mailIns dbmail
logic.clearOneMail = function(mailIns)
    local rwidx = mailIns:get_rewardIdx() -- 奖励id
    -- 取得该邮件所属的玩家
    local mail4players = dbmailplayer.getListBymidx(mailIns:get_idx())
    for j, mp in ipairs(mail4players) do
        -- 不管三七二十一，只要过期的邮件都清理掉
        -- 奖励清理
        local state = mp[dbmailplayer.keys.state]
        if state == IDConst.MailState.unread and rwidx > 0 then
            -- 说明有奖励还未领取
            local reward4Player = dbrewardpkgplayer.instanse(mp[dbmailplayer.keys.pidx], rwidx)
            if not reward4Player:isEmpty() then
                logic.bakData(reward4Player:getInsertSql()) -- 先备份
                reward4Player:delete() -- 删除掉
                reward4Player = nil
            end
        end

        -- 玩家的邮件关系清理
        local mpIns = dbmailplayer.instanse(mp[dbmailplayer.keys.pidx], mp[dbmailplayer.keys.midx])
        if not mpIns:isEmpty() then
            if rwidx > 0 then
                -- 有奖励备份一下
                logic.bakData(mpIns:getInsertSql()) -- 备份
            end
            mpIns:delete()
            mpIns = nil
        end
    end

    -- 最后把邮件实体也清理掉
    if mailIns:get_type() == IDConst.MailType.private then
        -- 如果是私信，还要把语言表清理
        skynet.call("USLanguage", "lua", "delByKey", mailIns:get_titleKey())
        skynet.call("USLanguage", "lua", "delByKey", mailIns:get_contentKey())
    else
        logic.bakData(mailIns:getInsertSql()) -- 私信不备份
    end
    mailIns:delete()
    mailIns = nil
end

---public 清理战报数据
logic.clearReports = function()
    local sec = dateEx.now() - _MailExpiredSec -- n天前的战报
    local day = dateEx.seconds2Str(sec, dateEx.yy_mm_dd)
    local sql =
        "select * from " .. dbreport.name .. " where Date(`" .. dbreport.keys.crttime .. "`) <= '" .. day .. "';"
    print("清理战报数据" == sql)
    local list = skynet.call("CLMySQL", "lua", "exesql", sql)
    if list and list.errno then
        skynet.error("sql error==" .. sql)
        return
    end
    local report
    for i, v in ipairs(list) do
        report = dbreport.instanse(v[dbreport.keys.idx])
        report:delete()
        report = nil
    end
end

---public 清理奖励数据
logic.clearRewards = function()
    -- 看看玩家是否还引用了奖励包，看看宝箱表是否还引用奖励包，都没有，那就清理&备份
    local sql = "select * from " .. dbrewardpkg.name .. ";"
    print("清理奖励包数据 ===" .. sql)
    local list = skynet.call("CLMySQL", "lua", "exesql", sql)
    if list and list.errno then
        skynet.error("sql error==" .. sql)
        return
    end
    ---@type dbmail
    local rewardIns
    for i, reward in ipairs(list) do
        local list1 = dbrewardpkgplayer.getListByrwidx(reward[dbrewardpkg.keys.rwidx])
        local list2 = dbbox.getListByrwidx(reward[dbrewardpkg.keys.rwidx])
        if #list1 == 0 and #list2 == 0 then
            rewardIns = dbrewardpkg.instanse(reward[dbrewardpkg.keys.idx])
            logic.bakData(rewardIns:getInsertSql())
            rewardIns:delete()
            rewardIns = nil
        end
    end
end

---public 清理玩家
logic.clearPlayers = function()
    --[[ //TODO:
        1.超过5天未登陆、未充值、未过新手引导；直接清理
        2.超过10天未登陆、未充值、等级低于x；直接清理
        3.超过20天未登陆、未充值、玩家总数量>n；清理
        4.超过30天未登陆；清理&备份数据
    ]]
    --清理对象： 主城、建筑、地块、舰队、大地图数据、道具、玩家表
end
--============================================================
skynet.start(
    function()
        skynet.dispatch(
            "lua",
            function(_, _, command, ...)
                local f = CMD[command] or logic[command]
                skynet.ret(skynet.pack(f(...)))
            end
        )
        -- 启动一个线路处理清除数据
        skynet.fork(clearDataTimer)
        skynet.fork(resetDataTimer)

        skynet.register "USClearData"
    end
)
