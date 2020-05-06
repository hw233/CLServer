--[[
使用时特别注意：
1、常用方法如下，在不知道表里有没有数据时可以采用如下方法（可能会查询一次表）
    local obj＝ dbitemsused.instanse(idx);
    if obj:isEmpty() then
        -- 没有数据
    else
        -- 有数据
    end
2、使用如下用法时，程序会自动判断是否是insert还是update
    local obj＝ dbitemsused.new(data);
3、使用如下用法时，程序会自动判断是否是insert还是update
    local obj＝ dbitemsused.new();
    obj:init(data);
]]

require("class")
local skynet = require "skynet"
local tonumber = tonumber
require("dateEx")

-- 道具物品使用记录
---@class dbitemsused : ClassBase
dbitemsused = class("dbitemsused")

dbitemsused.name = "itemsused"

dbitemsused.keys = {
    idx = "idx", -- 唯一标识
    itemidx = "itemidx", -- 道具唯一标识
    pidx = "pidx", -- 玩家唯一标识
    id = "id", -- 对应的id
    type = "type", -- 类型,IDConst.ItemType
    num = "num", -- 数量
    dateuse = "dateuse", -- 使用时间
    dec = "dec", -- 使用备注
}

function dbitemsused:ctor(v)
    self.__name__ = "itemsused"    -- 表名
    self.__isNew__ = nil -- false:说明mysql里已经有数据了
    if v then
        self:init(v)
    end
end

function dbitemsused:init(data, isNew)
    data = dbitemsused.validData(data)
    self.__key__ = data.idx
    local hadCacheData = false
    if self.__isNew__ == nil and isNew == nil then
        local d = skynet.call("CLDB", "lua", "get", dbitemsused.name, self.__key__)
        if d == nil then
            d = skynet.call("CLMySQL", "lua", "exesql", dbitemsused.querySql(data.idx))
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

function dbitemsused:getInsertSql()
    if self:isEmpty() then
        return nil
    end
    local data = dbitemsused.validData(self:value2copy())
    local sql = skynet.call("CLDB", "lua", "GETINSERTSQL", self.__name__, data)
    return sql
end
function dbitemsused:tablename() -- 取得表名
    return self.__name__
end

function dbitemsused:value2copy()  -- 取得数据复样，注意是只读的数据且只有当前时刻是最新的，如果要取得最新数据及修改数据，请用get、set
    local ret = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__)
    if ret then
        ret.dateuse = self:get_dateuse()
    end
    return ret
end

function dbitemsused:refreshData(data)
    if data == nil or self.__key__ == nil then
        skynet.error("dbitemsused:refreshData error!")
        return
    end
    local orgData = self:value2copy()
    if orgData == nil then
        skynet.error("get old data error!!")
    end
    for k, v in pairs(data) do
        orgData[k] = v
    end
    orgData = dbitemsused.validData(orgData)
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, orgData)
end

function dbitemsused:set_idx(v)
    -- 唯一标识
    if self:isEmpty() then
        skynet.error("[dbitemsused:set_idx],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "idx", v)
end
function dbitemsused:get_idx()
    -- 唯一标识
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "idx")
    return (tonumber(val) or 0)
end

function dbitemsused:set_itemidx(v)
    -- 道具唯一标识
    if self:isEmpty() then
        skynet.error("[dbitemsused:set_itemidx],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "itemidx", v)
end
function dbitemsused:get_itemidx()
    -- 道具唯一标识
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "itemidx")
    return (tonumber(val) or 0)
end

function dbitemsused:set_pidx(v)
    -- 玩家唯一标识
    if self:isEmpty() then
        skynet.error("[dbitemsused:set_pidx],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "pidx", v)
end
function dbitemsused:get_pidx()
    -- 玩家唯一标识
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "pidx")
    return (tonumber(val) or 0)
end

function dbitemsused:set_id(v)
    -- 对应的id
    if self:isEmpty() then
        skynet.error("[dbitemsused:set_id],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "id", v)
end
function dbitemsused:get_id()
    -- 对应的id
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "id")
    return (tonumber(val) or 0)
end

function dbitemsused:set_type(v)
    -- 类型,IDConst.ItemType
    if self:isEmpty() then
        skynet.error("[dbitemsused:set_type],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "type", v)
end
function dbitemsused:get_type()
    -- 类型,IDConst.ItemType
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "type")
    return (tonumber(val) or 0)
end

function dbitemsused:set_num(v)
    -- 数量
    if self:isEmpty() then
        skynet.error("[dbitemsused:set_num],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "num", v)
end
function dbitemsused:get_num()
    -- 数量
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "num")
    return (tonumber(val) or 0)
end

function dbitemsused:set_dateuse(v)
    -- 使用时间
    if self:isEmpty() then
        skynet.error("[dbitemsused:set_dateuse],please init first!!")
        return nil
    end
    if type(v) == "number" then
        v = dateEx.seconds2Str(v/1000)
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "dateuse", v)
end
function dbitemsused:get_dateuse()
    -- 使用时间
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "dateuse")
    if type(val) == "string" then
        return dateEx.str2Seconds(val)*1000 -- 转成毫秒
    else
        return val or 0
    end
end

function dbitemsused:set_dec(v)
    -- 使用备注
    if self:isEmpty() then
        skynet.error("[dbitemsused:set_dec],please init first!!")
        return nil
    end
    v = v or ""
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "dec", v)
end
function dbitemsused:get_dec()
    -- 使用备注
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "dec")
end

-- 把数据flush到mysql里， immd=true 立即生效
function dbitemsused:flush(immd)
    local sql
    local data = dbitemsused.validData(self:value2copy())
    if self.__isNew__ then
        sql = skynet.call("CLDB", "lua", "GETINSERTSQL", self.__name__, data)
        return skynet.call("CLMySQL", "lua", "exesql", sql, immd)
    else
        sql = skynet.call("CLDB", "lua", "GETUPDATESQL", self.__name__, data)
        return skynet.call("CLMySQL", "lua", "save", sql, immd)
    end
end

function dbitemsused:isEmpty()
    return (self.__key__ == nil) or (self:get_idx() == nil)
end

function dbitemsused:release(returnVal)
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

function dbitemsused:delete()
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
function dbitemsused:setTrigger(server, cmd, fieldKey)
    skynet.call("CLDB", "lua", "ADDTRIGGER", self.__name__, self.__key__, server, cmd, fieldKey)
end

---@param server 触发回调服务地址
---@param cmd 触发回调服务方法
---@param fieldKey 字段key(可为nil)
function dbitemsused:unsetTrigger(server, cmd, fieldKey)
    skynet.call("CLDB", "lua", "REMOVETRIGGER", self.__name__, self.__key__, server, cmd, fieldKey)
end

function dbitemsused.querySql(idx)
    -- 如果某个参数为nil,则where条件中不包括该条件
    local where = {}
    if idx then
        table.insert(where, "`idx`=" .. idx)
    end
    if #where > 0 then
        return "SELECT * FROM itemsused WHERE " .. table.concat(where, " and ") .. ";"
    else
       return "SELECT * FROM itemsused;"
    end
end

---public 取得一个组
---@param forceSelect boolean 强制从mysql取数据
---@param orderby string 排序
function dbitemsused.getListBypidx(pidx, forceSelect, orderby, limitOffset, limitNum)
    if orderby and orderby ~= "" then
        forceSelect = true
    end
    local data
    local ret = {}
    local cachlist, isFullCached, list
    local groupKey = "pidx_" .. pidx
    local groupInfor = skynet.call("CLDB", "lua", "GETGROUP", dbitemsused.name,  groupKey) or {}
    cachlist = groupInfor[1] or {}
    isFullCached = groupInfor[2]
    if isFullCached == true and (not forceSelect) then
        list = cachlist
        for k, v in pairs(list) do
            data = dbitemsused.new(v, false)
            table.insert(ret, data:value2copy())
            data:release()
        end
    else
        local sql = "SELECT * FROM itemsused WHERE pidx=" .. pidx ..  (orderby and " ORDER BY" ..  orderby or "") .. ((limitOffset and limitNum) and (" LIMIT " ..  limitOffset .. "," .. limitNum) or "") .. ";"
        list = skynet.call("CLMySQL", "lua", "exesql", sql)
        if list and list.errno then
            skynet.error("[dbitemsused.getGroup] sql error==" .. sql)
            return nil
         end
         for i, v in ipairs(list) do
             local key = tostring(v.idx)
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
             data = dbitemsused.new(v, false)
             ret[k] = data:value2copy()
             data:release()
         end
     end
     list = nil
     -- 设置当前缓存数据是全的数据
     skynet.call("CLDB", "lua", "SETGROUPISFULL", dbitemsused.name, groupKey)
     return ret
end

function dbitemsused.validData(data)
    if data == nil then return nil end

    if type(data.idx) ~= "number" then
        data.idx = tonumber(data.idx) or 0
    end
    if type(data.itemidx) ~= "number" then
        data.itemidx = tonumber(data.itemidx) or 0
    end
    if type(data.pidx) ~= "number" then
        data.pidx = tonumber(data.pidx) or 0
    end
    if type(data.id) ~= "number" then
        data.id = tonumber(data.id) or 0
    end
    if type(data.type) ~= "number" then
        data.type = tonumber(data.type) or 0
    end
    if type(data.num) ~= "number" then
        data.num = tonumber(data.num) or 0
    end
    if type(data.dateuse) == "number" then
        data.dateuse = dateEx.seconds2Str(data.dateuse/1000)
    end
    return data
end

function dbitemsused.instanse(idx)
    if type(idx) == "table" then
        local d = idx
        idx = d.idx
    end
    if idx == nil then
        skynet.error("[dbitemsused.instanse] all input params == nil")
        return nil
    end
    local key = (idx or "")
    if key == "" then
        error("the key is null", 0)
    end
    ---@type dbitemsused
    local obj = dbitemsused.new()
    local d = skynet.call("CLDB", "lua", "get", dbitemsused.name, key)
    if d == nil then
        d = skynet.call("CLMySQL", "lua", "exesql", dbitemsused.querySql(idx))
        if d and d.errno == nil and #d > 0 then
            if #d == 1 then
                d = d[1]
                -- 取得mysql表里的数据
                obj.__isNew__ = false
                obj.__key__ = key
                obj:init(d)
            else
                error("get data is more than one! count==" .. #d .. ", lua==dbitemsused")
            end
        else
            -- 没有数据
            obj.__isNew__ = true
        end
    else
        obj.__isNew__ = false
        obj.__key__ = key
        skynet.call("CLDB", "lua", "SETUSE", dbitemsused.name, key)
    end
    return obj
end

------------------------------------
return dbitemsused
