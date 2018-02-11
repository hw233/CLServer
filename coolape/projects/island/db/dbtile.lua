--[[
使用时特别注意：
1、常用方法如下，在不知道表里有没有数据时可以采用如下方法（可能会查询一次表）
    local obj＝ dbtile.instanse(idx);
    if obj:isEmpty() then
        -- 没有数据
    else
        -- 有数据
    end
2、使用如下用法时，程序认为mysql已经有数据了，只会做更新操作
    local obj＝ dbtile.new(data);
3、使用如下用法时，程序认为mysql没有数据，会插入一条记录到表
    local obj＝ dbtile.new();
    obj:init(data);
]]

require("class")
local skynet = require "skynet"

-- 地块表
---@class dbtile
dbtile = class("dbtile")

dbtile.name = "tile"

function dbtile:ctor(v)
    self.__name__ = "tile"    -- 表名
    if v then
        self.__isNew__ = false -- 说明mysql里已经有数据了
        self:init(v)
    else
        self.__isNew__ = true    -- 新建数据，说明mysql表里没有数据
        self.__key__ = nil -- 缓存数据的key
    end
end

function dbtile:init(data)
    self.__key__ = data.idx
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
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__)
end

function dbtile:setidx(v)
    -- 唯一标识
    if self:isEmpty() then
        skynet.error("[dbtile:setidx],please init first!!")
        return nil
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "idx", v)
end
function dbtile:getidx()
    -- 唯一标识
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "idx")
end

function dbtile:setattrid(v)
    -- 属性id
    if self:isEmpty() then
        skynet.error("[dbtile:setattrid],please init first!!")
        return nil
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "attrid", v)
end
function dbtile:getattrid()
    -- 属性id
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "attrid")
end

function dbtile:setcidx(v)
    -- 主城idx
    if self:isEmpty() then
        skynet.error("[dbtile:setcidx],please init first!!")
        return nil
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "cidx", v)
end
function dbtile:getcidx()
    -- 主城idx
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "cidx")
end

function dbtile:setpos(v)
    -- 城所在世界grid的index
    if self:isEmpty() then
        skynet.error("[dbtile:setpos],please init first!!")
        return nil
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "pos", v)
end
function dbtile:getpos()
    -- 城所在世界grid的index
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "pos")
end

-- 把数据flush到mysql里， immd=true 立即生效
function dbtile:flush(immd)
    local sql
    if self.__isNew__ then
        sql = skynet.call("CLDB", "lua", "GETINSERTSQL", self.__name__, self:value2copy())
    else
        sql = skynet.call("CLDB", "lua", "GETUPDATESQL", self.__name__, self:value2copy())
    end
    return skynet.call("CLMySql", "lua", "save", sql, immd)
end

function dbtile:isEmpty()
    return (self.__key__ == nil) or (self:getidx() == nil)
end

function dbtile:release()
    skynet.call("CLDB", "lua", "SETUNUSE", self.__name__, self.__key__)
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
function dbtile.getList(cidx, orderby)
    local sql = "SELECT * FROM servers WHERE cidx=" .. cidx ..  (orderby and " ORDER BY" ..  orderby or "") .. ";"
    local list = skynet.call("CLMySQL", "lua", "exesql", sql)
    if list and list.errno then
        skynet.error("[dbtile.getGroup] sql error==" .. sql)
        return nil
     end
     for i, v in ipairs(list) do
         local key = v.idx
         local d = skynet.call("CLDB", "lua", "get", dbtile.name, key)
         if d ~= nil then
             -- 用缓存的数据才是最新的
             list[i] = d
         end
     end
     return list
end

function dbtile.instanse(idx)
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
    obj.__key__ = key
    local d = skynet.call("CLDB", "lua", "get", dbtile.name, key)
    if d == nil then
        d = skynet.call("CLMySQL", "lua", "exesql", dbtile.querySql(idx, nil))
        if d and d.errno == nil and #d > 0 then
            if #d == 1 then
                d = d[1]
                -- 取得mysql表里的数据
                obj.__isNew__ = false
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
        skynet.call("CLDB", "lua", "SETUSE", dbtile.name, key)
    end
    return obj
end

------------------------------------
return dbtile
