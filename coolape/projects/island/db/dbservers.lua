require("class")
local skynet = require "skynet"

-- 服务器列表
dbservers = class("dbservers")

dbservers.name = "servers"

function dbservers:ctor(v)
    self.__name__ = "servers"    -- 表名
    self.__isNew__ = true    -- 新建数据，说明mysql表里没有数据
    self.__key__ = nil -- 缓存数据的key
end

function dbservers:init(data)
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

function dbservers:tablename() -- 取得表名
    return self.__name__
end

function dbservers:value2copy()  -- 取得数据复样，注意是只读的数据且只有当前时刻是最新的，如果要取得最新数据及修改数据，请用get、set
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__)
end

function dbservers:setidx(v)
    -- 唯一标识
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "idx", v)
end
function dbservers:getidx()
    -- 唯一标识
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "idx")
end

function dbservers:setappid(v)
    -- 应用id
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "appid", v)
end
function dbservers:getappid()
    -- 应用id
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "appid")
end

function dbservers:setchannel(v)
    -- 渠道id
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "channel", v)
end
function dbservers:getchannel()
    -- 渠道id
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "channel")
end

function dbservers:setname(v)
    -- 服务器名
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "name", v)
end
function dbservers:getname()
    -- 服务器名
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "name")
end

function dbservers:setstatus(v)
    -- 状态 0:正常; 1:爆满; 2:维护
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "status", v)
end
function dbservers:getstatus()
    -- 状态 0:正常; 1:爆满; 2:维护
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "status")
end

function dbservers:setisnew(v)
    -- 新服
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "isnew", v)
end
function dbservers:getisnew()
    -- 新服
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "isnew")
    if val == nil or val == 0 or val == false then
        return false
    else
        return true
    end
end

-- 把数据flush到mysql里， immd=true 立即生效
function dbservers:flush(immd)
    local sql
    if self.__isNew__ then
        sql = skynet.call("CLDB", "lua", "GETINSERTSQL", self.__name__, self:value2copy())
    else
        sql = skynet.call("CLDB", "lua", "GETUPDATESQL", self.__name__, self:value2copy())
    end
    return skynet.call("CLMySql", "lua", "save", sql, immd)
end

function dbservers:isEmpty()
    return (self.__key__ == nil) or (self:getidx() == nil)
end

function dbservers:release()
    skynet.call("CLDB", "lua", "SETTIMEOUT", self.__name__, self.__key__)
end

function dbservers.querySql(idx, appid, channel)
    -- 如果某个参数为nil,则where条件中不包括该条件
    local where = {}
    if idx then
        table.insert(where, "`idx`=" .. idx)
    end
    if appid then
        table.insert(where, "`appid`=" .. appid)
    end
    if channel then
        table.insert(where, "`channel`=" .. channel)
    end
    if #where > 0 then
        return "SELECT * FROM servers WHERE " .. table.concat(where, " and ") .. ";"
    else
       return "SELECT * FROM servers;"
    end
end

-- 取得一个组
function dbservers.getList(appid, orderby)
    local sql = "SELECT * FROM servers WHERE appid=" .. appid ..  (orderby and " ORDER BY" ..  orderby or "") .. ";"
    local list = skynet.call("CLMySQL", "lua", "exesql", sql)
    if list and list.errno then
        skynet.error("[dbservers.getGroup] sql error==" .. sql)
        return nil
     end
     for i, v in ipairs(list) do
         local key = v.idx
         local d = skynet.call("CLDB", "lua", "get", dbservers.name, key)
         if d ~= nil then
             -- 用缓存的数据才是最新的
             list[i] = d
         end
     end
     return list
end

function dbservers.instanse(idx)
    if idx == nil then
        skynet.error("[dbservers.instanse] idx == nil")
        return nil
    end
    local key = idx
    if key == "" then
        error("the key is null", 0)
    end
    ---@type dbservers
    local obj = dbservers.new()
    obj.__key__ = key
    local d = skynet.call("CLDB", "lua", "get", dbservers.name, key)
    if d == nil then
        d = skynet.call("CLMySQL", "lua", "exesql", dbservers.querySql(idx, nil, nil))
        if d and d.errno == nil and #d > 0 then
            if #d == 1 then
                d = d[1]
                -- 取得mysql表里的数据
                obj.__isNew__ = false
                obj:init(d)
            else
                error("get data is more than one! count==" .. #d .. ", lua==dbservers")
            end
        else
            -- 没有数据
            obj.__isNew__ = true
        end
    else
        obj.__isNew__ = false
        skynet.call("CLDB", "lua", "REMOVETIMEOUT", dbservers.name, key)
    end
    return obj
end

------------------------------------
return dbservers
