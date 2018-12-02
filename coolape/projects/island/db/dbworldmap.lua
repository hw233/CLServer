--[[
使用时特别注意：
1、常用方法如下，在不知道表里有没有数据时可以采用如下方法（可能会查询一次表）
    local obj＝ dbworldmap.instanse(idx);
    if obj:isEmpty() then
        -- 没有数据
    else
        -- 有数据
    end
2、使用如下用法时，程序会自动判断是否是insert还是update
    local obj＝ dbworldmap.new(data);
3、使用如下用法时，程序会自动判断是否是insert还是update
    local obj＝ dbworldmap.new();
    obj:init(data);
]]

require("class")
local skynet = require "skynet"
local tonumber = tonumber
require("dateEx")

-- 世界地图
---@class dbworldmap
dbworldmap = class("dbworldmap")

dbworldmap.name = "worldmap"

dbworldmap.keys = {
    idx = "idx", -- 网格index
    type = "type", -- 地块类型 1：玩家，2：npc
    cidx = "cidx", -- 主城idx
    pageIdx = "pageIdx", -- 所在屏的index
    val1 = "val1", -- 值1
    val2 = "val2", -- 值2
    val3 = "val3", -- 值3
}

function dbworldmap:ctor(v)
    self.__name__ = "worldmap"    -- 表名
    self.__isNew__ = nil -- false:说明mysql里已经有数据了
    if v then
        self:init(v)
    end
end

function dbworldmap:init(data, isNew)
    data = dbworldmap.validData(data)
    self.__key__ = data.idx
    if self.__isNew__ == nil and isNew == nil then
        local d = skynet.call("CLDB", "lua", "get", dbworldmap.name, self.__key__)
        if d == nil then
            d = skynet.call("CLMySQL", "lua", "exesql", dbworldmap.querySql(data.idx))
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

function dbworldmap:tablename() -- 取得表名
    return self.__name__
end

function dbworldmap:value2copy()  -- 取得数据复样，注意是只读的数据且只有当前时刻是最新的，如果要取得最新数据及修改数据，请用get、set
    local ret = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__)
    if ret then
    end
    return ret
end

function dbworldmap:refreshData(data)
    if data == nil or self.__key__ == nil then
        skynet.error("dbworldmap:refreshData error!")
        return
    end
    local orgData = self:value2copy()
    if orgData == nil then
        skynet.error("get old data error!!")
    end
    for k, v in pairs(data) do
        orgData[k] = v
    end
    orgData = dbworldmap.validData(orgData)
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, orgData)
end

function dbworldmap:set_idx(v)
    -- 网格index
    if self:isEmpty() then
        skynet.error("[dbworldmap:set_idx],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "idx", v)
end
function dbworldmap:get_idx()
    -- 网格index
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "idx")
    return (tonumber(val) or 0)
end

function dbworldmap:set_type(v)
    -- 地块类型 1：玩家，2：npc
    if self:isEmpty() then
        skynet.error("[dbworldmap:set_type],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "type", v)
end
function dbworldmap:get_type()
    -- 地块类型 1：玩家，2：npc
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "type")
    return (tonumber(val) or 0)
end

function dbworldmap:set_cidx(v)
    -- 主城idx
    if self:isEmpty() then
        skynet.error("[dbworldmap:set_cidx],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "cidx", v)
end
function dbworldmap:get_cidx()
    -- 主城idx
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "cidx")
    return (tonumber(val) or 0)
end

function dbworldmap:set_pageIdx(v)
    -- 所在屏的index
    if self:isEmpty() then
        skynet.error("[dbworldmap:set_pageIdx],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "pageIdx", v)
end
function dbworldmap:get_pageIdx()
    -- 所在屏的index
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "pageIdx")
    return (tonumber(val) or 0)
end

function dbworldmap:set_val1(v)
    -- 值1
    if self:isEmpty() then
        skynet.error("[dbworldmap:set_val1],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "val1", v)
end
function dbworldmap:get_val1()
    -- 值1
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "val1")
    return (tonumber(val) or 0)
end

function dbworldmap:set_val2(v)
    -- 值2
    if self:isEmpty() then
        skynet.error("[dbworldmap:set_val2],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "val2", v)
end
function dbworldmap:get_val2()
    -- 值2
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "val2")
    return (tonumber(val) or 0)
end

function dbworldmap:set_val3(v)
    -- 值3
    if self:isEmpty() then
        skynet.error("[dbworldmap:set_val3],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "val3", v)
end
function dbworldmap:get_val3()
    -- 值3
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "val3")
    return (tonumber(val) or 0)
end

-- 把数据flush到mysql里， immd=true 立即生效
function dbworldmap:flush(immd)
    local sql
    if self.__isNew__ then
        sql = skynet.call("CLDB", "lua", "GETINSERTSQL", self.__name__, self:value2copy())
    else
        sql = skynet.call("CLDB", "lua", "GETUPDATESQL", self.__name__, self:value2copy())
    end
    return skynet.call("CLMySQL", "lua", "save", sql, immd)
end

function dbworldmap:isEmpty()
    return (self.__key__ == nil) or (self:get_idx() == nil)
end

function dbworldmap:release()
    skynet.call("CLDB", "lua", "SETUNUSE", self.__name__, self.__key__)
    self.__isNew__ = nil
    self.__key__ = nil
end

function dbworldmap:delete()
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
function dbworldmap:setTrigger(server, cmd, fieldKey)
    skynet.call("CLDB", "lua", "ADDTRIGGER", self.__name__, self.__key__, server, cmd, fieldKey)
end

---@param server 触发回调服务地址
---@param cmd 触发回调服务方法
---@param fieldKey 字段key(可为nil)
function dbworldmap:unsetTrigger(server, cmd, fieldKey)
    skynet.call("CLDB", "lua", "REMOVETRIGGER", self.__name__, self.__key__, server, cmd, fieldKey)
end

function dbworldmap.querySql(idx)
    -- 如果某个参数为nil,则where条件中不包括该条件
    local where = {}
    if idx then
        table.insert(where, "`idx`=" .. idx)
    end
    if #where > 0 then
        return "SELECT * FROM worldmap WHERE " .. table.concat(where, " and ") .. ";"
    else
       return "SELECT * FROM worldmap;"
    end
end

-- 取得一个组
function dbworldmap.getListBypageIdx(pageIdx, orderby, limitOffset, limitNum)
    local sql = "SELECT * FROM worldmap WHERE pageIdx=" .. pageIdx ..  (orderby and " ORDER BY" ..  orderby or "") .. ((limitOffset and limitNum) and (" LIMIT " ..  limitOffset .. "," .. limitNum) or "") .. ";"
    local list = skynet.call("CLMySQL", "lua", "exesql", sql)
    if list and list.errno then
        skynet.error("[dbworldmap.getGroup] sql error==" .. sql)
        return nil
     end
     local cachlist = skynet.call("CLDB", "lua", "GETGROUP", dbworldmap.name, pageIdx) or {}
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
     local data
     local ret = {}
     for k, v in ipairs(list) do
         data = dbworldmap.new(v, false)
         ret[k] = data:value2copy()
         data:release()
     end
     list = nil
     return ret
end

function dbworldmap.validData(data)
    if data == nil then return nil end

    if type(data.idx) ~= "number" then
        data.idx = tonumber(data.idx) or 0
    end
    if type(data.type) ~= "number" then
        data.type = tonumber(data.type) or 0
    end
    if type(data.cidx) ~= "number" then
        data.cidx = tonumber(data.cidx) or 0
    end
    if type(data.pageIdx) ~= "number" then
        data.pageIdx = tonumber(data.pageIdx) or 0
    end
    if type(data.val1) ~= "number" then
        data.val1 = tonumber(data.val1) or 0
    end
    if type(data.val2) ~= "number" then
        data.val2 = tonumber(data.val2) or 0
    end
    if type(data.val3) ~= "number" then
        data.val3 = tonumber(data.val3) or 0
    end
    return data
end

function dbworldmap.instanse(idx)
    if type(idx) == "table" then
        local d = idx
        idx = d.idx
    end
    if idx == nil then
        skynet.error("[dbworldmap.instanse] all input params == nil")
        return nil
    end
    local key = (idx or "")
    if key == "" then
        error("the key is null", 0)
    end
    ---@type dbworldmap
    local obj = dbworldmap.new()
    local d = skynet.call("CLDB", "lua", "get", dbworldmap.name, key)
    if d == nil then
        d = skynet.call("CLMySQL", "lua", "exesql", dbworldmap.querySql(idx))
        if d and d.errno == nil and #d > 0 then
            if #d == 1 then
                d = d[1]
                -- 取得mysql表里的数据
                obj.__isNew__ = false
                obj.__key__ = key
                obj:init(d)
            else
                error("get data is more than one! count==" .. #d .. ", lua==dbworldmap")
            end
        else
            -- 没有数据
            obj.__isNew__ = true
        end
    else
        obj.__isNew__ = false
        obj.__key__ = key
        skynet.call("CLDB", "lua", "SETUSE", dbworldmap.name, key)
    end
    return obj
end

------------------------------------
return dbworldmap
