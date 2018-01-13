local skynet = require("skynet")
require("dbuser")
require("errcode")
---@type CLUtl
local CLUtl = require("CLUtl")
cmd4user = {}

cmd4user.CMD = {
    regist = function(m)
        -- 注册
        local ret = {}
        if CLUtl.isNilOrEmpty(m.userId) or CLUtl.isNilOrEmpty(m.password) then
            ret.msg = "用户名和密码不能为空";
            ret.code = errcode.error
            return NetProto.send.regist(ret, nil, 0)
        end
        local u = dbuser.instanse(m.userId)
        if not CLUtl.isNilOrEmpty(u:getuid()) then
            ret.msg = "用户名已经存在";
            ret.code = errcode.uidregisted
            return NetProto.send.regist(ret, nil, 0)
        end
        local newuser = {}
        newuser.uid = m.userId
        newuser.password = m.password
        u:init(newuser)

        ret.msg = nil;
        ret.code = errcode.ok
        local user = {}
        user.id = u:getuid() --  string
        user.ver = 0 --  int
        user.name = "user" --  string
        user.lev = 1 --  int
        return NetProto.send.regist(ret, user, skynet.time())
    end,

    login = function(m)
        -- 登陆
        print(m.userId, m.password)
        ---@type dbuser
        local u = dbuser.instanse(m.userId)
        if CLUtl.isNilOrEmpty(u:getuid()) then
            -- 说明是没有数据
            local ret = {}
            ret.msg = "用户不存在";
            ret.code = errcode.needregist
            return NetProto.send.login(ret, nil, 0)
        elseif m.password ~= u:getpassword() then
            -- 说明是没有数据
            local ret = {}
            ret.msg = "密码错误";
            ret.code = errcode.error
            return NetProto.send.login(ret, nil, 0)
        else
            u:setstatu(520)
            local u2 = dbuser.instanse(u:getuid(), u:getpassword())
            print("==============" .. u2:getstatu())
            local ret = {}
            ret.msg = nil;
            ret.code = errcode.ok
            local user = {}
            user.id = u:getuid() --  string
            user.ver = 0 --  int
            user.name = "user" --  string
            user.lev = 1 --  int
            return NetProto.send.login(ret, user, skynet.time())
        end
    end,
}

return cmd4user