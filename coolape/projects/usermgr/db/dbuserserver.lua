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
require("dateEx")

-- 用户与服务器关系
---@class dbuserserver
dbuserserver = class("dbuserserver")

dbuserserver.name = "userserver"

dbuserserver.keys = {
    sidx = "sidx", -- 服务器id
    uidx = "uidx", -- 用户id
    appid = "appid", -- 应用id
}

function dbuserserver:ctor(v)
    self.__name__ = "userserver"    -- 表名
    self.__isNew__ = nil -- false:说明mysql里已经有数据了
    if v then
        self:init(v)
    end
end

function dbuserserver:init(data, isNew)
    data = dbuserserver.validData(data)
    self.__key__ = data.uidx .. "_" .. data.appid
    local hadCacheData = false
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
            hadCacheData = true
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
    if not hadCacheData then
        skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, data)
    end
    skynet.call("CLDB", "lua", "SETUSE", self.__name__, self.__key__)
    return true
end

function dbuserserver:tablename() -- 取得表名
    return self.__name__
end

function dbuserserver:value2copy()  -- 取得数据复样，注意是只读的数据且只有当前时刻是最新的，如果要取得最新数据及修改数据，请用get、set
    local ret = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__)
    if ret then
    end
    return ret
end

function dbuserserver:refreshData(data)
    if data == nil or self.__key__ == nil then
        skynet.error("dbuserserver:refreshData error!")
        return
    end
    local orgData = self:value2copy()
    if orgData == nil then
        skynet.error("get old data error!!")
    end
    for k, v in pairs(data) do
        orgData[k] = v
    end
    orgData = dbuserserver.validData(orgData)
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, orgData)
end

function dbuserserver:set_sidx(v)
    -- 服务器id
    if self:isEmpty() then
        skynet.error("[dbuserserver:set_sidx],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "sidx", v)
end
function dbuserserver:get_sidx()
    -- 服务器id
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "sidx")
    return (tonumber(val) or 0)
end

function dbuserserver:set_uidx(v)
    -- 用户id
    if self:isEmpty() then
        skynet.error("[dbuserserver:set_uidx],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "uidx", v)
end
function dbuserserver:get_uidx()
    -- 用户id
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "uidx")
    return (tonumber(val) or 0)
end

function dbuserserver:set_appid(v)
    -- 应用id
    if self:isEmpty() then
        skynet.error("[dbuserserver:set_appid],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "appid", v)
end
function dbuserserver:get_appid()
    -- 应用id
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "appid")
    return (tonumber(val) or 0)
end

-- 把数据flush到mysql里， immd=true 立即生效
function dbuserserver:flush(immd)
    local sql
    if self.__isNew__ then
        sql = skynet.call("CLDB", "lua", "GETINSERTSQL", self.__name__, self:value2copy())
    else
        sql = skynet.call("CLDB", "lua", "GETUPDATESQL", self.__name__, self:value2copy())
    end
    return skynet.call("CLMySQL", "lua", "save", sql, immd)
end

function dbuserserver:isEmpty()
    return (self.__key__ == nil) or (self:get_uidx() == nil) or (self:get_appid() == nil)
end

function dbuserserver:release()
    skynet.call("CLDB", "lua", "SETUNUSE", self.__name__, self.__key__)
    self.__isNew__ = nil
    self.__key__ = nil
end

function dbuserserver:delete()
    local d = self:value2copy()
    skynet.call("CLDB", "lua", "SETUNUSE", self.__name__, self.__key__)
    skynet.call("CLDB", "lua", "REMOVE", self.__name__, self.__key__)
    local sql = skynet.call("CLDB", "lua", "GETDELETESQL", self.__name__, d)
    return skynet.call("CLMySQL", "lua", "EXESQL", sql)
end

---@public 设置触发器（当有数据改变时回调）
---@param server 触发回调服务地址
---@param cmd 触发回调服务方法
---@param fieldKey 字段key(可为nil)
function dbuserserver:setTrigger(server, cmd, fieldKey)
    skynet.call("CLDB", "lua", "ADDTRIGGER", self.__name__, self.__key__, server, cmd, fieldKey)
end

---@param server 触发回调服务地址
---@param cmd 触发回调服务方法
---@param fieldKey 字段key(可为nil)
function dbuserserver:unsetTrigger(server, cmd, fieldKey)
    skynet.call("CLDB", "lua", "REMOVETRIGGER", self.__name__, self.__key__, server, cmd, fieldKey)
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

function dbuserserver.validData(data)
    if data == nil then return nil end

    if type(data.sidx) ~= "number" then
        data.sidx = tonumber(data.sidx) or 0
    end
    if type(data.uidx) ~= "number" then
        data.uidx = tonumber(data.uidx) or 0
    end
    if type(data.appid) ~= "number" then
        data.appid = tonumber(data.appid) or 0
    end
    return data
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
    local d = skynet.call("CLDB", "lua", "get", dbuserserver.name, key)
    if d == nil then
        d = skynet.call("CLMySQL", "lua", "exesql", dbuserserver.querySql(uidx, appid))
        if d and d.errno == nil and #d > 0 then
            if #d == 1 then
                d = d[1]
                -- 取得mysql表里的数据
                obj.__isNew__ = false
                obj.__key__ = key
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
        obj.__key__ = key
        skynet.call("CLDB", "lua", "SETUSE", dbuserserver.name, key)
    end
    return obj
end

------------------------------------
return dbuserserver
