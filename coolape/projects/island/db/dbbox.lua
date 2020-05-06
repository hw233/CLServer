--[[
使用时特别注意：
1、常用方法如下，在不知道表里有没有数据时可以采用如下方法（可能会查询一次表）
    local obj＝ dbbox.instanse(idx);
    if obj:isEmpty() then
        -- 没有数据
    else
        -- 有数据
    end
2、使用如下用法时，程序会自动判断是否是insert还是update
    local obj＝ dbbox.new(data);
3、使用如下用法时，程序会自动判断是否是insert还是update
    local obj＝ dbbox.new();
    obj:init(data);
]]

require("class")
local skynet = require "skynet"
local tonumber = tonumber
require("dateEx")

-- 宝箱(礼包)
---@class dbbox : ClassBase
dbbox = class("dbbox")

dbbox.name = "box"

dbbox.keys = {
    idx = "idx", -- 唯一标识
    rwidx = "rwidx", -- 奖励包idx、掉落idx
    icon = "icon", -- 图标
    nameKey = "nameKey", -- 名称key
    descKey = "descKey", -- 描述key
    maxOutput = "maxOutput", -- 最大掉落数，如果小于等于0则没有限制
}

function dbbox:ctor(v)
    self.__name__ = "box"    -- 表名
    self.__isNew__ = nil -- false:说明mysql里已经有数据了
    if v then
        self:init(v)
    end
end

function dbbox:init(data, isNew)
    data = dbbox.validData(data)
    self.__key__ = data.idx
    local hadCacheData = false
    if self.__isNew__ == nil and isNew == nil then
        local d = skynet.call("CLDB", "lua", "get", dbbox.name, self.__key__)
        if d == nil then
            d = skynet.call("CLMySQL", "lua", "exesql", dbbox.querySql(data.idx, nil))
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

function dbbox:getInsertSql()
    if self:isEmpty() then
        return nil
    end
    local data = dbbox.validData(self:value2copy())
    local sql = skynet.call("CLDB", "lua", "GETINSERTSQL", self.__name__, data)
    return sql
end
function dbbox:tablename() -- 取得表名
    return self.__name__
end

function dbbox:value2copy()  -- 取得数据复样，注意是只读的数据且只有当前时刻是最新的，如果要取得最新数据及修改数据，请用get、set
    local ret = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__)
    if ret then
    end
    return ret
end

function dbbox:refreshData(data)
    if data == nil or self.__key__ == nil then
        skynet.error("dbbox:refreshData error!")
        return
    end
    local orgData = self:value2copy()
    if orgData == nil then
        skynet.error("get old data error!!")
    end
    for k, v in pairs(data) do
        orgData[k] = v
    end
    orgData = dbbox.validData(orgData)
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, orgData)
end

function dbbox:set_idx(v)
    -- 唯一标识
    if self:isEmpty() then
        skynet.error("[dbbox:set_idx],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "idx", v)
end
function dbbox:get_idx()
    -- 唯一标识
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "idx")
    return (tonumber(val) or 0)
end

function dbbox:set_rwidx(v)
    -- 奖励包idx、掉落idx
    if self:isEmpty() then
        skynet.error("[dbbox:set_rwidx],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "rwidx", v)
end
function dbbox:get_rwidx()
    -- 奖励包idx、掉落idx
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "rwidx")
    return (tonumber(val) or 0)
end

function dbbox:set_icon(v)
    -- 图标
    if self:isEmpty() then
        skynet.error("[dbbox:set_icon],please init first!!")
        return nil
    end
    v = v or ""
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "icon", v)
end
function dbbox:get_icon()
    -- 图标
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "icon")
end

function dbbox:set_nameKey(v)
    -- 名称key
    if self:isEmpty() then
        skynet.error("[dbbox:set_nameKey],please init first!!")
        return nil
    end
    v = v or ""
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "nameKey", v)
end
function dbbox:get_nameKey()
    -- 名称key
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "nameKey")
end

function dbbox:set_descKey(v)
    -- 描述key
    if self:isEmpty() then
        skynet.error("[dbbox:set_descKey],please init first!!")
        return nil
    end
    v = v or ""
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "descKey", v)
end
function dbbox:get_descKey()
    -- 描述key
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "descKey")
end

function dbbox:set_maxOutput(v)
    -- 最大掉落数，如果小于等于0则没有限制
    if self:isEmpty() then
        skynet.error("[dbbox:set_maxOutput],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "maxOutput", v)
end
function dbbox:get_maxOutput()
    -- 最大掉落数，如果小于等于0则没有限制
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "maxOutput")
    return (tonumber(val) or 0)
end

-- 把数据flush到mysql里， immd=true 立即生效
function dbbox:flush(immd)
    local sql
    local data = dbbox.validData(self:value2copy())
    if self.__isNew__ then
        sql = skynet.call("CLDB", "lua", "GETINSERTSQL", self.__name__, data)
        return skynet.call("CLMySQL", "lua", "exesql", sql, immd)
    else
        sql = skynet.call("CLDB", "lua", "GETUPDATESQL", self.__name__, data)
        return skynet.call("CLMySQL", "lua", "save", sql, immd)
    end
end

function dbbox:isEmpty()
    return (self.__key__ == nil) or (self:get_idx() == nil)
end

function dbbox:release(returnVal)
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

function dbbox:delete()
    local d = self:value2copy()
    skynet.call("CLDB", "lua", "SETUNUSE", self.__name__, self.__key__)
    skynet.call("CLDB", "lua", "REMOVE", self.__name__, self.__key__)
    local sql = skynet.call("CLDB", "lua", "GETDELETESQL", self.__name__, d)
    self.__key__ = nil
    return skynet.call("CLMySQL", "lua", "exesql", sql)
end

---public 设置触发器（当有数据改变时回调）
---@param server any 触发回调服务地址
---@param cmd string 触发回调服务方法
---@param fieldKey string 字段key(可为nil)
function dbbox:setTrigger(server, cmd, fieldKey)
    skynet.call("CLDB", "lua", "ADDTRIGGER", self.__name__, self.__key__, server, cmd, fieldKey)
end

---@param server and 触发回调服务地址
---@param cmd string 触发回调服务方法
---@param fieldKey string 字段key(可为nil)
function dbbox:unsetTrigger(server, cmd, fieldKey)
    skynet.call("CLDB", "lua", "REMOVETRIGGER", self.__name__, self.__key__, server, cmd, fieldKey)
end

function dbbox.querySql(idx, rwidx)
    -- 如果某个参数为nil,则where条件中不包括该条件
    local where = {}
    if idx then
        table.insert(where, "`idx`=" .. idx)
    end
    if rwidx then
        table.insert(where, "`rwidx`=" .. rwidx)
    end
    if #where > 0 then
        return "SELECT * FROM box WHERE " .. table.concat(where, " and ") .. ";"
    else
       return "SELECT * FROM box;"
    end
end

---public 取得一个组
---@param forceSelect boolean 强制从mysql取数据
---@param orderby string 排序
function dbbox.getListByrwidx(rwidx, forceSelect, orderby, limitOffset, limitNum)
    if orderby and orderby ~= "" then
        forceSelect = true
    end
    local data
    local ret = {}
    local cachlist, isFullCached, list
    local groupKey = "rwidx_" .. rwidx
    local groupInfor = skynet.call("CLDB", "lua", "GETGROUP", dbbox.name,  groupKey) or {}
    cachlist = groupInfor[1] or {}
    isFullCached = groupInfor[2]
    if isFullCached == true and (not forceSelect) then
        list = cachlist
        for k, v in pairs(list) do
            data = dbbox.new(v, false)
            table.insert(ret, data:value2copy())
            data:release()
        end
    else
        local sql = "SELECT * FROM box WHERE rwidx=" .. rwidx ..  (orderby and " ORDER BY" ..  orderby or "") .. ((limitOffset and limitNum) and (" LIMIT " ..  limitOffset .. "," .. limitNum) or "") .. ";"
        list = skynet.call("CLMySQL", "lua", "exesql", sql)
        if list and list.errno then
            skynet.error("[dbbox.getGroup] sql error==" .. sql)
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
             data = dbbox.new(v, false)
             ret[k] = data:value2copy()
             data:release()
         end
     end
     list = nil
     -- 设置当前缓存数据是全的数据
     skynet.call("CLDB", "lua", "SETGROUPISFULL", dbbox.name, groupKey)
     return ret
end

function dbbox.validData(data)
    if data == nil then return nil end

    if type(data.idx) ~= "number" then
        data.idx = tonumber(data.idx) or 0
    end
    if type(data.rwidx) ~= "number" then
        data.rwidx = tonumber(data.rwidx) or 0
    end
    if type(data.maxOutput) ~= "number" then
        data.maxOutput = tonumber(data.maxOutput) or 0
    end
    return data
end

function dbbox.instanse(idx)
    if type(idx) == "table" then
        local d = idx
        idx = d.idx
    end
    if idx == nil then
        skynet.error("[dbbox.instanse] all input params == nil")
        return nil
    end
    local key = (idx or "")
    if key == "" then
        error("the key is null", 0)
    end
    ---@type dbbox
    local obj = dbbox.new()
    local d = skynet.call("CLDB", "lua", "get", dbbox.name, key)
    if d == nil then
        d = skynet.call("CLMySQL", "lua", "exesql", dbbox.querySql(idx, nil))
        if d and d.errno == nil and #d > 0 then
            if #d == 1 then
                d = d[1]
                -- 取得mysql表里的数据
                obj.__isNew__ = false
                obj.__key__ = key
                obj:init(d)
            else
                error("get data is more than one! count==" .. #d .. ", lua==dbbox")
            end
        else
            -- 没有数据
            obj.__isNew__ = true
        end
    else
        obj.__isNew__ = false
        obj.__key__ = key
        skynet.call("CLDB", "lua", "SETUSE", dbbox.name, key)
    end
    return obj
end

------------------------------------
return dbbox
