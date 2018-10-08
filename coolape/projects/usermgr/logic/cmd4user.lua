local skynet = require("skynet")
require("dbuser")
require("dbuserserver")
require("dbservers")
require("Errcode")
---@type CLUtl
local CLUtl = require("CLUtl")
local DBUtl = require "DBUtl"
---@type dateEx
local dateEx = require("dateEx")
---@type NetProtoUsermgr
local NetProto = "NetProtoUsermgr"
require("CLGlobal")
local table = table

local cmd4user = {}

-- 取得服务器idx
local function getServerid(uidx, appid, channel)
    if not appid then
        return 0
    end
    local serveridx = 0
    ---@type dbuserserver
    local us = dbuserserver.instanse(uidx, appid)
    if us:isEmpty() then
        -- 说明该用户是第一次进来
        local list = dbservers.getListByappid(appid)
        if list and #list > 0 then
            for i, v in ipairs(list) do
                if v.isnew and (channel == nil or channel == "" or v.channel == channel) then
                    serveridx = v.idx
                    break
                end
            end
            if serveridx <= 0 then
                serveridx = list[1].idx
            end
            local d= {}
            d.appid = appid
            d.sidx = serveridx
            d.uidx = uidx
            us:init(d, true)
            us:release()
        end
    else
        serveridx = (us:get_sidx() or 0)
        us:release()
    end
    return serveridx
end

cmd4user.CMD = {
    registAccount = function(m, fd)
        -- 注册
        local ret = {}
        if CLUtl.isNilOrEmpty(m.userId) or CLUtl.isNilOrEmpty(m.password) then
            ret.msg = "用户名和密码不能为空";
            ret.code = Errcode.error
            return skynet.call(NetProto, "lua", "send", "registAccount", ret, nil, 0, dateEx.nowMS())
        end
        ---@type dbuser
        local myself = dbuser.instanse(m.userId, nil)
        if not CLUtl.isNilOrEmpty(myself:get_uid()) then
            ret.msg = "用户名已经存在";
            ret.code = Errcode.uidregisted
            myself:release()
            return skynet.call(NetProto, "lua", "send", "registAccount", ret, nil, 0, dateEx.nowMS())
        end
        --处理一个设备最大注册数量
        local list = dbuser.getListBydeviceid(m.deviceID)
        if #list > 10 then
            ret.msg = "同一设备注册账号超上限";
            ret.code = Errcode.toomanydevice
            myself:release()
            return skynet.call(NetProto, "lua", "send", "registAccount", ret, nil, 0, dateEx.nowMS())
        end

        local newuser = {}
        newuser.idx = DBUtl.nextVal(DBUtl.Keys.user)
        newuser.uidChl = ""
        newuser.uid = m.userId
        newuser.password = m.password
        newuser.crtTime = dateEx.nowStr()
        newuser.lastEnTime = dateEx.nowStr()
        newuser.status = 0
        newuser.appid = m.appid
        newuser.channel = m.channel
        newuser.deviceid = m.deviceID
        newuser.deviceinfor = m.deviceInfor
        if not myself:init(newuser, true) then
            ret.msg = "注册失败";
            ret.code = Errcode.error
            return skynet.call(NetProto, "lua", "send", "registAccount", ret, nil, 0, dateEx.nowMS())
        end

        ret.msg = nil;
        ret.code = Errcode.ok
        local user = {}
        user.idx = myself:get_idx()
        --user.name = "user" --  string

        local serveridx = 0
        if m.appid ~= 1001 then
            serveridx = getServerid(newuser.idx, m.appid, m.channel)
        end
        local ret = skynet.call(NetProto, "lua", "send", "registAccount", ret, user, serveridx, dateEx.nowMS())
        myself:release()
        return ret;
    end,

    loginAccount = function(m, fd)
        -- 登陆
        if CLUtl.isNilOrEmpty(m.userId) then
            local ret = {}
            ret.msg = "参数错误！";
            ret.code = Errcode.error
            return skynet.call(NetProto, "lua", "send", "loginAccount", ret)
        end
        ---@type dbuser
        local myself = dbuser.instanse(m.userId, nil)
        if myself:isEmpty() then
            -- 说明是没有数据
            local ret = {}
            ret.msg = "用户不存在";
            ret.code = Errcode.needregist
            return skynet.call(NetProto, "lua", "send", "loginAccount", ret, nil, 0, dateEx.nowMS())
        elseif m.password ~= myself:get_password() then
            -- 说明密码错误
            local ret = {}
            ret.msg = "密码错误";
            ret.code = Errcode.psderror
            myself:release()
            return skynet.call(NetProto, "lua", "send", "loginAccount", ret, nil, 0, dateEx.nowMS())
        else
            local ret = {}
            ret.msg = nil;
            ret.code = Errcode.ok
            local user = {}
            user.idx = myself:get_idx()
            myself:set_lastEnTime(dateEx.nowMS())
            --user.name = "user" --  string

            local serveridx = 0
            if m.appid ~= 1001 then
                -- 1001:咪宝
                serveridx = getServerid(user.idx, m.appid, m.channel)
            end
            local ret = skynet.call(NetProto, "lua", "send", "loginAccount", ret, user, serveridx, dateEx.nowMS())
            myself:release()
            return ret
        end
    end,

    loginAccountChannel = function(m, fd)
        -- 渠道登陆
        if CLUtl.isNilOrEmpty(m.userId) then
            local ret = {}
            ret.msg = "参数错误！";
            ret.code = Errcode.error
            return skynet.call(NetProto, "lua", "send", "loginAccountChannel", ret)
        end
        local ret = {}
        ---@type dbuser
        local myself = dbuser.instanse(nil, m.userId)
        if myself:isEmpty() then
            -- 说明是没有数据
            --local ret = {}
            --ret.msg = "用户不存在";
            --ret.code = Errcode.needregist
            --return NetProto.send.loginAccount(ret, nil, 0, dateEx.nowMS())

            local newuser = {}
            newuser.idx = DBUtl.nextVal(DBUtl.Keys.user)
            newuser.uidChl = m.userId
            newuser.uid = ""
            newuser.password = ""
            newuser.crtTime = dateEx.nowStr()
            newuser.lastEnTime = dateEx.nowStr()
            newuser.status = 0
            newuser.appid = m.appid
            newuser.channel = m.channel
            newuser.deviceid = m.deviceID
            newuser.deviceinfor = m.deviceInfor
            if not myself:init(newuser, true) then
                ret.msg = "注册失败";
                ret.code = Errcode.error
                return skynet.call(NetProto, "lua", "send", "loginAccountChannel", ret, 0, dateEx.nowMS())
            end
        end
        ret.msg = nil;
        ret.code = Errcode.ok
        local user = {}
        user.idx = myself:get_idx()
        myself:set_lastEnTime(dateEx.nowMS())
        --user.name = "user" --  string

        local serveridx = 0
        if m.appid ~= 1001 then
            -- 1001:咪宝
            serveridx = getServerid(user.idx, m.appid, m.channel)
        end
        local ret = skynet.call(NetProto, "lua", "send", "loginAccountChannel", ret, user, serveridx, dateEx.nowMS())
        myself:release()
        return ret
    end,
}

skynet.start(function()
    skynet.dispatch("lua", function(_, _, command, ...)
        local f = cmd4user.CMD[command]
        skynet.ret(skynet.pack(f(...)))
    end)
end)
