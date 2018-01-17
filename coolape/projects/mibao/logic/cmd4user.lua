local skynet = require("skynet")
require("dbuser")
require("Errcode")
---@type CLUtl
local CLUtl = require("CLUtl")
cmd4user = {}

---@type dbuser
local myself = nil;

cmd4user.CMD = {
    regist = function(m, fd)
        -- 注册
        local ret = {}
        if CLUtl.isNilOrEmpty(m.userId) or CLUtl.isNilOrEmpty(m.password) then
            ret.msg = "用户名和密码不能为空";
            ret.code = Errcode.error
            return NetProto.send.regist(ret, nil, 0)
        end
        myself = dbuser.instanse(m.userId)
        if not CLUtl.isNilOrEmpty(myself:getuid()) then
            ret.msg = "用户名已经存在";
            ret.code = Errcode.uidregisted
            return NetProto.send.regist(ret, nil, 0)
        end
        local newuser = {}
        newuser.uid = m.userId
        newuser.password = m.password
        myself:init(newuser)

        ret.msg = nil;
        ret.code = Errcode.ok
        local user = {}
        user.id = myself:getuid() --  string
        user.ver = 0 --  int
        user.name = "user" --  string
        user.lev = 1 --  int
        return NetProto.send.regist(ret, user, skynet.time(), fd)
    end,

    login = function(m, fd)
        -- 登陆
        print(m.userId, m.password)
        ---@type dbuser
        if myself == nil then
            myself = dbuser.instanse(m.userId)
        end
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
            ret.code = Errcode.error
            return NetProto.send.login(ret, nil, 0)
        else
            local ret = {}
            ret.msg = nil;
            ret.code = Errcode.ok
            local user = {}
            user.id = myself:getuid() --  string
            user.ver = 0 --  int
            user.name = "user" --  string
            user.lev = 1 --  int
            return NetProto.send.login(ret, user, skynet.time(), fd)
        end
    end,

    logout = function(m, fd)
        local uid = m.__session__
        --local ret = {}
        if myself then
            if uid ~= myself:getuid() then
                ret.code = Errcode.error
                ret.msg = "数据错误"
                return NetProto.send.logout(ret)
            end
            myself:release()
            myself = nil;
        end
        --ret.code = Errcode.ok
        --NetProto.send.logout(ret) -- dosconnect not
        skynet.call("watchdog", "lua", "close", fd)
    end,
}

return cmd4user