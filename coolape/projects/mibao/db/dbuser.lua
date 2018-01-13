require("class")
local skynet = require "skynet"

-- 用户表
dbuser = class("dbuser")

dbuser.name = "user"

function dbuser:ctor(v)
    self.__name__ = "user"    -- 表名
    self.__isNew__ = true    -- 新建数据，说明mysql表里没有数据
    self.__key__ = nil --- 缓存数据的key
end

function dbuser:init(data)
    self.__key__ = data.uid .. "_" .. data.password
end

function dbuser:tablename() -- 取得表名
    return self.__name__
end

function dbuser:value2copy()  -- 取得数据复样，注意是只读的数据且只有当前时刻是最新的，如果要取得最新数据及修改数据，请用get、set
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__)
end

function dbuser:setuid(v)
    -- 用户id
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "uid", v)
end
function dbuser:getuid()
    -- 用户id
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "uid")
end

function dbuser:setpassword(v)
    -- 用户密码
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "password", v)
end
function dbuser:getpassword()
    -- 用户密码
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "password")
end

function dbuser:setcrtTime(v)
    -- 创建时间
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "crtTime", v)
end
function dbuser:getcrtTime()
    -- 创建时间
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "crtTime")
end

function dbuser:setlastEnTime(v)
    -- 最后登陆时间
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "lastEnTime", v)
end
function dbuser:getlastEnTime()
    -- 最后登陆时间
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "lastEnTime")
end

function dbuser:setstatu(v)
    -- 状态
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "statu", v)
end
function dbuser:getstatu()
    -- 状态
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "statu")
end

-- 把数据flush到mysql里， immd=true 立即生效
function dbuser:flush(immd)
    skynet.call("CLDB", "lua", "flush", self.__name__, self.__key__, immd)
end

function dbuser:release()
    skynet.call("CLDB", "lua", "SETTIMEOUT", self.__name__, self.__key__)
end

function dbuser.querySql(uid, password)
    return "SELECT * FROM user WHERE " .. "`uid`=" .. (uid and "'" .. uid .."'" or "") .. " AND " .. "`password`=" .. (password and "'" .. password .."'" or "") .. ";"
end

function dbuser.instanse(uid, password)
    local key = uid .. "_" .. password
    if key == "" then
        error("the key is null", 0)
    end
    ---@type dbuser
    local obj = dbuser.new()
    local d = skynet.call("CLDB", "lua", "get", dbuser.name, key)
    if d == nil then
        d = skynet.call("CLMySQL", "lua", "exesql", dbuser.querySql(uid,password))
        if d and #d > 0 then
            if #d == 1 then
                d = d[1]
            else
                error("get data is more than one! count==" .. #d .. ", lua==dbuser")
            end
            -- 取得mysql表里的数据
            obj:init(d)
            obj.__isNew__ = false
            skynet.call("CLDB", "lua", "set", dbuser.name, key, d)
        else
            -- 没有数据
            obj.__isNew__ = true
        end
    else
        obj:init(d)
        obj.__isNew__ = false
        skynet.call("CLDB", "lua", "removetimeout", dbuser.name, key)
    end
    return obj
end

------------------------------------
return dbuser
