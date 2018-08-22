--[[
使用时特别注意：
1、常用方法如下，在不知道表里有没有数据时可以采用如下方法（可能会查询一次表）
    local obj＝ dbuser.instanse(uid, uidChl);
    if obj:isEmpty() then
        -- 没有数据
    else
        -- 有数据
    end
2、使用如下用法时，程序会自动判断是否是insert还是update
    local obj＝ dbuser.new(data);
3、使用如下用法时，程序会自动判断是否是insert还是update
    local obj＝ dbuser.new();
    obj:init(data);
]]

require("class")
local skynet = require "skynet"
local tonumber = tonumber

-- 用户表
---@class dbuser
dbuser = class("dbuser")

dbuser.name = "user"

function dbuser:ctor(v)
    self.__name__ = "user"    -- 表名
    self.__isNew__ = nil -- false:说明mysql里已经有数据了
    if v then
        self:init(v)
    end
end

function dbuser:init(data, isNew)
    self.__key__ = data.uid .. "_" .. data.uidChl
    if self.__isNew__ == nil and isNew == nil then
        local d = skynet.call("CLDB", "lua", "get", dbuser.name, self.__key__)
        if d == nil then
            d = skynet.call("CLMySQL", "lua", "exesql", dbuser.querySql(nil, data.uid, data.uidChl))
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

function dbuser:tablename() -- 取得表名
    return self.__name__
end

function dbuser:value2copy()  -- 取得数据复样，注意是只读的数据且只有当前时刻是最新的，如果要取得最新数据及修改数据，请用get、set
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__)
end

function dbuser:set_idx(v)
    -- 唯一标识
    if self:isEmpty() then
        skynet.error("[dbuser:setidx],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "idx", v)
end
function dbuser:get_idx()
    -- 唯一标识
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "idx")
end

function dbuser:set_uidChl(v)
    -- 用户id(第三方渠道用户)
    if self:isEmpty() then
        skynet.error("[dbuser:setuidChl],please init first!!")
        return nil
    end
    v = v or ""
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "uidChl", v)
end
function dbuser:get_uidChl()
    -- 用户id(第三方渠道用户)
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "uidChl")
end

function dbuser:set_uid(v)
    -- 用户id
    if self:isEmpty() then
        skynet.error("[dbuser:setuid],please init first!!")
        return nil
    end
    v = v or ""
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "uid", v)
end
function dbuser:get_uid()
    -- 用户id
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "uid")
end

function dbuser:set_password(v)
    -- 用户密码
    if self:isEmpty() then
        skynet.error("[dbuser:setpassword],please init first!!")
        return nil
    end
    v = v or ""
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "password", v)
end
function dbuser:get_password()
    -- 用户密码
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "password")
end

function dbuser:set_crtTime(v)
    -- 创建时间
    if self:isEmpty() then
        skynet.error("[dbuser:setcrtTime],please init first!!")
        return nil
    end
    v = v or ""
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "crtTime", v)
end
function dbuser:get_crtTime()
    -- 创建时间
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "crtTime")
end

function dbuser:set_lastEnTime(v)
    -- 最后登陆时间
    if self:isEmpty() then
        skynet.error("[dbuser:setlastEnTime],please init first!!")
        return nil
    end
    v = v or ""
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "lastEnTime", v)
end
function dbuser:get_lastEnTime()
    -- 最后登陆时间
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "lastEnTime")
end

function dbuser:set_status(v)
    -- 状态 0:正常;
    if self:isEmpty() then
        skynet.error("[dbuser:setstatus],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "status", v)
end
function dbuser:get_status()
    -- 状态 0:正常;
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "status")
end

function dbuser:set_appid(v)
    -- 应用id
    if self:isEmpty() then
        skynet.error("[dbuser:setappid],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "appid", v)
end
function dbuser:get_appid()
    -- 应用id
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "appid")
end

function dbuser:set_channel(v)
    -- 渠道
    if self:isEmpty() then
        skynet.error("[dbuser:setchannel],please init first!!")
        return nil
    end
    v = v or ""
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "channel", v)
end
function dbuser:get_channel()
    -- 渠道
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "channel")
end

function dbuser:set_deviceid(v)
    -- 机器id
    if self:isEmpty() then
        skynet.error("[dbuser:setdeviceid],please init first!!")
        return nil
    end
    v = v or ""
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "deviceid", v)
end
function dbuser:get_deviceid()
    -- 机器id
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "deviceid")
end

function dbuser:set_deviceinfor(v)
    -- 机器信息
    if self:isEmpty() then
        skynet.error("[dbuser:setdeviceinfor],please init first!!")
        return nil
    end
    v = v or ""
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "deviceinfor", v)
end
function dbuser:get_deviceinfor()
    -- 机器信息
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "deviceinfor")
end

function dbuser:set_groupid(v)
    -- 组id
    if self:isEmpty() then
        skynet.error("[dbuser:setgroupid],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "groupid", v)
end
function dbuser:get_groupid()
    -- 组id
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "groupid")
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

function dbuser:isEmpty()
    return (self.__key__ == nil) or (self:get_uid() == nil) or (self:get_uidChl() == nil)
end

function dbuser:release()
    skynet.call("CLDB", "lua", "SETUNUSE", self.__name__, self.__key__)
    self.__isNew__ = nil
    self.__key__ = nil
end

function dbuser:delete()
    skynet.call("CLDB", "lua", "SETUNUSE", self.__name__, self.__key__)
    skynet.call("CLDB", "lua", "REMOVE", self.__name__, self.__key__)
    local sql = skynet.call("CLDB", "lua", "GETDELETESQL", self.__name__, self:value2copy())
    return skynet.call("CLMySql", "lua", "EXESQL", sql)
end

function dbuser.querySql(idx, uid, uidChl)
    -- 如果某个参数为nil,则where条件中不包括该条件
    local where = {}
    if idx then
        table.insert(where, "`idx`=" .. idx)
    end
    if uid then
        table.insert(where, "`uid`=" .. "'" .. uid  .. "'")
    end
    if uidChl then
        table.insert(where, "`uidChl`=" .. "'" .. uidChl  .. "'")
    end
    if #where > 0 then
        return "SELECT * FROM user WHERE " .. table.concat(where, " and ") .. ";"
    else
       return "SELECT * FROM user;"
    end
end

function dbuser.instanse(uid, uidChl)
    if type(uid) == "table" then
        local d = uid
        uid = d.uid
        uidChl = d.uidChl
    end
    if uid == nil and uidChl == nil then
        skynet.error("[dbuser.instanse] all input params == nil")
        return nil
    end
    local key = (uid or "") .. "_" .. (uidChl or "")
    if key == "" then
        error("the key is null", 0)
    end
    ---@type dbuser
    local obj = dbuser.new()
    obj.__key__ = key
    local d = skynet.call("CLDB", "lua", "get", dbuser.name, key)
    if d == nil then
        d = skynet.call("CLMySQL", "lua", "exesql", dbuser.querySql(nil, uid, uidChl))
        if d and d.errno == nil and #d > 0 then
            if #d == 1 then
                d = d[1]
                -- 取得mysql表里的数据
                obj.__isNew__ = false
                obj:init(d)
            else
                error("get data is more than one! count==" .. #d .. ", lua==dbuser")
            end
        else
            -- 没有数据
            obj.__isNew__ = true
        end
    else
        obj.__isNew__ = false
        skynet.call("CLDB", "lua", "SETUSE", dbuser.name, key)
    end
    return obj
end

------------------------------------
return dbuser
