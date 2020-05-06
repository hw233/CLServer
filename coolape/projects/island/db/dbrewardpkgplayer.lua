--[[
使用时特别注意：
1、常用方法如下，在不知道表里有没有数据时可以采用如下方法（可能会查询一次表）
    local obj＝ dbrewardpkgplayer.instanse(pidx, rwidx);
    if obj:isEmpty() then
        -- 没有数据
    else
        -- 有数据
    end
2、使用如下用法时，程序会自动判断是否是insert还是update
    local obj＝ dbrewardpkgplayer.new(data);
3、使用如下用法时，程序会自动判断是否是insert还是update
    local obj＝ dbrewardpkgplayer.new();
    obj:init(data);
]]

require("class")
local skynet = require "skynet"
local tonumber = tonumber
require("dateEx")

-- 用户的奖励包
---@class dbrewardpkgplayer : ClassBase
dbrewardpkgplayer = class("dbrewardpkgplayer")

dbrewardpkgplayer.name = "rewardpkgplayer"

dbrewardpkgplayer.keys = {
    pidx = "pidx", -- 玩家唯一标识
    rwidx = "rwidx", -- 邮件唯一标识
}

function dbrewardpkgplayer:ctor(v)
    self.__name__ = "rewardpkgplayer"    -- 表名
    self.__isNew__ = nil -- false:说明mysql里已经有数据了
    if v then
        self:init(v)
    end
end

function dbrewardpkgplayer:init(data, isNew)
    data = dbrewardpkgplayer.validData(data)
    self.__key__ = data.pidx .. "_" .. data.rwidx
    local hadCacheData = false
    if self.__isNew__ == nil and isNew == nil then
        local d = skynet.call("CLDB", "lua", "get", dbrewardpkgplayer.name, self.__key__)
        if d == nil then
            d = skynet.call("CLMySQL", "lua", "exesql", dbrewardpkgplayer.querySql(data.pidx, data.rwidx))
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

function dbrewardpkgplayer:getInsertSql()
    if self:isEmpty() then
        return nil
    end
    local data = dbrewardpkgplayer.validData(self:value2copy())
    local sql = skynet.call("CLDB", "lua", "GETINSERTSQL", self.__name__, data)
    return sql
end
function dbrewardpkgplayer:tablename() -- 取得表名
    return self.__name__
end

function dbrewardpkgplayer:value2copy()  -- 取得数据复样，注意是只读的数据且只有当前时刻是最新的，如果要取得最新数据及修改数据，请用get、set
    local ret = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__)
    if ret then
    end
    return ret
end

function dbrewardpkgplayer:refreshData(data)
    if data == nil or self.__key__ == nil then
        skynet.error("dbrewardpkgplayer:refreshData error!")
        return
    end
    local orgData = self:value2copy()
    if orgData == nil then
        skynet.error("get old data error!!")
    end
    for k, v in pairs(data) do
        orgData[k] = v
    end
    orgData = dbrewardpkgplayer.validData(orgData)
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, orgData)
end

function dbrewardpkgplayer:set_pidx(v)
    -- 玩家唯一标识
    if self:isEmpty() then
        skynet.error("[dbrewardpkgplayer:set_pidx],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "pidx", v)
end
function dbrewardpkgplayer:get_pidx()
    -- 玩家唯一标识
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "pidx")
    return (tonumber(val) or 0)
end

function dbrewardpkgplayer:set_rwidx(v)
    -- 邮件唯一标识
    if self:isEmpty() then
        skynet.error("[dbrewardpkgplayer:set_rwidx],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "rwidx", v)
end
function dbrewardpkgplayer:get_rwidx()
    -- 邮件唯一标识
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "rwidx")
    return (tonumber(val) or 0)
end

-- 把数据flush到mysql里， immd=true 立即生效
function dbrewardpkgplayer:flush(immd)
    local sql
    local data = dbrewardpkgplayer.validData(self:value2copy())
    if self.__isNew__ then
        sql = skynet.call("CLDB", "lua", "GETINSERTSQL", self.__name__, data)
        return skynet.call("CLMySQL", "lua", "exesql", sql, immd)
    else
        sql = skynet.call("CLDB", "lua", "GETUPDATESQL", self.__name__, data)
        return skynet.call("CLMySQL", "lua", "save", sql, immd)
    end
end

function dbrewardpkgplayer:isEmpty()
    return (self.__key__ == nil) or (self:get_pidx() == nil) or (self:get_rwidx() == nil)
end

function dbrewardpkgplayer:release(returnVal)
    local val = nil
    if not self:isEmpty() then
        if returnVal then
            val = self:value2copy()
        end
        skynet.call("CLDB", "lua", "SETUNUSE", self.__name__, self.__key__)
    end
    self.__isNew__ = nil
    self.__key__ = nil
    self = nil
    return val
end

function dbrewardpkgplayer:delete()
    local d = self:value2copy()
    skynet.call("CLDB", "lua", "SETUNUSE", self.__name__, self.__key__)
    skynet.call("CLDB", "lua", "REMOVE", self.__name__, self.__key__)
    local sql = skynet.call("CLDB", "lua", "GETDELETESQL", self.__name__, d)
    self.__key__ = nil
    return skynet.call("CLMySQL", "lua", "exesql", sql)
end

---public 设置触发器（当有数据改变时回调）
---@param server 触发回调服务地址
---@param cmd 触发回调服务方法
---@param fieldKey 字段key(可为nil)
function dbrewardpkgplayer:setTrigger(server, cmd, fieldKey)
    skynet.call("CLDB", "lua", "ADDTRIGGER", self.__name__, self.__key__, server, cmd, fieldKey)
end

---@param server 触发回调服务地址
---@param cmd 触发回调服务方法
---@param fieldKey 字段key(可为nil)
function dbrewardpkgplayer:unsetTrigger(server, cmd, fieldKey)
    skynet.call("CLDB", "lua", "REMOVETRIGGER", self.__name__, self.__key__, server, cmd, fieldKey)
end

function dbrewardpkgplayer.querySql(pidx, rwidx)
    -- 如果某个参数为nil,则where条件中不包括该条件
    local where = {}
    if pidx then
        table.insert(where, "`pidx`=" .. pidx)
    end
    if rwidx then
        table.insert(where, "`rwidx`=" .. rwidx)
    end
    if #where > 0 then
        return "SELECT * FROM rewardpkgplayer WHERE " .. table.concat(where, " and ") .. ";"
    else
       return "SELECT * FROM rewardpkgplayer;"
    end
end

---public 取得一个组
---@param forceSelect boolean 强制从mysql取数据
---@param orderby string 排序
function dbrewardpkgplayer.getListBypidx(pidx, forceSelect, orderby, limitOffset, limitNum)
    if orderby and orderby ~= "" then
        forceSelect = true
    end
    local data
    local ret = {}
    local cachlist, isFullCached, list
    local groupKey = "pidx_" .. pidx
    local groupInfor = skynet.call("CLDB", "lua", "GETGROUP", dbrewardpkgplayer.name,  groupKey) or {}
    cachlist = groupInfor[1] or {}
    isFullCached = groupInfor[2]
    if isFullCached == true and (not forceSelect) then
        list = cachlist
        for k, v in pairs(list) do
            data = dbrewardpkgplayer.new(v, false)
            table.insert(ret, data:value2copy())
            data:release()
        end
    else
        local sql = "SELECT * FROM rewardpkgplayer WHERE pidx=" .. pidx ..  (orderby and " ORDER BY" ..  orderby or "") .. ((limitOffset and limitNum) and (" LIMIT " ..  limitOffset .. "," .. limitNum) or "") .. ";"
        list = skynet.call("CLMySQL", "lua", "exesql", sql)
        if list and list.errno then
            skynet.error("[dbrewardpkgplayer.getGroup] sql error==" .. sql)
            return nil
         end
         for i, v in ipairs(list) do
             local key = tostring(v.pidx .. "_" .. v.rwidx)
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
             data = dbrewardpkgplayer.new(v, false)
             ret[k] = data:value2copy()
             data:release()
         end
     end
     list = nil
     -- 设置当前缓存数据是全的数据
     skynet.call("CLDB", "lua", "SETGROUPISFULL", dbrewardpkgplayer.name, groupKey)
     return ret
end

---public 取得一个组
---@param forceSelect boolean 强制从mysql取数据
---@param orderby string 排序
function dbrewardpkgplayer.getListByrwidx(rwidx, forceSelect, orderby, limitOffset, limitNum)
    if orderby and orderby ~= "" then
        forceSelect = true
    end
    local data
    local ret = {}
    local cachlist, isFullCached, list
    local groupKey = "rwidx_" .. rwidx
    local groupInfor = skynet.call("CLDB", "lua", "GETGROUP", dbrewardpkgplayer.name,  groupKey) or {}
    cachlist = groupInfor[1] or {}
    isFullCached = groupInfor[2]
    if isFullCached == true and (not forceSelect) then
        list = cachlist
        for k, v in pairs(list) do
            data = dbrewardpkgplayer.new(v, false)
            table.insert(ret, data:value2copy())
            data:release()
        end
    else
        local sql = "SELECT * FROM rewardpkgplayer WHERE rwidx=" .. rwidx ..  (orderby and " ORDER BY" ..  orderby or "") .. ((limitOffset and limitNum) and (" LIMIT " ..  limitOffset .. "," .. limitNum) or "") .. ";"
        list = skynet.call("CLMySQL", "lua", "exesql", sql)
        if list and list.errno then
            skynet.error("[dbrewardpkgplayer.getGroup] sql error==" .. sql)
            return nil
         end
         for i, v in ipairs(list) do
             local key = tostring(v.pidx .. "_" .. v.rwidx)
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
             data = dbrewardpkgplayer.new(v, false)
             ret[k] = data:value2copy()
             data:release()
         end
     end
     list = nil
     -- 设置当前缓存数据是全的数据
     skynet.call("CLDB", "lua", "SETGROUPISFULL", dbrewardpkgplayer.name, groupKey)
     return ret
end

function dbrewardpkgplayer.validData(data)
    if data == nil then return nil end

    if type(data.pidx) ~= "number" then
        data.pidx = tonumber(data.pidx) or 0
    end
    if type(data.rwidx) ~= "number" then
        data.rwidx = tonumber(data.rwidx) or 0
    end
    return data
end

function dbrewardpkgplayer.instanse(pidx, rwidx)
    if type(pidx) == "table" then
        local d = pidx
        pidx = d.pidx
        rwidx = d.rwidx
    end
    if pidx == nil and rwidx == nil then
        skynet.error("[dbrewardpkgplayer.instanse] all input params == nil")
        return nil
    end
    local key = (pidx or "") .. "_" .. (rwidx or "")
    if key == "" then
        error("the key is null", 0)
    end
    ---@type dbrewardpkgplayer
    local obj = dbrewardpkgplayer.new()
    local d = skynet.call("CLDB", "lua", "get", dbrewardpkgplayer.name, key)
    if d == nil then
        d = skynet.call("CLMySQL", "lua", "exesql", dbrewardpkgplayer.querySql(pidx, rwidx))
        if d and d.errno == nil and #d > 0 then
            if #d == 1 then
                d = d[1]
                -- 取得mysql表里的数据
                obj.__isNew__ = false
                obj.__key__ = key
                obj:init(d)
            else
                error("get data is more than one! count==" .. #d .. ", lua==dbrewardpkgplayer")
            end
        else
            -- 没有数据
            obj.__isNew__ = true
        end
    else
        obj.__isNew__ = false
        obj.__key__ = key
        skynet.call("CLDB", "lua", "SETUSE", dbrewardpkgplayer.name, key)
    end
    return obj
end

------------------------------------
return dbrewardpkgplayer
