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
    self.__key__ = data.uid
    if self.__isNew__ then
        -- 说明之前表里没有数据，先入库
        local sql = skynet.call("CLDB", "lua", "GETINSERTSQL", self.__name__, data)
        local r = skynet.call("CLMySQL", "lua", "exesql", sql)
        if r == nil or r.errno == nil then
            self.__isNew__ = false
        else
            return false
        end
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, data)
    skynet.call("CLDB", "lua", "REMOVETIMEOUT", self.__name__, self.__key__)
    return true
end

function dbuser:tablename() -- 取得表名
    return self.__name__
end

function dbuser:value2copy()  -- 取得数据复样，注意是只读的数据且只有当前时刻是最新的，如果要取得最新数据及修改数据，请用get、set
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__)
end

function dbuser:setidx(v)
    -- 唯一标识
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "idx", v)
end
function dbuser:getidx()
    -- 唯一标识
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "idx")
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

function dbuser:setstatus(v)
    -- 状态 0:正常;
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "status", v)
end
function dbuser:getstatus()
    -- 状态 0:正常;
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "status")
end

function dbuser:setappid(v)
    -- 应用id
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "appid", v)
end
function dbuser:getappid()
    -- 应用id
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "appid")
end

function dbuser:setchannel(v)
    -- 渠道
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "channel", v)
end
function dbuser:getchannel()
    -- 渠道
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "channel")
end

function dbuser:setdeviceid(v)
    -- 机器id
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "deviceid", v)
end
function dbuser:getdeviceid()
    -- 机器id
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "deviceid")
end

function dbuser:setdeviceinfor(v)
    -- 机器信息
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "deviceinfor", v)
end
function dbuser:getdeviceinfor()
    -- 机器信息
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "deviceinfor")
end

-- 把数据flush到mysql里， immd=true 立即生效
function dbuser:flush(immd)
    local sql
    if self.__isNew__ then
        sql = skynet.call("CLDB", "lua", "GETINSERTSQL", self.__name__, self:value2copy())
    else
        sql = skynet.call("CLDB", "lua", "GETUPDATESQL", self.__name__, self:value2copy())
    end
    return skynet.call("CLMySql", "lua", "save", sql, immd)
end

function dbuser:release()
    skynet.call("CLDB", "lua", "SETTIMEOUT", self.__name__, self.__key__)
end

function dbuser.querySql(uid)
    return "SELECT * FROM user WHERE " .. "`uid`=" .. (uid and "'" .. uid .."'" or "") .. ";"
end

function dbuser.instanse(uid)
    if uid == nil then
        skynet.error("[dbuser.instanse] uid == nil")
        return nil
    end
    local key = uid
    if key == "" then
        error("the key is null", 0)
    end
    ---@type dbuser
    local obj = dbuser.new()
    obj.__key__ = key
    local d = skynet.call("CLDB", "lua", "get", dbuser.name, key)
    if d == nil then
        d = skynet.call("CLMySQL", "lua", "exesql", dbuser.querySql(uid))
        if d and d.errno == nil and #d > 0 then
            if #d == 1 then
                d = d[1]
            else
                error("get data is more than one! count==" .. #d .. ", lua==dbuser")
            end
            -- 取得mysql表里的数据
            obj.__isNew__ = false
            obj:init(d)
        else
            -- 没有数据
            obj.__isNew__ = true
        end
    else
        obj.__isNew__ = false
        skynet.call("CLDB", "lua", "REMOVETIMEOUT", dbuser.name, key)
    end
    return obj
end

------------------------------------
return dbuser
