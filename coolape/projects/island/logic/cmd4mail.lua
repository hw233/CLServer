---@class cmd4mail 邮件处理服务
local logic = {}
local skynet = require("skynet")
require "skynet.manager" -- import skynet.register
require("public.include")
require("public.cfgUtl")
require "db.dbplayer"
require "db.dbcity"
require "db.dbbuilding"
require "db.dbtile"
require "db.dbmail"
require "db.dbmailplayer"
require "db.dbreport"
require "db.dblanguage"
require("Errcode")

---@type CLQuickSort
local Sort = require "CLQuickSort"
local _DefaultLanguage = 0
local CMD = {}

---public 设置邮件的收发人信息
---@param mail dbmail
---@param pidx number 取邮件的玩家
local setUserInfor = function(m, mail, pidx)
    local type = mail:get_type()
    if type == IDConst.MailType.system or type == IDConst.MailType.report then
        m.fromPidx = "0"
        m.fromName = "System"
        m.fromIcon = 0
        m.toPidx = mail:get_toPidx()
        if m.toPidx == 0 then
            if pidx then
                -- 说明收件人为空，就是取信本人（只有系统邮件，发全服的时候应该会出现这情况）
                local player = dbplayer.instanse(pidx)
                if player:isEmpty() then
                    m.toPidx = pidx
                    m.toName = player:get_name()
                    m.toIcon = player:get_icon()
                    player:release()
                end
            end
        else
            local player = dbplayer.instanse(m.toPidx)
            if player:isEmpty() then
                m.toName = player:get_name()
                m.toIcon = player:get_icon()
                player:release()
            else
                m.toName = nil
                m.toIcon = 0
            end
            player = nil
        end
    elseif type == IDConst.MailType.private then
        local player = dbplayer.instanse(mail:get_fromPidx())
        if not player:isEmpty() then
            m.fromIcon = player:get_icon()
            m.fromName = player:get_name()
        end
        player:release()
        player = dbplayer.instanse(mail:get_toPidx())
        if not player:isEmpty() then
            m.toName = player:get_name()
            m.toIcon = player:get_icon()
        end
        player:release()
    end
    return m
end

---public 邮件列表排序(按时间的先后，方便客户处理)
local sortMails = function(a, b)
    return a[dbmail.keys.date] < b[dbmail.keys.date]
end

---public 倒序回复的子邮件列表（按时间的倒序）
local sortSubMails = function(id1, id2)
    local a = dbmail.instanse(id1)
    local b = dbmail.instanse(id2)
    local ret = a:get_date() > b:get_date()
    a:release()
    b:release()
    return ret
end

---public 取得邮件数据
---@param idx number 邮件idx
---@param language number 语言类型
---@param pidx number 取邮件的玩家
---@return NetProtoIsland.ST_mail
logic.getMail4Player = function(idx, language, pidx)
    language = language or 1
    local mail = dbmail.instanse(idx)
    if mail == nil or mail:isEmpty() then
        mail:release()
        return nil
    end
    local mailType = mail:get_type()
    if mailType == IDConst.MailType.private then
        -- 私信和客服邮件不用考虑语言类别
        language = _DefaultLanguage
    end
    local mailPlayer = dbmailplayer.instanse(pidx, idx)
    ---@type NetProtoIsland.ST_mail
    local mailVal = mail:value2copy()
    -- 设置状态
    mailVal.state = mailPlayer:get_state()
    mailPlayer:release()
    -- 用户信息
    mailVal = setUserInfor(mailVal, mail, pidx)
    -- 取得title
    mailVal.title = LGet(language, mail:get_titleKey())
    -- 取得内容
    if CLUtl.isNilOrEmpty(mail:get_contentKey()) then
        mailVal.content = ""
    else
        mailVal.content = LGet(language, mail:get_contentKey())
    end

    mailVal.historyList = {}
    -- 设置回复的子邮件
    if mail:get_parent() > 0 then
        local children = dbmail.getListByparent(mail:get_parent())
        if children and #children > 0 then
            for i, v in ipairs(children) do
                if v[dbmail.keys.date] <= mail:get_date() then
                    -- 只有时间小于当前邮件的发送时间才是当前邮件的历史记录
                    table.insert(mailVal.historyList, v[dbmail.keys.idx])
                end
            end
        end
        -- 最后把最开始的邮件记录下
        table.insert(mailVal.historyList, mail:get_parent())
    else
        -- 自己也算是历史
        table.insert(mailVal.historyList, mail:get_idx())
    end

    -- 历史记录倒序
    if #mailVal.historyList > 1 then
        Sort.quickSort(mailVal.historyList, sortSubMails)
    end

    mail:release()
    return mailVal
end

---public 取得玩家的邮件列表
logic.getMailsByPidx = function(pidx)
    local player = dbplayer.instanse(pidx)
    if player:isEmpty() then
        player:release()
        printe("玩家取得为nil")
        return {}
    end
    local language = player:get_language()

    -- //TODO:每次只能取得100条?
    local list = dbmailplayer.getListBypidx(pidx) or {}
    local mails = {}
    ---@type NetProtoIsland.ST_mail
    local mailData
    for i, v in ipairs(list) do
        mailData = logic.getMail4Player(v[dbmailplayer.keys.midx], language, pidx)
        if mailData then
            table.insert(mails, mailData)
        else
            printw("get mail is nil !!!!!!!!!!! id=" .. v[dbmailplayer.keys.midx])
        end
    end
    Sort.quickSort(mails, sortMails)

    player:release()
    return mails
end

---public 新建邮件
logic.newMail = function(m)
    local idx = DBUtl.nextVal(DBUtl.Keys.mail)
    local mail =
        dbmail.new(
        {
            [dbmail.keys.idx] = idx,
            [dbmail.keys.parent] = m.parent or 0, -- 父idx(其实就是邮件的idx，回复的邮件指向的主邮件的idx)
            [dbmail.keys.type] = m.type, -- 类型，1：系统，2：战报；3：私信，4:联盟，5：客服
            [dbmail.keys.fromPidx] = m.fromPidx, -- 发件人
            [dbmail.keys.toPidx] = m.toPidx or 0, -- 收件人
            [dbmail.keys.titleKey] = m.titleKey, -- 标题key
            [dbmail.keys.titleParams] = m.titleParams, -- 标题的参数
            [dbmail.keys.contentKey] = m.contentKey, -- 内容key
            [dbmail.keys.contentParams] = m.contentParams, -- 内容参数
            [dbmail.keys.date] = dateEx.nowMS(), -- 时间
            [dbmail.keys.rewardIdx] = m.reward or 0, -- 奖励idx
            [dbmail.keys.comIdx] = m.comIdx or 0, -- 通用ID,可以关联到其它的id，比如战报id等
            [dbmail.keys.backup] = m.backup or "" -- 备用
        },
        true
    )
    return mail:release(true)
end

---public 发送邮件给玩家
logic.pushToPlayer = function(midx, toPidx)
    ---@type dbmailplayer
    local mp = dbmailplayer.new()
    mp:init(
        {
            [dbmailplayer.keys.midx] = midx,
            [dbmailplayer.keys.pidx] = toPidx,
            [dbmailplayer.keys.state] = IDConst.MailState.unread
        },
        true
    )
    logic.onMailChg(midx, toPidx)
    mp:release()
end

logic.onMailChg = function(midx, toPidx)
    -- send to user
    local agent = getPlayerAgent(toPidx)
    if agent then
        -- 在线，推送给玩家
        local player = dbplayer.instanse(toPidx)
        local language = player:get_language() or 1
        player:release()
        local package =
            pkg4Client({cmd = "onMailChg"}, {code = Errcode.ok}, {logic.getMail4Player(midx, language, toPidx)})
        sendPkg2Player(toPidx, package)
    end
end

---public 发送邮件
---@param toPlayers table 需要发送给玩家的idx列表
logic.doSendMail = function(mailContent, toPlayers)
    local mail = logic.newMail(mailContent)
    for i, pidx in ipairs(toPlayers) do
        logic.pushToPlayer(mail[dbmail.keys.idx], pidx)
    end
end

---public 发送舰队沉没的邮件
logic.sendFleetSinkedMail = function(fleetName, toPidx)
    local params = json.encode({fleetName = fleetName})
    local mailContent = {
        [dbmail.keys.parent] = 0, -- 父idx(其实就是邮件的idx，回复的邮件指向的主邮件的idx)
        [dbmail.keys.type] = IDConst.MailType.system, -- 类型，1：系统，2：战报；3：私信，4:联盟，5：客服
        [dbmail.keys.fromPidx] = IDConst.sysPidx, -- 发件人
        [dbmail.keys.toPidx] = toPidx, -- 收件人
        [dbmail.keys.titleKey] = "MailFleetSinkedTitle", -- 标题key
        [dbmail.keys.titleParams] = params, -- 标题的参数
        [dbmail.keys.contentKey] = "MailFleetSinkedContent", -- 内容key
        [dbmail.keys.contentParams] = params -- 内容参数
    }
    local mail = logic.newMail(mailContent)
    logic.pushToPlayer(mail[dbmail.keys.idx], toPidx)
end

logic.release = function()
end

-----------------------------------------------------
--CMD------------------------------------------------
-----------------------------------------------------
---@param m NetProtoIsland.RC_getMails
CMD.getMails = function(m, fd, agent)
    local pidx = getPlayerIdx(fd)
    local mails = logic.getMailsByPidx(pidx)
    return pkg4Client(m, {code = Errcode.ok}, mails)
end

---@param m NetProtoIsland.RC_getReportResult
CMD.getReportResult = function(m, fd, agent)
    local report = dbreport.instanse(m.idx)
    if report:isEmpty() then
        report:release()
        return pkg4Client(m, {code = Errcode.Errcode.reportIsNil}, nil)
    end
    local resultStr = report:get_result()
    local result = json.decode(resultStr)
    report:release()
    return pkg4Client(m, {code = Errcode.ok}, result)
end

---@param m NetProtoIsland.RC_getReportDetail
CMD.getReportDetail = function(m, fd, agent)
    local report = dbreport.instanse(m.idx)
    if report:isEmpty() then
        report:release()
        return pkg4Client(m, {code = Errcode.Errcode.reportIsNil})
    end
    local type = report:get_type()
    local resultStr = report:get_result()
    local result = json.decode(resultStr or "")

    ---@type NetProtoIsland.ST_battleDetail
    local battleContent
    ---@type NetProtoIsland.ST_battleFleetDetail
    local battleFleetConent
    if type == IDConst.BattleType.attackIsland then
        battleContent = json.decode(report:get_content())

        local tiles = {}
        for i, v in ipairs(battleContent.targetCity.tiles) do
            tiles[v[dbtile.keys.idx]] = v
        end
        battleContent.targetCity.tiles = tiles

        local buildings = {}
        for i, v in ipairs(battleContent.targetCity.buildings) do
            buildings[v[dbbuilding.keys.idx]] = v
        end
        battleContent.targetCity.buildings = buildings
    else
        battleFleetConent = json.decode(report:get_content())
        battleFleetConent = battleFleetConent.battleData
    end
    report:release()
    return pkg4Client(m, {code = Errcode.ok}, m.idx, type, battleContent, battleFleetConent, result)
end

---@param m NetProtoIsland.RC_sendMail
CMD.sendMail = function(m, fd, agent)
    ---@type NetProtoIsland.ST_retInfor
    local ret = {}
    local fromPidx = getPlayerIdx(m.__session__)
    local toPidx = m.toPidx
    local player = dbplayer.instanse(fromPidx)
    if player:isEmpty() then
        player:release()
        ret.code = Errcode.playerIsNil
        return pkg4Client(m, ret)
    end
    player:release()

    player = dbplayer.instanse(toPidx)
    if player:isEmpty() then
        player:release()
        ret.code = Errcode.playerIsNil
        return pkg4Client(m, ret)
    end
    player:release()

    -- 设置语言表
    local titleKey = MD5.sumhexa(m.title)
    skynet.call("USLanguage", "lua", "set", _DefaultLanguage, titleKey, m.title)
    local contentKey = MD5.sumhexa(m.content)
    skynet.call("USLanguage", "lua", "set", _DefaultLanguage, contentKey, m.content)
    local mailContent = {}
    mailContent[dbmail.keys.titleKey] = titleKey
    mailContent[dbmail.keys.contentKey] = contentKey
    mailContent[dbmail.keys.fromPidx] = fromPidx
    mailContent[dbmail.keys.toPidx] = toPidx
    mailContent[dbmail.keys.type] = m.type

    -- 发送邮件
    logic.doSendMail(mailContent, {fromPidx, toPidx})

    ret.code = Errcode.ok
    return pkg4Client(m, ret)
end

---@param m NetProtoIsland.RC_readMail
CMD.readMail = function(m, fd, agent)
    local pidx = getPlayerIdx(m.__session__)
    local mail = dbmailplayer.instanse(pidx, m.idx)
    if mail:isEmpty() then
        mail:release()
        return pkg4Client(m, {code = Errcode.mailIsNil})
    end
    if mail:get_state() == IDConst.MailState.readRewared then
        mail:release()
        return pkg4Client(m, {code = Errcode.mailHadReaded})
    end
    mail:set_state(IDConst.MailState.readRewared)
    local player = dbplayer.instanse(pidx)

    local mailVal = logic.getMail4Player(mail:get_midx(), player:get_language(), pidx)
    player:release()
    mail:release()
    logic.onMailChg(m.idx, pidx)
    return pkg4Client(m, {code = Errcode.ok}, mailVal)
end

---@param m NetProtoIsland.RC_receiveRewardMail
CMD.receiveRewardMail = function(m, fd, agent)
    --//TODO:
end

---@param m NetProtoIsland.RC_deleteMail
CMD.deleteMail = function(m, fd, agent)
end
---@param m NetProtoIsland.RC_replyMail
CMD.replyMail = function(m, fd, agent)
    ---@type NetProtoIsland.ST_retInfor
    local ret = {}
    local mail = dbmail.instanse(m.idx)
    if mail:isEmpty() then
        mail:release()
        ret.code = Errcode.mailIsNil
        return pkg4Client(m, ret)
    end

    local fromPidx = getPlayerIdx(m.__session__)
    local player = dbplayer.instanse(fromPidx)
    if player:isEmpty() then
        player:release()
        ret.code = Errcode.playerIsNil
        return pkg4Client(m, ret)
    end
    player:release()

    local toPidx = mail:get_fromPidx()
    player = dbplayer.instanse(toPidx)
    if player:isEmpty() then
        player:release()
        ret.code = Errcode.playerIsNil
        return pkg4Client(m, ret)
    end
    player:release()

    -- 设置语言表
    local contentKey = MD5.sumhexa(m.content)
    skynet.call("USLanguage", "lua", "set", _DefaultLanguage, contentKey, m.content)
    local mailContent = {}
    local parent = mail:get_parent()
    if parent == nil or parent <= 0 then
        parent = m.idx
    end
    mailContent[dbmail.keys.parent] = parent
    mailContent[dbmail.keys.titleKey] = mail:get_titleKey()
    mailContent[dbmail.keys.contentKey] = contentKey
    mailContent[dbmail.keys.fromPidx] = fromPidx
    mailContent[dbmail.keys.toPidx] = toPidx
    mailContent[dbmail.keys.type] = mail:get_type()

    mail:release()
    -- 发送邮件
    logic.doSendMail(mailContent, {fromPidx, toPidx})

    ret.code = Errcode.ok
    return pkg4Client(m, ret)
end
-----------------------------------------------------
-----------------------------------------------------
-----------------------------------------------------
skynet.start(
    function()
        skynet.dispatch(
            "lua",
            function(_, _, command, ...)
                local f = CMD[command] or logic[command]
                if f == nil then
                    error("func is nill.cmd =" .. command)
                else
                    skynet.ret(skynet.pack(f(...)))
                end
            end
        )
    end
)
