--[[
使用时特别注意：
1、常用方法如下，在不知道表里有没有数据时可以采用如下方法（可能会查询一次表）
    local obj＝ dbbuilding.instanse(idx);
    if obj:isEmpty() then
        -- 没有数据
    else
        -- 有数据
    end
2、使用如下用法时，程序认为mysql已经有数据了，只会做更新操作
    local obj＝ dbbuilding.new(data);
3、使用如下用法时，程序认为mysql没有数据，会插入一条记录到表
    local obj＝ dbbuilding.new();
    obj:init(data);
]]

require("class")
local skynet = require "skynet"

-- 建筑表
---@class dbbuilding
dbbuilding = class("dbbuilding")

dbbuilding.name = "building"

function dbbuilding:ctor(v)
    self.__name__ = "building"    -- 表名
    if v then
        self.__isNew__ = false -- 说明mysql里已经有数据了
        self:init(v)
    else
        self.__isNew__ = true    -- 新建数据，说明mysql表里没有数据
        self.__key__ = nil -- 缓存数据的key
    end
end

function dbbuilding:init(data)
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

function dbbuilding:tablename() -- 取得表名
    return self.__name__
end

function dbbuilding:value2copy()  -- 取得数据复样，注意是只读的数据且只有当前时刻是最新的，如果要取得最新数据及修改数据，请用get、set
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__)
end

function dbbuilding:setidx(v)
    -- 唯一标识
    if self:isEmpty() then
        skynet.error("[dbbuilding:setidx],please init first!!")
        return nil
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "idx", v)
end
function dbbuilding:getidx()
    -- 唯一标识
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "idx")
end

function dbbuilding:setcidx(v)
    -- 主城idx
    if self:isEmpty() then
        skynet.error("[dbbuilding:setcidx],please init first!!")
        return nil
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "cidx", v)
end
function dbbuilding:getcidx()
    -- 主城idx
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "cidx")
end

function dbbuilding:setpos(v)
    -- 位置，即在城的gird中的index
    if self:isEmpty() then
        skynet.error("[dbbuilding:setpos],please init first!!")
        return nil
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "pos", v)
end
function dbbuilding:getpos()
    -- 位置，即在城的gird中的index
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "pos")
end

function dbbuilding:setattrid(v)
    -- 属性配置id
    if self:isEmpty() then
        skynet.error("[dbbuilding:setattrid],please init first!!")
        return nil
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "attrid", v)
end
function dbbuilding:getattrid()
    -- 属性配置id
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "attrid")
end

function dbbuilding:setlev(v)
    -- 等级
    if self:isEmpty() then
        skynet.error("[dbbuilding:setlev],please init first!!")
        return nil
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "lev", v)
end
function dbbuilding:getlev()
    -- 等级
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "lev")
end

function dbbuilding:setval(v)
    -- 值。如:产量，仓库的存储量等
    if self:isEmpty() then
        skynet.error("[dbbuilding:setval],please init first!!")
        return nil
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "val", v)
end
function dbbuilding:getval()
    -- 值。如:产量，仓库的存储量等
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "val")
end

function dbbuilding:setval2(v)
    -- 值2。如:产量，仓库的存储量等
    if self:isEmpty() then
        skynet.error("[dbbuilding:setval2],please init first!!")
        return nil
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "val2", v)
end
function dbbuilding:getval2()
    -- 值2。如:产量，仓库的存储量等
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "val2")
end

function dbbuilding:setval3(v)
    -- 值3。如:产量，仓库的存储量等
    if self:isEmpty() then
        skynet.error("[dbbuilding:setval3],please init first!!")
        return nil
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "val3", v)
end
function dbbuilding:getval3()
    -- 值3。如:产量，仓库的存储量等
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "val3")
end

function dbbuilding:setval4(v)
    -- 值4。如:产量，仓库的存储量等
    if self:isEmpty() then
        skynet.error("[dbbuilding:setval4],please init first!!")
        return nil
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "val4", v)
end
function dbbuilding:getval4()
    -- 值4。如:产量，仓库的存储量等
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "val4")
end

-- 把数据flush到mysql里， immd=true 立即生效
function dbbuilding:flush(immd)
    local sql
    if self.__isNew__ then
        sql = skynet.call("CLDB", "lua", "GETINSERTSQL", self.__name__, self:value2copy())
    else
        sql = skynet.call("CLDB", "lua", "GETUPDATESQL", self.__name__, self:value2copy())
    end
    return skynet.call("CLMySql", "lua", "save", sql, immd)
end

function dbbuilding:isEmpty()
    return (self.__key__ == nil) or (self:getidx() == nil)
end

function dbbuilding:release()
    skynet.call("CLDB", "lua", "SETUNUSE", self.__name__, self.__key__)
end

function dbbuilding:delete()
    skynet.call("CLDB", "lua", "SETUNUSE", self.__name__, self.__key__)
    skynet.call("CLDB", "lua", "REMOVE", self.__name__, self.__key__)
    local sql = skynet.call("CLDB", "lua", "GETDELETESQL", self.__name__, self:value2copy())
    return skynet.call("CLMySql", "lua", "EXESQL", sql)
end

function dbbuilding.querySql(idx, cidx)
    -- 如果某个参数为nil,则where条件中不包括该条件
    local where = {}
    if idx then
        table.insert(where, "`idx`=" .. idx)
    end
    if cidx then
        table.insert(where, "`cidx`=" .. "'" .. cidx  .. "'")
    end
    if #where > 0 then
        return "SELECT * FROM building WHERE " .. table.concat(where, " and ") .. ";"
    else
       return "SELECT * FROM building;"
    end
end

-- 取得一个组
function dbbuilding.getList(cidx, orderby, limitOffset, limitNum)
    local sql = "SELECT * FROM building WHERE cidx=" .. "'" .. cidx .. "'" ..  (orderby and " ORDER BY" ..  orderby or "") .. ((limitOffset and limitNum) and (" LIMIT " ..  limitOffset .. "," .. limitNum) or "") .. ";"
    local list = skynet.call("CLMySQL", "lua", "exesql", sql)
    if list and list.errno then
        skynet.error("[dbbuilding.getGroup] sql error==" .. sql)
        return nil
     end
     local cachlist = skynet.call("CLDB", "lua", "GETGROUP", dbbuilding.name, cidx) or {}
     for i, v in ipairs(list) do
         local key = v.idx
         local d = cachlist[key]
         if d ~= nil then
             -- 用缓存的数据才是最新的
             list[i] = d
             cachlist = nil
         end
     end
     for k ,v in pairs(cachlist) do
         table.insert(list, v)
     end
     return list
end

function dbbuilding.instanse(idx)
    if type(idx) == "table" then
        local d = idx
        idx = d.idx
    end
    if idx == nil then
        skynet.error("[dbbuilding.instanse] all input params == nil")
        return nil
    end
    local key = (idx or "")
    if key == "" then
        error("the key is null", 0)
    end
    ---@type dbbuilding
    local obj = dbbuilding.new()
    obj.__key__ = key
    local d = skynet.call("CLDB", "lua", "get", dbbuilding.name, key)
    if d == nil then
        d = skynet.call("CLMySQL", "lua", "exesql", dbbuilding.querySql(idx, nil))
        if d and d.errno == nil and #d > 0 then
            if #d == 1 then
                d = d[1]
                -- 取得mysql表里的数据
                obj.__isNew__ = false
                obj:init(d)
            else
                error("get data is more than one! count==" .. #d .. ", lua==dbbuilding")
            end
        else
            -- 没有数据
            obj.__isNew__ = true
        end
    else
        obj.__isNew__ = false
        skynet.call("CLDB", "lua", "SETUSE", dbbuilding.name, key)
    end
    return obj
end

------------------------------------
return dbbuilding
