--[[
使用时特别注意：
1、常用方法如下，在不知道表里有没有数据时可以采用如下方法（可能会查询一次表）
    local obj＝ dblanguage.instanse(language, ckey);
    if obj:isEmpty() then
        -- 没有数据
    else
        -- 有数据
    end
2、使用如下用法时，程序会自动判断是否是insert还是update
    local obj＝ dblanguage.new(data);
3、使用如下用法时，程序会自动判断是否是insert还是update
    local obj＝ dblanguage.new();
    obj:init(data);
]]

require("class")
local skynet = require "skynet"
local tonumber = tonumber
require("dateEx")

-- 语言表(国际化)
---@class dblanguage : ClassBase
dblanguage = class("dblanguage")

dblanguage.name = "language"

dblanguage.keys = {
    language = "language", -- 语言类别
    ckey = "ckey", -- 内容key
    content = "content", -- 内容
}

function dblanguage:ctor(v)
    self.__name__ = "language"    -- 表名
    self.__isNew__ = nil -- false:说明mysql里已经有数据了
    if v then
        self:init(v)
    end
end

function dblanguage:init(data, isNew)
    data = dblanguage.validData(data)
    self.__key__ = data.language .. "_" .. data.ckey
    local hadCacheData = false
    if self.__isNew__ == nil and isNew == nil then
        local d = skynet.call("CLDB", "lua", "get", dblanguage.name, self.__key__)
        if d == nil then
            d = skynet.call("CLMySQL", "lua", "exesql", dblanguage.querySql(data.language, data.ckey))
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

function dblanguage:getInsertSql()
    if self:isEmpty() then
        return nil
    end
    local data = dblanguage.validData(self:value2copy())
    local sql = skynet.call("CLDB", "lua", "GETINSERTSQL", self.__name__, data)
    return sql
end
function dblanguage:tablename() -- 取得表名
    return self.__name__
end

function dblanguage:value2copy()  -- 取得数据复样，注意是只读的数据且只有当前时刻是最新的，如果要取得最新数据及修改数据，请用get、set
    local ret = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__)
    if ret then
    end
    return ret
end

function dblanguage:refreshData(data)
    if data == nil or self.__key__ == nil then
        skynet.error("dblanguage:refreshData error!")
        return
    end
    local orgData = self:value2copy()
    if orgData == nil then
        skynet.error("get old data error!!")
    end
    for k, v in pairs(data) do
        orgData[k] = v
    end
    orgData = dblanguage.validData(orgData)
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, orgData)
end

function dblanguage:set_language(v)
    -- 语言类别
    if self:isEmpty() then
        skynet.error("[dblanguage:set_language],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "language", v)
end
function dblanguage:get_language()
    -- 语言类别
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "language")
    return (tonumber(val) or 0)
end

function dblanguage:set_ckey(v)
    -- 内容key
    if self:isEmpty() then
        skynet.error("[dblanguage:set_ckey],please init first!!")
        return nil
    end
    v = v or ""
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "ckey", v)
end
function dblanguage:get_ckey()
    -- 内容key
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "ckey")
end

function dblanguage:set_content(v)
    -- 内容
    if self:isEmpty() then
        skynet.error("[dblanguage:set_content],please init first!!")
        return nil
    end
    v = v or ""
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "content", v)
end
function dblanguage:get_content()
    -- 内容
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "content")
end

-- 把数据flush到mysql里， immd=true 立即生效
function dblanguage:flush(immd)
    local sql
    local data = dblanguage.validData(self:value2copy())
    if self.__isNew__ then
        sql = skynet.call("CLDB", "lua", "GETINSERTSQL", self.__name__, data)
        return skynet.call("CLMySQL", "lua", "exesql", sql, immd)
    else
        sql = skynet.call("CLDB", "lua", "GETUPDATESQL", self.__name__, data)
        return skynet.call("CLMySQL", "lua", "save", sql, immd)
    end
end

function dblanguage:isEmpty()
    return (self.__key__ == nil) or (self:get_language() == nil) or (self:get_ckey() == nil)
end

function dblanguage:release(returnVal)
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

function dblanguage:delete()
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
function dblanguage:setTrigger(server, cmd, fieldKey)
    skynet.call("CLDB", "lua", "ADDTRIGGER", self.__name__, self.__key__, server, cmd, fieldKey)
end

---@param server 触发回调服务地址
---@param cmd 触发回调服务方法
---@param fieldKey 字段key(可为nil)
function dblanguage:unsetTrigger(server, cmd, fieldKey)
    skynet.call("CLDB", "lua", "REMOVETRIGGER", self.__name__, self.__key__, server, cmd, fieldKey)
end

function dblanguage.querySql(language, ckey)
    -- 如果某个参数为nil,则where条件中不包括该条件
    local where = {}
    if language then
        table.insert(where, "`language`=" .. language)
    end
    if ckey then
        table.insert(where, "`ckey`=" .. "'" .. ckey  .. "'")
    end
    if #where > 0 then
        return "SELECT * FROM language WHERE " .. table.concat(where, " and ") .. ";"
    else
       return "SELECT * FROM language;"
    end
end

---public 取得一个组
---@param forceSelect boolean 强制从mysql取数据
---@param orderby string 排序
function dblanguage.getListByckey(ckey, forceSelect, orderby, limitOffset, limitNum)
    if orderby and orderby ~= "" then
        forceSelect = true
    end
    local data
    local ret = {}
    local cachlist, isFullCached, list
    local groupKey = "ckey_" .. ckey
    local groupInfor = skynet.call("CLDB", "lua", "GETGROUP", dblanguage.name,  groupKey) or {}
    cachlist = groupInfor[1] or {}
    isFullCached = groupInfor[2]
    if isFullCached == true and (not forceSelect) then
        list = cachlist
        for k, v in pairs(list) do
            data = dblanguage.new(v, false)
            table.insert(ret, data:value2copy())
            data:release()
        end
    else
        local sql = "SELECT * FROM language WHERE ckey=" .. "'" .. ckey .. "'" ..  (orderby and " ORDER BY" ..  orderby or "") .. ((limitOffset and limitNum) and (" LIMIT " ..  limitOffset .. "," .. limitNum) or "") .. ";"
        list = skynet.call("CLMySQL", "lua", "exesql", sql)
        if list and list.errno then
            skynet.error("[dblanguage.getGroup] sql error==" .. sql)
            return nil
         end
         for i, v in ipairs(list) do
             local key = tostring(v.language .. "_" .. v.ckey)
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
             data = dblanguage.new(v, false)
             ret[k] = data:value2copy()
             data:release()
         end
     end
     list = nil
     -- 设置当前缓存数据是全的数据
     skynet.call("CLDB", "lua", "SETGROUPISFULL", dblanguage.name, groupKey)
     return ret
end

function dblanguage.validData(data)
    if data == nil then return nil end

    if type(data.language) ~= "number" then
        data.language = tonumber(data.language) or 0
    end
    return data
end

function dblanguage.instanse(language, ckey)
    if type(language) == "table" then
        local d = language
        language = d.language
        ckey = d.ckey
    end
    if language == nil and ckey == nil then
        skynet.error("[dblanguage.instanse] all input params == nil")
        return nil
    end
    local key = (language or "") .. "_" .. (ckey or "")
    if key == "" then
        error("the key is null", 0)
    end
    ---@type dblanguage
    local obj = dblanguage.new()
    local d = skynet.call("CLDB", "lua", "get", dblanguage.name, key)
    if d == nil then
        d = skynet.call("CLMySQL", "lua", "exesql", dblanguage.querySql(language, ckey))
        if d and d.errno == nil and #d > 0 then
            if #d == 1 then
                d = d[1]
                -- 取得mysql表里的数据
                obj.__isNew__ = false
                obj.__key__ = key
                obj:init(d)
            else
                error("get data is more than one! count==" .. #d .. ", lua==dblanguage")
            end
        else
            -- 没有数据
            obj.__isNew__ = true
        end
    else
        obj.__isNew__ = false
        obj.__key__ = key
        skynet.call("CLDB", "lua", "SETUSE", dblanguage.name, key)
    end
    return obj
end

------------------------------------
return dblanguage
