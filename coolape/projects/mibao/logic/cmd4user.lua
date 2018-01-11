
require("dbuser")
require("errcode")
---@type CLUtl
local CLUtl = require("CLUtl")
cmd4user = {}

cmd4user.CMD = {
    login = function(m)
        -- 登陆
        print(m.userId, m.password)
        ---@type dbuser
        local u = dbuser.instanse(m.userId, m.password)
        if CLUtl.isNilOrEmpty(u.uid) then
            -- 说明是没有数据
            local ret = {}
            ret.msg = "plese regist first";
            ret.code = errcode.needregist
            return NetProto.send.login(ret, nil, 0)
        else
            local ret = {}
            ret.msg = nil;
            ret.code = errcode.ok
            local user = {}
            user.id = u.uid --  string
            user.ver = 0 --  int
            user.name = "user" --  string
            user.lev = 1 --  int
            return NetProto.send.login(ret, user, skynet.time())
        end
    end,
}

return cmd4user