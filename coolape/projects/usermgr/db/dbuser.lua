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
require("dateEx")

-- 用户表
---@class dbuser : ClassBase
dbuser = class("dbuser")

dbuser.name = "user"

dbuser.keys = {
    idx = "idx", -- 唯一标识
    uidChl = "uidChl", -- 用户id(第三方渠道用户)
    uid = "uid", -- 用户id
    password = "password", -- 用户密码
    crtTime = "crtTime", -- 创建时间
    lastEnTime = "lastEnTime", -- 最后登陆时间
    status = "status", -- 状态 0:正常;
    email = "email", -- 邮箱
    appid = "appid", -- 应用id
    channel = "channel", -- 渠道
    deviceid = "deviceid", -- 机器id
    deviceinfor = "deviceinfor", -- 机器信息
    groupid = "groupid", -- 组id
}

function dbuser:ctor(v)
    self.__name__ = "user"    -- 表名
    self.__isNew__ = nil -- false:说明mysql里已经有数据了
    if v then
        self:init(v)
    end
end

function dbuser:init(data, isNew)
    data = dbuser.validData(data)
    self.__key__ = data.uid .. "_" .. data.uidChl
    local hadCacheData = false
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
            hadCacheData = true
            self.__isNew__ = false
        end
    elseif isNew ~= nil then
        self.__isNew__ = isNew
    end
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
    if not hadCacheData then
        skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, data)
    end
    skynet.call("CLDB", "lua", "SETUSE", self.__name__, self.__key__)
    return true
end

function dbuser:getInsertSql()
    if self:isEmpty() then
        return nil
    end
    local sql = skynet.call("CLDB", "lua", "GETINSERTSQL", self.__name__, self:value2copy())
    return sql
end
function dbuser:tablename() -- 取得表名
    return self.__name__
end

function dbuser:value2copy()  -- 取得数据复样，注意是只读的数据且只有当前时刻是最新的，如果要取得最新数据及修改数据，请用get、set
    local ret = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__)
    if ret then
        ret.crtTime = self:get_crtTime()
        ret.lastEnTime = self:get_lastEnTime()
    end
    return ret
end

function dbuser:refreshData(data)
    if data == nil or self.__key__ == nil then
        skynet.error("dbuser:refreshData error!")
        return
    end
    local orgData = self:value2copy()
    if orgData == nil then
        skynet.error("get old data error!!")
    end
    for k, v in pairs(data) do
        orgData[k] = v
    end
    orgData = dbuser.validData(orgData)
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, orgData)
end

function dbuser:set_idx(v)
    -- 唯一标识
    if self:isEmpty() then
        skynet.error("[dbuser:set_idx],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "idx", v)
end
function dbuser:get_idx()
    -- 唯一标识
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "idx")
    return (tonumber(val) or 0)
end

function dbuser:set_uidChl(v)
    -- 用户id(第三方渠道用户)
    if self:isEmpty() then
        skynet.error("[dbuser:set_uidChl],please init first!!")
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
        skynet.error("[dbuser:set_uid],please init first!!")
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
        skynet.error("[dbuser:set_password],please init first!!")
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
        skynet.error("[dbuser:set_crtTime],please init first!!")
        return nil
    end
    if type(v) == "number" then
        v = dateEx.seconds2Str(v/1000)
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "crtTime", v)
end
function dbuser:get_crtTime()
    -- 创建时间
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "crtTime")
    if type(val) == "string" then
        return dateEx.str2Seconds(val)*1000 -- 转成毫秒
    else
        return val
    end
end

function dbuser:set_lastEnTime(v)
    -- 最后登陆时间
    if self:isEmpty() then
        skynet.error("[dbuser:set_lastEnTime],please init first!!")
        return nil
    end
    if type(v) == "number" then
        v = dateEx.seconds2Str(v/1000)
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "lastEnTime", v)
end
function dbuser:get_lastEnTime()
    -- 最后登陆时间
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "lastEnTime")
    if type(val) == "string" then
        return dateEx.str2Seconds(val)*1000 -- 转成毫秒
    else
        return val
    end
end

function dbuser:set_status(v)
    -- 状态 0:正常;
    if self:isEmpty() then
        skynet.error("[dbuser:set_status],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "status", v)
end
function dbuser:get_status()
    -- 状态 0:正常;
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "status")
    return (tonumber(val) or 0)
end

function dbuser:set_email(v)
    -- 邮箱
    if self:isEmpty() then
        skynet.error("[dbuser:set_email],please init first!!")
        return nil
    end
    v = v or ""
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "email", v)
end
function dbuser:get_email()
    -- 邮箱
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "email")
end

function dbuser:set_appid(v)
    -- 应用id
    if self:isEmpty() then
        skynet.error("[dbuser:set_appid],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "appid", v)
end
function dbuser:get_appid()
    -- 应用id
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "appid")
    return (tonumber(val) or 0)
end

function dbuser:set_channel(v)
    -- 渠道
    if self:isEmpty() then
        skynet.error("[dbuser:set_channel],please init first!!")
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
        skynet.error("[dbuser:set_deviceid],please init first!!")
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
        skynet.error("[dbuser:set_deviceinfor],please init first!!")
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
        skynet.error("[dbuser:set_groupid],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "groupid", v)
end
function dbuser:get_groupid()
    -- 组id
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "groupid")
    return (tonumber(val) or 0)
end

-- 把数据flush到mysql里， immd=true 立即生效
function dbuser:flush(immd)
    local sql
    if self.__isNew__ then
        sql = skynet.call("CLDB", "lua", "GETINSERTSQL", self.__name__, self:value2copy())
        return skynet.call("CLMySQL", "lua", "exesql", sql, immd)
    else
        sql = skynet.call("CLDB", "lua", "GETUPDATESQL", self.__name__, self:value2copy())
        return skynet.call("CLMySQL", "lua", "save", sql, immd)
    end
end

function dbuser:isEmpty()
    return (self.__key__ == nil) or (self:get_uid() == nil) or (self:get_uidChl() == nil)
end

function dbuser:release(returnVal)
    local val = nil
    if returnVal then
        val = self:value2copy()
    end
    skynet.call("CLDB", "lua", "SETUNUSE", self.__name__, self.__key__)
    self.__isNew__ = nil
    self.__key__ = nil
    self = nil
    return val
end

function dbuser:delete()
    local d = self:value2copy()
    skynet.call("CLDB", "lua", "SETUNUSE", self.__name__, self.__key__)
    skynet.call("CLDB", "lua", "REMOVE", self.__name__, self.__key__)
    local sql = skynet.call("CLDB", "lua", "GETDELETESQL", self.__name__, d)
    self.__key__ = nil
    return skynet.call("CLMySQL", "lua", "exesql", sql)
end

---@public 设置触发器（当有数据改变时回调）
---@param server 触发回调服务地址
---@param cmd 触发回调服务方法
---@param fieldKey 字段key(可为nil)
function dbuser:setTrigger(server, cmd, fieldKey)
    skynet.call("CLDB", "lua", "ADDTRIGGER", self.__name__, self.__key__, server, cmd, fieldKey)
end

---@param server 触发回调服务地址
---@param cmd 触发回调服务方法
---@param fieldKey 字段key(可为nil)
function dbuser:unsetTrigger(server, cmd, fieldKey)
    skynet.call("CLDB", "lua", "REMOVETRIGGER", self.__name__, self.__key__, server, cmd, fieldKey)
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

---@public 取得一个组
---@param forceSelect boolean 强制从mysql取数据
---@param orderby string 排序
function dbuser.getListBydeviceid(deviceid, forceSelect, orderby, limitOffset, limitNum)
    if orderby and orderby ~= "" then
        forceSelect = true
    end
    local data
    local ret = {}
    local cachlist, isFullCached, list
    local groupInfor = skynet.call("CLDB", "lua", "GETGROUP", dbuser.name, deviceid) or {}
    cachlist = groupInfor[1] or {}
    isFullCached = groupInfor[2]
    if isFullCached == true and (not forceSelect) then
        list = cachlist
        for k, v in pairs(list) do
            data = dbuser.new(v, false)
            table.insert(ret, data:value2copy())
            data:release()
        end
    else
        local sql = "SELECT * FROM user WHERE deviceid=" .. "'" .. deviceid .. "'" ..  (orderby and " ORDER BY" ..  orderby or "") .. ((limitOffset and limitNum) and (" LIMIT " ..  limitOffset .. "," .. limitNum) or "") .. ";"
        list = skynet.call("CLMySQL", "lua", "exesql", sql)
        if list and list.errno then
            skynet.error("[dbuser.getGroup] sql error==" .. sql)
            return nil
         end
         for i, v in ipairs(list) do
             local key = tostring(v.uid .. "_" .. v.uidChl)
             local d = cachlist[key]
             if d ~= nil then
                 -- 用缓存的数据才是最新的
                 list[i] = d
                 cachlist[key] = nil
             end
         end
         for k ,v in pairs(cachlist) do
             table.insert(list, v)
         end
         cachlist = nil
         for k, v in ipairs(list) do
             data = dbuser.new(v, false)
             ret[k] = data:value2copy()
             data:release()
         end
     end
     list = nil
     -- 设置当前缓存数据是全的数据
     skynet.call("CLDB", "lua", "SETGROUPISFULL", dbuser.name, deviceid)
     return ret
end

---@public 取得一个组
---@param forceSelect boolean 强制从mysql取数据
---@param orderby string 排序
function dbuser.getListBychannel_groupid(channel, groupid, forceSelect, orderby, limitOffset, limitNum)
    if orderby and orderby ~= "" then
        forceSelect = true
    end
    local data
    local ret = {}
    local cachlist, isFullCached, list
    local groupInfor = skynet.call("CLDB", "lua", "GETGROUP", dbuser.name, channel .. "_" .. groupid) or {}
    cachlist = groupInfor[1] or {}
    isFullCached = groupInfor[2]
    if isFullCached == true and (not forceSelect) then
        list = cachlist
        for k, v in pairs(list) do
            data = dbuser.new(v, false)
            table.insert(ret, data:value2copy())
            data:release()
        end
    else
        local sql = "SELECT * FROM user WHERE channel=" .. "'" .. channel .. "'" .. " AND groupid=" .. groupid ..  (orderby and " ORDER BY" ..  orderby or "") .. ((limitOffset and limitNum) and (" LIMIT " ..  limitOffset .. "," .. limitNum) or "") .. ";"
        list = skynet.call("CLMySQL", "lua", "exesql", sql)
        if list and list.errno then
            skynet.error("[dbuser.getGroup] sql error==" .. sql)
            return nil
         end
         for i, v in ipairs(list) do
             local key = tostring(v.uid .. "_" .. v.uidChl)
             local d = cachlist[key]
             if d ~= nil then
                 -- 用缓存的数据才是最新的
                 list[i] = d
                 cachlist[key] = nil
             end
         end
         for k ,v in pairs(cachlist) do
             table.insert(list, v)
         end
         cachlist = nil
         for k, v in ipairs(list) do
             data = dbuser.new(v, false)
             ret[k] = data:value2copy()
             data:release()
         end
     end
     list = nil
     -- 设置当前缓存数据是全的数据
     skynet.call("CLDB", "lua", "SETGROUPISFULL", dbuser.name, channel .. "_" .. groupid)
     return ret
end

function dbuser.validData(data)
    if data == nil then return nil end

    if type(data.idx) ~= "number" then
        data.idx = tonumber(data.idx) or 0
    end
    if type(data.crtTime) == "number" then
        data.crtTime = dateEx.seconds2Str(data.crtTime/1000)
    end
    if type(data.lastEnTime) == "number" then
        data.lastEnTime = dateEx.seconds2Str(data.lastEnTime/1000)
    end
    if type(data.status) ~= "number" then
        data.status = tonumber(data.status) or 0
    end
    if type(data.appid) ~= "number" then
        data.appid = tonumber(data.appid) or 0
    end
    if type(data.groupid) ~= "number" then
        data.groupid = tonumber(data.groupid) or 0
    end
    return data
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
    local d = skynet.call("CLDB", "lua", "get", dbuser.name, key)
    if d == nil then
        d = skynet.call("CLMySQL", "lua", "exesql", dbuser.querySql(nil, uid, uidChl))
        if d and d.errno == nil and #d > 0 then
            if #d == 1 then
                d = d[1]
                -- 取得mysql表里的数据
                obj.__isNew__ = false
                obj.__key__ = key
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
        obj.__key__ = key
        skynet.call("CLDB", "lua", "SETUSE", dbuser.name, key)
    end
    return obj
end

------------------------------------
return dbuser
