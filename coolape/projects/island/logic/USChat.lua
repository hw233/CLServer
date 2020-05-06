---@class USClearData 清除数据（过期数据）
local skynet = require "skynet"
require "skynet.manager" -- import skynet.register
require("public.include")
require("Errcode")
require "db.dbchat"
require "db.dbplayer"
local Sort = require "CLQuickSort"

local table = table
---@type CLLQueue 时间屏道聊天信息
local worldChatQueue = CLLQueue.new()
local MaxCacheWorldChatNum = 100 -- 缓存的最大聊天数量
local logic = {}
local CMD = {}
local rootPath = "./coolape/projectsData/" .. skynet.getenv("projectName") .. "/chatData/"

logic.init = function()
    -- 加载之前的世界聊天信息
    worldChatQueue:clear()
    local str = fileEx.readAll(CLUtl.combinePath(rootPath, "worldChats.json"))
    if str then
        worldChatQueue.queue = json.decode(str) or {}
    end
end

logic.release = function(killself)
    -- 保存之前的世界聊天信息
    local chatstr = json.encode(worldChatQueue.queue)
    fileEx.createDir(rootPath)
    fileEx.writeAll(CLUtl.combinePath(rootPath, "worldChats.json"), chatstr)
    if killself then
        skynet.exit()
    end
end

---@param m NetProtoIsland.RC_sendChat
logic.doSendChat = function(fromPidx, toPidx, content, type)
    local d = {}
    d[dbchat.keys.idx] = DBUtl.nextVal(DBUtl.Keys.chat)
    d[dbchat.keys.fromPidx] = fromPidx
    d[dbchat.keys.toPidx] = toPidx
    d[dbchat.keys.content] = content
    d[dbchat.keys.type] = type
    d[dbchat.keys.time] = dateEx.nowMS()

    local pkg = pkg4Client({cmd = "onChatChg"}, {code = Errcode.ok}, {d})
    if type == IDConst.ChatType.world then
        worldChatQueue:enQueue(d)
        sendPkg2AllOnlinePlayers(pkg)
        -- 把超过最大缓存数量的聊天清除掉
        while (worldChatQueue:size() > MaxCacheWorldChatNum) do
            worldChatQueue:deQueue()
        end
    else
        -- 入库
        local chat = dbchat.new()
        chat:init(d, true)
        chat:release()
        if type == IDConst.ChatType.private then
            -- 私聊
            sendPkg2Player(fromPidx, pkg)
            sendPkg2Player(toPidx, pkg)
        elseif type == IDConst.ChatType.union then
        -- //TODO:盟聊天,这个时候toPidx其实是联盟idx，发送给盟里所有成员
        end
    end
end

logic.compareChat = function(a, b)
    return a[dbchat.keys.time] > b[dbchat.keys.time]
end
--============================================================
---@param m NetProtoIsland.RC_getChats
CMD.getChats = function(m, fd, agent)
    local pidx = getPlayerIdx(m.__session__) or 0
    local player = dbplayer.instanse(pidx)
    if player:isEmpty() then
        player:release()
        return pkg4Client(m, {code = Errcode.playerIsNil})
    end

    -- 私聊
    local chats2 = {}
    local list = dbchat.getListBytype_fromPidx(IDConst.ChatType.private, pidx) or {}
    print("list==" .. #list)
    for i, v in ipairs(list) do
        table.insert(chats2, v)
    end
    list = dbchat.getListBytype_toPidx(IDConst.ChatType.private, pidx) or {}
    print("list2222==" .. #list)
    for i, v in ipairs(list) do
        table.insert(chats2, v)
    end
    Sort.quickSort(chats2, logic.compareChat)

    -- 联盟
    local chats3 = {}
    local player = dbplayer.instanse(pidx)
    if player:get_unionidx() > 0 then
        list = dbchat.getListBytype_toPidx(IDConst.ChatType.union, player:get_unionidx()) or {}
        for i, v in ipairs(list) do
            table.insert(chats3, v)
        end
    end
    Sort.quickSort(chats3, logic.compareChat)

    player:release()

    return pkg4Client(m, {code = Errcode.ok}, worldChatQueue.queue, chats2, chats3)
end

---@param m NetProtoIsland.RC_sendChat
CMD.sendChat = function(m, fd, agent)
    -- 判断是不是可以发送信息
    if m.type == IDConst.ChatType.world then
        -- 世界频道只有玩家等级达到一定等级后才可以发送
        local pidx = getPlayerIdx(m.__session__)
        if pidx ~= IDConst.gmPidx then
            local player = dbplayer.instanse(pidx)
            if player:isEmpty() then
                player:release()
                return pkg4Client(m, {code = Errcode.playerIsNil})
            end
            if player:get_lev() < 5 then
                return pkg4Client(m, {code = Errcode.levTooLowCannotChatInWorld})
            end
            player:release()
        end
    elseif m.type == IDConst.ChatType.private then
        local targetPidx = m.toPidx
        local player = dbplayer.instanse(targetPidx)
        if player:isEmpty() then
            player:release()
            return pkg4Client(m, {code = Errcode.playerIsNil})
        end
        player:release()
    end
    local content = m.content
    if CLUtl.isNilOrEmpty(content) then
        return pkg4Client(m, {code = Errcode.contentIsNil})
    end
    if #content > 1000 then
        return pkg4Client(m, {code = Errcode.contentOverLen})
    end

    local pidx = getPlayerIdx(m.__session__) or 0
    logic.doSendChat(pidx, m.toPidx, m.content, m.type)
    return pkg4Client(m, {code = Errcode.ok})
end
--============================================================
logic.init()
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

        skynet.register "USChat"
    end
)
