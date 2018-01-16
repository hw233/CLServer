require("class")
local skynet = require "skynet"

-- 服务器列表
dbservers = class("dbservers")

dbservers.name = "servers"

function dbservers:ctor(v)
    self.__name__ = "servers"    -- 表名
    self.__isNew__ = true    -- 新建数据，说明mysql表里没有数据
    self.__key__ = nil --- 缓存数据的key
end

function dbservers:init(data)
    self.__key__ = data.idx .. "_" .. data.appid
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

function dbservers:tablename() -- 取得表名
    return self.__name__
end

function dbservers:value2copy()  -- 取得数据复样，注意是只读的数据且只有当前时刻是最新的，如果要取得最新数据及修改数据，请用get、set
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__)
end

function dbservers:setidx(v)
    -- 唯一标识
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "idx", v)
end
function dbservers:getidx()
    -- 唯一标识
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "idx")
end

function dbservers:setappid(v)
    -- 应用id
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "appid", v)
end
function dbservers:getappid()
    -- 应用id
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "appid")
end

function dbservers:setname(v)
    -- 服务器名
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "name", v)
end
function dbservers:getname()
    -- 服务器名
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "name")
end

function dbservers:setstatus(v)
    -- 状态 0:正常; 1:爆满; 2:维护
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "status", v)
end
function dbservers:getstatus()
    -- 状态 0:正常; 1:爆满; 2:维护
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "status")
end

-- 把数据flush到mysql里， immd=true 立即生效
function dbservers:flush(immd)
    local sql
    if self.__isNew__ then
        sql = skynet.call("CLDB", "lua", "GETINSERTSQL", self.__name__, self:value2copy())
    else
        sql = skynet.call("CLDB", "lua", "GETUPDATESQL", self.__name__, self:value2copy())
    end
    return skynet.call("CLMySql", "lua", "save", sql, immd)
end

function dbservers:release()
    skynet.call("CLDB", "lua", "SETTIMEOUT", self.__name__, self.__key__)
end

function dbservers.querySql(idx, appid)
    return "SELECT * FROM servers WHERE " .. "`idx`=" .. (idx and idx or 0) .. " AND " .. "`appid`=" .. (appid and appid or 0) .. ";"
end

function dbservers.instanse(idx, appid)
    if idx == nil then
        skynet.error("[dbuser.instanse] idx == nil")
        return nil
    end
    if appid == nil then
        skynet.error("[dbuser.instanse] appid == nil")
        return nil
    end
    local key = idx .. "_" .. appid
    if key == "" then
        error("the key is null", 0)
    end
    ---@type dbservers
    local obj = dbservers.new()
    obj.__key__ = key
    local d = skynet.call("CLDB", "lua", "get", dbservers.name, key)
    if d == nil then
        d = skynet.call("CLMySQL", "lua", "exesql", dbservers.querySql(idx,appid))
        if d and d.errno == nil and #d > 0 then
            if #d == 1 then
                d = d[1]
            else
                error("get data is more than one! count==" .. #d .. ", lua==dbservers")
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
        skynet.call("CLDB", "lua", "REMOVETIMEOUT", dbservers.name, key)
    end
    return obj
end

------------------------------------
return dbservers
