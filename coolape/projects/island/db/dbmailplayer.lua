--[[
使用时特别注意：
1、常用方法如下，在不知道表里有没有数据时可以采用如下方法（可能会查询一次表）
    local obj＝ dbmailplayer.instanse(pidx, midx);
    if obj:isEmpty() then
        -- 没有数据
    else
        -- 有数据
    end
2、使用如下用法时，程序会自动判断是否是insert还是update
    local obj＝ dbmailplayer.new(data);
3、使用如下用法时，程序会自动判断是否是insert还是update
    local obj＝ dbmailplayer.new();
    obj:init(data);
]]

require("class")
local skynet = require "skynet"
local tonumber = tonumber
require("dateEx")

-- 邮件与用户的关系表
---@class dbmailplayer : ClassBase
dbmailplayer = class("dbmailplayer")

dbmailplayer.name = "mailplayer"

dbmailplayer.keys = {
    pidx = "pidx", -- 玩家唯一标识
    midx = "midx", -- 邮件唯一标识
    state = "state", -- 状态，0：未读，1：已读&未领奖，2：已读&已领奖
}

function dbmailplayer:ctor(v)
    self.__name__ = "mailplayer"    -- 表名
    self.__isNew__ = nil -- false:说明mysql里已经有数据了
    if v then
        self:init(v)
    end
end

function dbmailplayer:init(data, isNew)
    data = dbmailplayer.validData(data)
    self.__key__ = data.pidx .. "_" .. data.midx
    local hadCacheData = false
    if self.__isNew__ == nil and isNew == nil then
        local d = skynet.call("CLDB", "lua", "get", dbmailplayer.name, self.__key__)
        if d == nil then
            d = skynet.call("CLMySQL", "lua", "exesql", dbmailplayer.querySql(data.pidx, data.midx))
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

function dbmailplayer:tablename() -- 取得表名
    return self.__name__
end

function dbmailplayer:value2copy()  -- 取得数据复样，注意是只读的数据且只有当前时刻是最新的，如果要取得最新数据及修改数据，请用get、set
    local ret = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__)
    if ret then
    end
    return ret
end

function dbmailplayer:refreshData(data)
    if data == nil or self.__key__ == nil then
        skynet.error("dbmailplayer:refreshData error!")
        return
    end
    local orgData = self:value2copy()
    if orgData == nil then
        skynet.error("get old data error!!")
    end
    for k, v in pairs(data) do
        orgData[k] = v
    end
    orgData = dbmailplayer.validData(orgData)
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, orgData)
end

function dbmailplayer:set_pidx(v)
    -- 玩家唯一标识
    if self:isEmpty() then
        skynet.error("[dbmailplayer:set_pidx],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "pidx", v)
end
function dbmailplayer:get_pidx()
    -- 玩家唯一标识
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "pidx")
    return (tonumber(val) or 0)
end

function dbmailplayer:set_midx(v)
    -- 邮件唯一标识
    if self:isEmpty() then
        skynet.error("[dbmailplayer:set_midx],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "midx", v)
end
function dbmailplayer:get_midx()
    -- 邮件唯一标识
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "midx")
    return (tonumber(val) or 0)
end

function dbmailplayer:set_state(v)
    -- 状态，0：未读，1：已读&未领奖，2：已读&已领奖
    if self:isEmpty() then
        skynet.error("[dbmailplayer:set_state],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "state", v)
end
function dbmailplayer:get_state()
    -- 状态，0：未读，1：已读&未领奖，2：已读&已领奖
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "state")
    return (tonumber(val) or 0)
end

-- 把数据flush到mysql里， immd=true 立即生效
function dbmailplayer:flush(immd)
    local sql
    if self.__isNew__ then
        sql = skynet.call("CLDB", "lua", "GETINSERTSQL", self.__name__, self:value2copy())
        return skynet.call("CLMySQL", "lua", "exesql", sql, immd)
    else
        sql = skynet.call("CLDB", "lua", "GETUPDATESQL", self.__name__, self:value2copy())
        return skynet.call("CLMySQL", "lua", "save", sql, immd)
    end
end

function dbmailplayer:isEmpty()
    return (self.__key__ == nil) or (self:get_pidx() == nil) or (self:get_midx() == nil)
end

function dbmailplayer:release(returnVal)
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

function dbmailplayer:delete()
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
function dbmailplayer:setTrigger(server, cmd, fieldKey)
    skynet.call("CLDB", "lua", "ADDTRIGGER", self.__name__, self.__key__, server, cmd, fieldKey)
end

---@param server 触发回调服务地址
---@param cmd 触发回调服务方法
---@param fieldKey 字段key(可为nil)
function dbmailplayer:unsetTrigger(server, cmd, fieldKey)
    skynet.call("CLDB", "lua", "REMOVETRIGGER", self.__name__, self.__key__, server, cmd, fieldKey)
end

function dbmailplayer.querySql(pidx, midx)
    -- 如果某个参数为nil,则where条件中不包括该条件
    local where = {}
    if pidx then
        table.insert(where, "`pidx`=" .. pidx)
    end
    if midx then
        table.insert(where, "`midx`=" .. midx)
    end
    if #where > 0 then
        return "SELECT * FROM mailplayer WHERE " .. table.concat(where, " and ") .. ";"
    else
       return "SELECT * FROM mailplayer;"
    end
end

---@public 取得一个组
---@param forceSelect boolean 强制从mysql取数据
---@param orderby string 排序
function dbmailplayer.getListBypidx(pidx, forceSelect, orderby, limitOffset, limitNum)
    if orderby and orderby ~= "" then
        forceSelect = true
    end
    local data
    local ret = {}
    local cachlist, isFullCached, list
    local groupInfor = skynet.call("CLDB", "lua", "GETGROUP", dbmailplayer.name, pidx) or {}
    cachlist = groupInfor[1] or {}
    isFullCached = groupInfor[2]
    if isFullCached == true and (not forceSelect) then
        list = cachlist
        for k, v in pairs(list) do
            data = dbmailplayer.new(v, false)
            table.insert(ret, data:value2copy())
            data:release()
        end
    else
        local sql = "SELECT * FROM mailplayer WHERE pidx=" .. pidx ..  (orderby and " ORDER BY" ..  orderby or "") .. ((limitOffset and limitNum) and (" LIMIT " ..  limitOffset .. "," .. limitNum) or "") .. ";"
        list = skynet.call("CLMySQL", "lua", "exesql", sql)
        if list and list.errno then
            skynet.error("[dbmailplayer.getGroup] sql error==" .. sql)
            return nil
         end
         for i, v in ipairs(list) do
             local key = tostring(v.pidx .. "_" .. v.midx)
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
             data = dbmailplayer.new(v, false)
             ret[k] = data:value2copy()
             data:release()
         end
     end
     list = nil
     -- 设置当前缓存数据是全的数据
     skynet.call("CLDB", "lua", "SETGROUPISFULL", dbmailplayer.name, pidx)
     return ret
end

function dbmailplayer.validData(data)
    if data == nil then return nil end

    if type(data.pidx) ~= "number" then
        data.pidx = tonumber(data.pidx) or 0
    end
    if type(data.midx) ~= "number" then
        data.midx = tonumber(data.midx) or 0
    end
    if type(data.state) ~= "number" then
        data.state = tonumber(data.state) or 0
    end
    return data
end

function dbmailplayer.instanse(pidx, midx)
    if type(pidx) == "table" then
        local d = pidx
        pidx = d.pidx
        midx = d.midx
    end
    if pidx == nil and midx == nil then
        skynet.error("[dbmailplayer.instanse] all input params == nil")
        return nil
    end
    local key = (pidx or "") .. "_" .. (midx or "")
    if key == "" then
        error("the key is null", 0)
    end
    ---@type dbmailplayer
    local obj = dbmailplayer.new()
    local d = skynet.call("CLDB", "lua", "get", dbmailplayer.name, key)
    if d == nil then
        d = skynet.call("CLMySQL", "lua", "exesql", dbmailplayer.querySql(pidx, midx))
        if d and d.errno == nil and #d > 0 then
            if #d == 1 then
                d = d[1]
                -- 取得mysql表里的数据
                obj.__isNew__ = false
                obj.__key__ = key
                obj:init(d)
            else
                error("get data is more than one! count==" .. #d .. ", lua==dbmailplayer")
            end
        else
            -- 没有数据
            obj.__isNew__ = true
        end
    else
        obj.__isNew__ = false
        obj.__key__ = key
        skynet.call("CLDB", "lua", "SETUSE", dbmailplayer.name, key)
    end
    return obj
end

------------------------------------
return dbmailplayer
