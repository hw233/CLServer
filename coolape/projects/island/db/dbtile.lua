--[[
使用时特别注意：
1、常用方法如下，在不知道表里有没有数据时可以采用如下方法（可能会查询一次表）
    local obj＝ dbtile.instanse(idx);
    if obj:isEmpty() then
        -- 没有数据
    else
        -- 有数据
    end
2、使用如下用法时，程序会自动判断是否是insert还是update
    local obj＝ dbtile.new(data);
3、使用如下用法时，程序会自动判断是否是insert还是update
    local obj＝ dbtile.new();
    obj:init(data);
]]

require("class")
local skynet = require "skynet"
local tonumber = tonumber
require("dateEx")

-- 地块表
---@class dbtile
dbtile = class("dbtile")

dbtile.name = "tile"

function dbtile:ctor(v)
    self.__name__ = "tile"    -- 表名
    self.__isNew__ = nil -- false:说明mysql里已经有数据了
    if v then
        self:init(v)
    end
end

function dbtile:init(data, isNew)
    data = dbtile.validData(data)
    self.__key__ = data.idx
    if self.__isNew__ == nil and isNew == nil then
        local d = skynet.call("CLDB", "lua", "get", dbtile.name, self.__key__)
        if d == nil then
            d = skynet.call("CLMySQL", "lua", "exesql", dbtile.querySql(data.idx, nil))
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

function dbtile:tablename() -- 取得表名
    return self.__name__
end

function dbtile:value2copy()  -- 取得数据复样，注意是只读的数据且只有当前时刻是最新的，如果要取得最新数据及修改数据，请用get、set
    local ret = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__)
    if ret then
    end
    return ret
end

function dbtile:set_idx(v)
    -- 唯一标识
    if self:isEmpty() then
        skynet.error("[dbtile:set_idx],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "idx", v)
end
function dbtile:get_idx()
    -- 唯一标识
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "idx")
    return (tonumber(val) or 0)
end

function dbtile:set_cidx(v)
    -- 主城idx
    if self:isEmpty() then
        skynet.error("[dbtile:set_cidx],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "cidx", v)
end
function dbtile:get_cidx()
    -- 主城idx
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "cidx")
    return (tonumber(val) or 0)
end

function dbtile:set_attrid(v)
    -- 属性id
    if self:isEmpty() then
        skynet.error("[dbtile:set_attrid],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "attrid", v)
end
function dbtile:get_attrid()
    -- 属性id
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "attrid")
    return (tonumber(val) or 0)
end

function dbtile:set_pos(v)
    -- 城所在世界grid的index
    if self:isEmpty() then
        skynet.error("[dbtile:set_pos],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "pos", v)
end
function dbtile:get_pos()
    -- 城所在世界grid的index
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "pos")
    return (tonumber(val) or 0)
end

-- 把数据flush到mysql里， immd=true 立即生效
function dbtile:flush(immd)
    local sql
    if self.__isNew__ then
        sql = skynet.call("CLDB", "lua", "GETINSERTSQL", self.__name__, self:value2copy())
    else
        sql = skynet.call("CLDB", "lua", "GETUPDATESQL", self.__name__, self:value2copy())
    end
    return skynet.call("CLMySQL", "lua", "save", sql, immd)
end

function dbtile:isEmpty()
    return (self.__key__ == nil) or (self:get_idx() == nil)
end

function dbtile:release()
    skynet.call("CLDB", "lua", "SETUNUSE", self.__name__, self.__key__)
    self.__isNew__ = nil
    self.__key__ = nil
end

function dbtile:delete()
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
function dbtile:setTrigger(server, cmd, fieldKey)
    skynet.call("CLDB", "lua", "ADDTRIGGER", self.__name__, self.__key__, server, cmd, fieldKey)
end

---@param server 触发回调服务地址
---@param cmd 触发回调服务方法
---@param fieldKey 字段key(可为nil)
function dbtile:unsetTrigger(server, cmd, fieldKey)
    skynet.call("CLDB", "lua", "REMOVETRIGGER", self.__name__, self.__key__, server, cmd, fieldKey)
end

function dbtile.querySql(idx, cidx)
    -- 如果某个参数为nil,则where条件中不包括该条件
    local where = {}
    if idx then
        table.insert(where, "`idx`=" .. idx)
    end
    if cidx then
        table.insert(where, "`cidx`=" .. cidx)
    end
    if #where > 0 then
        return "SELECT * FROM tile WHERE " .. table.concat(where, " and ") .. ";"
    else
       return "SELECT * FROM tile;"
    end
end

-- 取得一个组
function dbtile.getListBycidx(cidx, orderby, limitOffset, limitNum)
    local sql = "SELECT * FROM tile WHERE cidx=" .. cidx ..  (orderby and " ORDER BY" ..  orderby or "") .. ((limitOffset and limitNum) and (" LIMIT " ..  limitOffset .. "," .. limitNum) or "") .. ";"
    local list = skynet.call("CLMySQL", "lua", "exesql", sql)
    if list and list.errno then
        skynet.error("[dbtile.getGroup] sql error==" .. sql)
        return nil
     end
     local cachlist = skynet.call("CLDB", "lua", "GETGROUP", dbtile.name, cidx) or {}
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
         data = dbtile.new(v, false)
         ret[k] = data:value2copy()
         data:release()
     end
     list = nil
     return ret
end

function dbtile.validData(data)
    if data == nil then return nil end

    if type(data.idx) ~= "number" then
        data.idx = tonumber(data.idx) or 0
    end
    if type(data.cidx) ~= "number" then
        data.cidx = tonumber(data.cidx) or 0
    end
    if type(data.attrid) ~= "number" then
        data.attrid = tonumber(data.attrid) or 0
    end
    if type(data.pos) ~= "number" then
        data.pos = tonumber(data.pos) or 0
    end
    return data
end

function dbtile.instanse(idx)
    if type(idx) == "table" then
        local d = idx
        idx = d.idx
    end
    if idx == nil then
        skynet.error("[dbtile.instanse] all input params == nil")
        return nil
    end
    local key = (idx or "")
    if key == "" then
        error("the key is null", 0)
    end
    ---@type dbtile
    local obj = dbtile.new()
    local d = skynet.call("CLDB", "lua", "get", dbtile.name, key)
    if d == nil then
        d = skynet.call("CLMySQL", "lua", "exesql", dbtile.querySql(idx, nil))
        if d and d.errno == nil and #d > 0 then
            if #d == 1 then
                d = d[1]
                -- 取得mysql表里的数据
                obj.__isNew__ = false
                obj.__key__ = key
                obj:init(d)
            else
                error("get data is more than one! count==" .. #d .. ", lua==dbtile")
            end
        else
            -- 没有数据
            obj.__isNew__ = true
        end
    else
        obj.__isNew__ = false
        obj.__key__ = key
        skynet.call("CLDB", "lua", "SETUSE", dbtile.name, key)
    end
    return obj
end

------------------------------------
return dbtile
