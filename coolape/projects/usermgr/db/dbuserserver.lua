require("class")
local skynet = require "skynet"

-- 用户与服务器关系
dbuserserver = class("dbuserserver")

dbuserserver.name = "userserver"

function dbuserserver:ctor(v)
    self.__name__ = "userserver"    -- 表名
    self.__isNew__ = true    -- 新建数据，说明mysql表里没有数据
    self.__key__ = nil -- 缓存数据的key
end

function dbuserserver:init(data)
    self.__key__ = data.uidx .. "_" .. data.appid
    if self.__isNew__ then
        -- 说明之前表里没有数据，先入库
        local sql = skynet.call("CLDB", "lua", "GETINSERTSQL", self.__name__, data)
        local r = skynet.call("CLMySQL", "lua", "save", sql)
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

function dbuserserver:tablename() -- 取得表名
    return self.__name__
end

function dbuserserver:value2copy()  -- 取得数据复样，注意是只读的数据且只有当前时刻是最新的，如果要取得最新数据及修改数据，请用get、set
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__)
end

function dbuserserver:setsidx(v)
    -- 服务器id
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "sidx", v)
end
function dbuserserver:getsidx()
    -- 服务器id
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "sidx")
end

function dbuserserver:setuidx(v)
    -- 用户id
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "uidx", v)
end
function dbuserserver:getuidx()
    -- 用户id
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "uidx")
end

function dbuserserver:setappid(v)
    -- 应用id
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "appid", v)
end
function dbuserserver:getappid()
    -- 应用id
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "appid")
end

-- 把数据flush到mysql里， immd=true 立即生效
function dbuserserver:flush(immd)
    local sql
    if self.__isNew__ then
        sql = skynet.call("CLDB", "lua", "GETINSERTSQL", self.__name__, self:value2copy())
    else
        sql = skynet.call("CLDB", "lua", "GETUPDATESQL", self.__name__, self:value2copy())
    end
    return skynet.call("CLMySql", "lua", "save", sql, immd)
end

function dbuserserver:release()
    skynet.call("CLDB", "lua", "SETTIMEOUT", self.__name__, self.__key__)
end

function dbuserserver.querySql(uidx, appid)
    -- 如果某个参数为nil,则where条件中不包括该条件
    local where = {}
    if uidx then
        table.insert(where, "`uidx`=" .. "'" .. uidx  .. "'")
    end
    if appid then
        table.insert(where, "`appid`=" .. "'" .. appid  .. "'")
    end
    if #where > 0 then
        return "SELECT * FROM userserver WHERE " .. table.concat(where, " and ") .. ";"
    else
       return "SELECT * FROM userserver;"
    end
end

function dbuserserver.instanse(uidx, appid)
    if uidx == nil then
        skynet.error("[dbuserserver.instanse] uidx == nil")
        return nil
    end
    if appid == nil then
        skynet.error("[dbuserserver.instanse] appid == nil")
        return nil
    end
    local key = uidx .. "_" .. appid
    if key == "" then
        error("the key is null", 0)
    end
    ---@type dbuserserver
    local obj = dbuserserver.new()
    obj.__key__ = key
    local d = skynet.call("CLDB", "lua", "get", dbuserserver.name, key)
    if d == nil then
        d = skynet.call("CLMySQL", "lua", "exesql", dbuserserver.querySql(uidx, appid))
        if d and d.errno == nil and #d > 0 then
            if #d == 1 then
                d = d[1]
                -- 取得mysql表里的数据
                obj.__isNew__ = false
                obj:init(d)
            else
                error("get data is more than one! count==" .. #d .. ", lua==dbuserserver")
            end
        else
            -- 没有数据
            obj.__isNew__ = true
        end
    else
        obj.__isNew__ = false
        skynet.call("CLDB", "lua", "REMOVETIMEOUT", dbuserserver.name, key)
    end
    return obj
end

------------------------------------
return dbuserserver
