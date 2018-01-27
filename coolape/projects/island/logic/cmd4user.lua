local skynet = require("skynet")
require("dbuser")
require("dbuserserver")
require("dbservers")
require("Errcode")
---@type CLUtl
local CLUtl = require("CLUtl")
local Utl = require "Utl"
---@type dateEx
local dateEx = require("dateEx")
---@type NetProtoUsermgr
local NetProto = NetProtoUsermgr
local table = table

local cmd4user = {}

-- 取得服务器idx
local function getServerid(uidx, appid, channel)
    if not appid then
        return 0
    end
    local us = dbuserserver.instanse(uidx, appid)
    if us:isEmpty() then
        -- 说明该用户是第一次进来
        local list = dbservers.getList(appid)
        if list and #list > 0 then
            for i, v in ipairs(list) do
                if v.isnew and (channel == nil or v.channel == channel) then
                    return v.idx
                end
            end
            return list[1].idx
        end
    end
    return (us:getsidx() or 0)
end

cmd4user.CMD = {
    registAccount = function(m, fd)
        -- 注册
        local ret = {}
        if CLUtl.isNilOrEmpty(m.userId) or CLUtl.isNilOrEmpty(m.password) then
            ret.msg = "用户名和密码不能为空";
            ret.code = Errcode.error
            return NetProto.send.registAccount(ret, nil, 0, dateEx.nowMS())
        end
        ---@type dbuser
        local myself = dbuser.instanse(m.userId)
        if not CLUtl.isNilOrEmpty(myself:getuid()) then
            ret.msg = "用户名已经存在";
            ret.code = Errcode.uidregisted
            myself:release()
            return NetProto.send.registAccount(ret, nil, 0, dateEx.nowMS())
        end
        local newuser = {}
        newuser.idx = Utl.nextVal("user")
        newuser.uid = m.userId
        newuser.password = m.password
        newuser.crtTime = dateEx.nowStr()
        newuser.lastEnTime = dateEx.nowStr()
        newuser.status = 0
        newuser.appid = m.appid
        newuser.channel = m.channel
        newuser.deviceid = m.deviceID
        newuser.deviceinfor = m.deviceInfor
        if not myself:init(newuser) then
            ret.msg = "注册失败";
            ret.code = Errcode.error
            return NetProto.send.registAccount(ret, nil, 0, dateEx.nowMS())
        end

        ret.msg = nil;
        ret.code = Errcode.ok
        local user = {}
        user.idx = myself:getidx()
        user.name = "user" --  string

        local serveridx = 0
        if m.appid ~= 1001 then
            serveridx = getServerid(newuser.idx, m.appid, m.channel)
        end
        local ret = NetProto.send.registAccount(ret, user, serveridx, dateEx.nowMS())
        myself:release()
        return ret;
    end,

    loginAccount = function(m, fd)
        -- 登陆
        if m.userId == nil then
            local ret = {}
            ret.msg = "参数错误！";
            ret.code = Errcode.error
            return NetProto.send.loginAccount(ret)
        end
        ---@type dbuser
        local myself = dbuser.instanse(m.userId)
        if myself:isEmpty() then
            -- 说明是没有数据
            local ret = {}
            ret.msg = "用户不存在";
            ret.code = Errcode.needregist
            return NetProto.send.loginAccount(ret, nil, 0, dateEx.nowMS())
        elseif m.password ~= myself:getpassword() then
            -- 说明密码错误
            local ret = {}
            ret.msg = "密码错误";
            ret.code = Errcode.psderror
            myself:release()
            return NetProto.send.loginAccount(ret, nil, 0, dateEx.nowMS())
        else
            local ret = {}
            ret.msg = nil;
            ret.code = Errcode.ok
            local user = {}
            user.idx = myself:getidx()
            user.name = "user" --  string

            local serveridx = 0
            if m.appid ~= 1001 then -- 1001:咪宝
                serveridx = getServerid(user.idx, m.appid, m.channel)
            end
            local ret = NetProto.send.loginAccount(ret, user, serveridx, dateEx.nowMS())
            myself:release()
            return ret
        end
    end,

}

return cmd4user
