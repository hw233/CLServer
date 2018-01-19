local skynet = require("skynet")
require("dbuser")
require("Errcode")
---@type CLUtl
local CLUtl = require("CLUtl")
---@type dateEx
local dateEx = require("dateEx")
---@type UsermgrHttpProto
local NetProto = UsermgrHttpProto

cmd4user = {}

-- 取得服务器idx
local function getServerid(uidx, appid)
    local us = dbuserserver.instanse(uidx, appid)
    local sidx = us:getsidx()
    if CLUtl.isNilOrEmpty(sidx) then
        -- 说明该用户是第一次进来
        local list = dbservers.getList(appid)
        if list then
            for i, v in ipairs(list) do
                if v.isnew then
                    return v.idx
                end
            end
            return list[1].idx
        end
    end
    return sidx;
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
        newuser.idx = skynet.call("CLDB", "lua", "nextVal", "user");
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
        local ret = NetProto.send.regist(ret, user, getServerid(newuser.idx, m.appid))
        myself:release()
        return ret;
    end,

    login = function(m, fd)
        -- 登陆
        --print(m.userId, m.password)
        ---@type dbuser
        local myself = dbuser.instanse(m.userId)
        if CLUtl.isNilOrEmpty(myself:getuid()) then
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
            return NetProto.send.login(ret, user, getServerid(myself:getidx(), m.appid))
        end
    end,
    -- 保存选服
    setEnterServer = function(m)
        local uidx = m.uidx
        local sidx = m.sidx
        local appid = m.appid

        local us = dbuserserver.instanse(uidx, appid)
        if CLUtl.isNilOrEmpty(us:getsidx()) then
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
}

return cmd4user
