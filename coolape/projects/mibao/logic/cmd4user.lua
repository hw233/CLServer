local skynet = require("skynet")
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
        if CLUtl.isNilOrEmpty(u:getuid()) then
            -- 说明是没有数据
            local ret = {}
            ret.msg = "plese regist first";
            ret.code = errcode.needregist
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
            --print(skynet.call("CLDB", "lua", "getInsertSql", u:name(), u:value()))
            --print(skynet.call("CLDB", "lua", "getUpdateSql", u:name(), u:value()))
            --print(skynet.call("CLDB", "lua", "getdeleteSql", u:name(), u:value()))
            return NetProto.send.login(ret, user, skynet.time())
        end
    end,

    regist = function(m)
        -- 注册

    end,
}

return cmd4user