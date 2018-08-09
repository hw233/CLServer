--[[
使用时特别注意：
1、常用方法如下，在不知道表里有没有数据时可以采用如下方法（可能会查询一次表）
    local obj＝ dbuserserver.instanse(uidx, appid);
    if obj:isEmpty() then
        -- 没有数据
    else
        -- 有数据
    end
2、使用如下用法时，程序会自动判断是否是insert还是update
    local obj＝ dbuserserver.new(data);
3、使用如下用法时，程序会自动判断是否是insert还是update
    local obj＝ dbuserserver.new();
    obj:init(data);
]]

require("class")
local skynet = require "skynet"
local tonumber = tonumber

-- 用户与服务器关系
---@class dbuserserver
dbuserserver = class("dbuserserver")

dbuserserver.name = "userserver"

function dbuserserver:ctor(v)
    self.__name__ = "userserver"    -- 表名
    self.__isNew__ = nil -- false:说明mysql里已经有数据了
    if v then
        self:init(v)
    end
end

function dbuserserver:init(data, isNew)
    self.__key__ = data.uidx .. "_" .. data.appid
    if self.__isNew__ == nil and isNew == nil then
        local d = skynet.call("CLDB", "lua", "get", dbuserserver.name, self.__key__)
        if d == nil then
            d = skynet.call("CLMySQL", "lua", "exesql", dbuserserver.querySql(data.uidx, data.appid))
            if d and d.errno == nil and #d > 0 then
                self.__isNew__ = false
            else
                self.__isNew__ = true
            end
        else
            self.__isNew__ = false
        end
    else
        self.__isNew__ = isNew
    end
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
    skynet.call("CLDB", "lua", "SETUSE", self.__name__, self.__key__)
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
    if self:isEmpty() then
        skynet.error("[dbuserserver:setsidx],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "sidx", v)
end
function dbuserserver:getsidx()
    -- 服务器id
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "sidx")
end

function dbuserserver:setuidx(v)
    -- 用户id
    if self:isEmpty() then
        skynet.error("[dbuserserver:setuidx],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "uidx", v)
end
function dbuserserver:getuidx()
    -- 用户id
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "uidx")
end

function dbuserserver:setappid(v)
    -- 应用id
    if self:isEmpty() then
        skynet.error("[dbuserserver:setappid],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
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

function dbuserserver:isEmpty()
    return (self.__key__ == nil) or (self:getuidx() == nil) or (self:getappid() == nil)
end

function dbuserserver:release()
    skynet.call("CLDB", "lua", "SETUNUSE", self.__name__, self.__key__)
    self.__isNew__ = nil
    self.__key__ = nil
end

function dbuserserver:delete()
    skynet.call("CLDB", "lua", "SETUNUSE", self.__name__, self.__key__)
    skynet.call("CLDB", "lua", "REMOVE", self.__name__, self.__key__)
    local sql = skynet.call("CLDB", "lua", "GETDELETESQL", self.__name__, self:value2copy())
    return skynet.call("CLMySql", "lua", "EXESQL", sql)
end

function dbuserserver.querySql(uidx, appid)
    -- 如果某个参数为nil,则where条件中不包括该条件
    local where = {}
    if uidx then
        table.insert(where, "`uidx`=" .. uidx)
    end
    if appid then
        table.insert(where, "`appid`=" .. appid)
    end
    if #where > 0 then
        return "SELECT * FROM userserver WHERE " .. table.concat(where, " and ") .. ";"
    else
       return "SELECT * FROM userserver;"
    end
end

function dbuserserver.instanse(uidx, appid)
    if type(uidx) == "table" then
        local d = uidx
        uidx = d.uidx
        appid = d.appid
    end
    if uidx == nil and appid == nil then
        skynet.error("[dbuserserver.instanse] all input params == nil")
        return nil
    end
    local key = (uidx or "") .. "_" .. (appid or "")
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
        skynet.call("CLDB", "lua", "SETUSE", dbuserserver.name, key)
    end
    return obj
end

------------------------------------
return dbuserserver
