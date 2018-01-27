-- 玩家的逻辑处理
local skynet = require("skynet")
require("Errcode")
---@type CLUtl
local CLUtl = require("CLUtl")
local Utl = require "Utl"
---@type dateEx
local dateEx = require("dateEx")
---@type NetProtoUsermgr
local NetProto = NetProtoUsermgr
local table = table

local cmd4player = {}
local myself;

cmd4player.CMD = {
    regist = function(m, fd)
        -- 注册
        local ret = {}
        if CLUtl.isNilOrEmpty(m.userId) or CLUtl.isNilOrEmpty(m.password) then
            ret.msg = "用户名和密码不能为空";
            ret.code = Errcode.error
            return NetProto.send.registAccount(ret, nil, 0, dateEx.nowMS())
        end
        if myself == nil then
            myself = dbuser.instanse(m.userId)
        end
        if not CLUtl.isNilOrEmpty(myself:getuid()) then
            ret.msg = "用户名已经存在";
            ret.code = Errcode.uidregisted
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
        return ret;
    end,

    login = function(m, fd)
        -- 登陆
        if m.userId == nil then
            local ret = {}
            ret.msg = "参数错误！";
            ret.code = Errcode.error
            return NetProto.send.loginAccount(ret)
        end
        if myself == nil then
            myself = dbuser.instanse(m.userId)
        end
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
            return NetProto.send.loginAccount(ret, nil, 0, dateEx.nowMS())
        else
            local ret = {}
            ret.msg = nil;
            ret.code = Errcode.ok
            local user = {}
            user.idx = myself:getidx()
            user.name = "user" --  string

            local serveridx = 0
            if m.appid ~= 1001 then
                -- 1001:咪宝
                serveridx = getServerid(user.idx, m.appid, m.channel)
            end
            local ret = NetProto.send.loginAccount(ret, user, serveridx, dateEx.nowMS())
            return ret
        end
    end,
    logout = function(m, fd)
        --TODO:把相关处理入库
        if myself then
            myself:release();
            myself = nil;
        end
        skynet.call("watchdog", "lua", "close", fd)
    end,

}

return cmd4player
