--if cmd4player ~= nil then
--    printe("this logic may not entry")
--end

-- 玩家的逻辑处理
local cmd4player = {}

local skynet = require("skynet")
require("public.include")
require("Errcode")
---@type CLUtl
local CLUtl = require("CLUtl")
local DBUtl = require "DBUtl"
---@type dateEx
local dateEx = require("dateEx")
local NetProtoName = skynet.getenv("NetProtoName")
require("dbplayer")

local table = table

---@type dbplayer
local myself
local city
local agent
local isEditMode
local CMD = {}
CMD.getEditMode = function()
    return isEditMode
end
CMD.login = function(m, fd, _agent)
    local cmd = m.cmd
    isEditMode = m.isEditMode
    agent = _agent
    -- 登陆
    if m.uidx == nil then
        local ret = {}
        ret.msg = "参数错误！"
        ret.code = Errcode.error
        return skynet.call(NetProtoName, "lua", "send", cmd, ret, nil, dateEx.nowMS(), fd, m)
    end
    if myself == nil then
        myself = dbplayer.instanse(m.uidx)
    end
    if myself:isEmpty() then
        -- 说明是没有数据,新号
        local player = {}
        player.idx = m.uidx
        player.status = 1
        player.name = "new player"
        player.lev = 1
        player.money = 0
        player.diam = 100
        player.cityidx = 0
        player.unionidx = 0
        player.crtTime = dateEx.nowStr()
        player.lastEnTime = dateEx.nowStr()
        player.channel = m.channel
        player.deviceid = m.deviceID
        if not myself:init(player, true) then
            printe("create player err==" .. m.uidx)
            local ret = {}
            ret.msg = "create player err"
            ret.code = Errcode.error
            return skynet.call(NetProtoName, "lua", "send", cmd, ret, nil, dateEx.nowMS(), fd, m)
        end
    end
    -- 增加触发器
    myself:setTrigger(skynet.self(), "onPlayerChg")

    local ret = {}
    ret.msg = nil
    ret.code = Errcode.ok
    return skynet.call(NetProtoName, "lua", "send", cmd, ret, myself:value2copy(), dateEx.nowMS(), fd, m)
end

CMD.release = function(m, fd)
    print("player release")
    if myself then
        myself:unsetTrigger(skynet.self(), "onPlayerChg")
        myself:release()
        myself = nil
    end
end

CMD.logout = function(m, fd)
    skynet.call("watchdog", "lua", "close", fd, m)
end

CMD.onPlayerChg = function(data, cmd)
    cmd = cmd or "onPlayerChg"
    local ret = {}
    ret.code = Errcode.ok
    local package = skynet.call(NetProtoName, "lua", "send", cmd, ret, myself:value2copy())
    skynet.call(agent, "lua", "sendPackage", package)
end

CMD.getPlayer = function(m)
    -- 取得玩家信息
    return myself:value2copy()
end

CMD.chgDiam = function(m)
    -- 修改宝石数量
    if m.diam == nil then
        return false
    end
    myself:set_diam(myself:get_diam() - m.diam)
    return true
end

skynet.start(
    function()
        skynet.dispatch(
            "lua",
            function(_, _, command, ...)
                local f = CMD[command]
                if f then
                    skynet.ret(skynet.pack(f(...)))
                else
                    error("cmd func is nil.cmd == " .. command)
                end
            end
        )
    end
)
