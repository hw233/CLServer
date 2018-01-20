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
---@type UsermgrHttpProto
local NetProto = UsermgrHttpProto
local table = table

cmd4user = {}

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
    regist = function(m, fd)
        -- 注册
        local ret = {}
        if CLUtl.isNilOrEmpty(m.userId) or CLUtl.isNilOrEmpty(m.password) then
            ret.msg = "用户名和密码不能为空";
            ret.code = Errcode.error
            return NetProto.send.regist(ret, nil, 0)
        end
        ---@type dbuser
        local myself = dbuser.instanse(m.userId)
        if not CLUtl.isNilOrEmpty(myself:getuid()) then
            ret.msg = "用户名已经存在";
            ret.code = Errcode.uidregisted
            myself:release()
            return NetProto.send.regist(ret, nil, 0)
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
            return NetProto.send.regist(ret, nil, 0)
        end

        ret.msg = nil;
        ret.code = Errcode.ok
        local user = {}
        user.idx = myself:getidx()
        user.name = "user" --  string
        local ret = NetProto.send.regist(ret, user, getServerid(newuser.idx, m.appid, m.channel))
        myself:release()
        return ret;
    end,

    login = function(m, fd)
        -- 登陆
        if m.userId == nil then
            local ret = {}
            ret.msg = "参数错误！";
            ret.code = Errcode.error
            return NetProto.send.login(ret)
        end
        ---@type dbuser
        local myself = dbuser.instanse(m.userId)
        if myself:isEmpty() then
            -- 说明是没有数据
            local ret = {}
            ret.msg = "用户不存在";
            ret.code = Errcode.needregist
            return NetProto.send.login(ret, nil, 0)
        elseif m.password ~= myself:getpassword() then
            -- 说明密码错误
            local ret = {}
            ret.msg = "密码错误";
            ret.code = Errcode.psderror
            myself:release()
            return NetProto.send.login(ret, nil, 0)
        else
            local ret = {}
            ret.msg = nil;
            ret.code = Errcode.ok
            local user = {}
            user.idx = myself:getidx()
            user.name = "user" --  string
            myself:release()
            return NetProto.send.login(ret, user, getServerid(myself:getidx(), m.appid, m.channel))
        end
    end,

    setEnterServer = function(m, fd)
        -- 保存选服
        local uidx = m.uidx
        local sidx = m.sidx
        local appid = m.appid

        if uidx == nil or sidx == nil or appid == nil then
            local ret = {}
            ret.msg = "参数错误！";
            ret.code = Errcode.error
            return NetProto.send.setEnterServer(ret)
        end

        local us = dbuserserver.instanse(uidx, appid)
        if us:isEmpty() then
            local data = {}
            data.sidx = sidx
            data.uidx = uidx
            data.appid = appid
            us:init(data)
        end
        us:release()
        local ret = {}
        ret.msg = nil;
        ret.code = Errcode.ok
        return NetProto.send.setEnterServer(ret)
    end,

    getServerInfor = function(m, fd)
        -- 取得服务器信息
        if m.idx == nil then
            local ret = {}
            ret.msg = "参数错误！";
            ret.code = Errcode.error
            return NetProto.send.getServerInfor(ret)
        end

        local s = dbservers.instanse(m.idx)
        if s:isEmpty() then
            -- 未找到
            local ret = {}
            ret.msg = "未找到数据";
            ret.code = Errcode.error
            return NetProto.send.getServerInfor(ret, nil)
        end
        local ret = {}
        ret.msg = nil
        ret.code = Errcode.ok
        local result = s:value2copy()
        s:setisnew(false)
        result.isnew = s:getisnew()
        s:release()
        return NetProto.send.getServerInfor(ret, result)
    end,

    getServers = function(m, fg)
        -- 取得服务器列表
        local appid = m.appid
        local channel = m.channel
        if appid == nil then
            local ret = {}
            ret.msg = "参数错误！";
            ret.code = Errcode.error
            return NetProto.send.getServers(ret)
        end
        local list = dbservers.getList(appid, " idx desc ")
        local result = {}
        if list and #list > 0 then
            if channel then
                for i, v in ipairs(list) do
                    if v.channel == channel then
                        table.insert(result, v)
                    end
                end
            else
                result = list
            end
        end

        local ret = {}
        ret.msg = nil
        ret.code = Errcode.ok
        return NetProto.send.getServers(ret, result)
    end
}

return cmd4user
