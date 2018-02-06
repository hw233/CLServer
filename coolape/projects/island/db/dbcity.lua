require("class")
local skynet = require "skynet"

-- 主城表
dbcity = class("dbcity")

dbcity.name = "city"

function dbcity:ctor(v)
    self.__name__ = "city"    -- 表名
    self.__isNew__ = true    -- 新建数据，说明mysql表里没有数据
    self.__key__ = nil -- 缓存数据的key
end

function dbcity:init(data)
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
    skynet.call("CLDB", "lua", "REMOVETIMEOUT", self.__name__, self.__key__)
    return true
end

function dbcity:tablename() -- 取得表名
    return self.__name__
end

function dbcity:value2copy()  -- 取得数据复样，注意是只读的数据且只有当前时刻是最新的，如果要取得最新数据及修改数据，请用get、set
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__)
end

function dbcity:setidx(v)
    -- 唯一标识
    if self:isEmpty() then
        skynet.error("[dbcity:setidx],please init first!!")
        return nil
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "idx", v)
end
function dbcity:getidx()
    -- 唯一标识
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "idx")
end

function dbcity:setname(v)
    -- 名称
    if self:isEmpty() then
        skynet.error("[dbcity:setname],please init first!!")
        return nil
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "name", v)
end
function dbcity:getname()
    -- 名称
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "name")
end

function dbcity:setpidx(v)
    -- 玩家idx
    if self:isEmpty() then
        skynet.error("[dbcity:setpidx],please init first!!")
        return nil
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "pidx", v)
end
function dbcity:getpidx()
    -- 玩家idx
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "pidx")
end

function dbcity:setpos(v)
    -- 城所在世界grid的index
    if self:isEmpty() then
        skynet.error("[dbcity:setpos],please init first!!")
        return nil
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "pos", v)
end
function dbcity:getpos()
    -- 城所在世界grid的index
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "pos")
end

function dbcity:setstatus(v)
    -- 状态 1:正常;
    if self:isEmpty() then
        skynet.error("[dbcity:setstatus],please init first!!")
        return nil
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "status", v)
end
function dbcity:getstatus()
    -- 状态 1:正常;
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "status")
end

function dbcity:setlev(v)
    -- 等级
    if self:isEmpty() then
        skynet.error("[dbcity:setlev],please init first!!")
        return nil
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "lev", v)
end
function dbcity:getlev()
    -- 等级
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "lev")
end

-- 把数据flush到mysql里， immd=true 立即生效
function dbcity:flush(immd)
    local sql
    if self.__isNew__ then
        sql = skynet.call("CLDB", "lua", "GETINSERTSQL", self.__name__, self:value2copy())
    else
        sql = skynet.call("CLDB", "lua", "GETUPDATESQL", self.__name__, self:value2copy())
    end
    return skynet.call("CLMySql", "lua", "save", sql, immd)
end

function dbcity:isEmpty()
    return (self.__key__ == nil) or (self:getidx() == nil)
end

function dbcity:release()
    skynet.call("CLDB", "lua", "SETTIMEOUT", self.__name__, self.__key__)
end

function dbcity.querySql(idx, pidx)
    -- 如果某个参数为nil,则where条件中不包括该条件
    local where = {}
    if idx then
        table.insert(where, "`idx`=" .. idx)
    end
    if pidx then
        table.insert(where, "`pidx`=" .. "'" .. pidx  .. "'")
    end
    if #where > 0 then
        return "SELECT * FROM city WHERE " .. table.concat(where, " and ") .. ";"
    else
       return "SELECT * FROM city;"
    end
end

-- 取得一个组
function dbservers.getList(pidx, orderby)
    local sql = "SELECT * FROM servers WHERE pidx=" .. "'" .. pidx .. "'" ..  (orderby and " ORDER BY" ..  orderby or "") .. ";"
    local list = skynet.call("CLMySQL", "lua", "exesql", sql)
    if list and list.errno then
        skynet.error("[dbcity.getGroup] sql error==" .. sql)
        return nil
     end
     for i, v in ipairs(list) do
         local key = v.idx
         local d = skynet.call("CLDB", "lua", "get", dbcity.name, key)
         if d ~= nil then
             -- 用缓存的数据才是最新的
             list[i] = d
         end
     end
     return list
end

function dbcity.instanse(idx)
    if idx == nil then
        skynet.error("[dbcity.instanse] all input params == nil")
        return nil
    end
    local key = (idx or "")
    if key == "" then
        error("the key is null", 0)
    end
    ---@type dbcity
    local obj = dbcity.new()
    obj.__key__ = key
    local d = skynet.call("CLDB", "lua", "get", dbcity.name, key)
    if d == nil then
        d = skynet.call("CLMySQL", "lua", "exesql", dbcity.querySql(idx, nil))
        if d and d.errno == nil and #d > 0 then
            if #d == 1 then
                d = d[1]
                -- 取得mysql表里的数据
                obj.__isNew__ = false
                obj:init(d)
            else
                error("get data is more than one! count==" .. #d .. ", lua==dbcity")
            end
        else
            -- 没有数据
            obj.__isNew__ = true
        end
    else
        obj.__isNew__ = false
        skynet.call("CLDB", "lua", "REMOVETIMEOUT", dbcity.name, key)
    end
    return obj
end

------------------------------------
return dbcity
