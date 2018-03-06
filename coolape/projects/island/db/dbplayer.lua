--[[
使用时特别注意：
1、常用方法如下，在不知道表里有没有数据时可以采用如下方法（可能会查询一次表）
    local obj＝ dbplayer.instanse(idx);
    if obj:isEmpty() then
        -- 没有数据
    else
        -- 有数据
    end
2、使用如下用法时，程序认为mysql已经有数据了，只会做更新操作
    local obj＝ dbplayer.new(data);
3、使用如下用法时，程序认为mysql没有数据，会插入一条记录到表
    local obj＝ dbplayer.new();
    obj:init(data);
]]

require("class")
local skynet = require "skynet"

-- 玩家表
---@class dbplayer
dbplayer = class("dbplayer")

dbplayer.name = "player"

function dbplayer:ctor(v)
    self.__name__ = "player"    -- 表名
    if v then
        self.__isNew__ = false -- 说明mysql里已经有数据了
        self:init(v)
    else
        self.__isNew__ = true    -- 新建数据，说明mysql表里没有数据
        self.__key__ = nil -- 缓存数据的key
    end
end

function dbplayer:init(data)
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

function dbplayer:tablename() -- 取得表名
    return self.__name__
end

function dbplayer:value2copy()  -- 取得数据复样，注意是只读的数据且只有当前时刻是最新的，如果要取得最新数据及修改数据，请用get、set
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__)
end

function dbplayer:setidx(v)
    -- 唯一标识
    if self:isEmpty() then
        skynet.error("[dbplayer:setidx],please init first!!")
        return nil
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "idx", v)
end
function dbplayer:getidx()
    -- 唯一标识
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "idx")
end

function dbplayer:setstatus(v)
    -- 状态 1:正常;
    if self:isEmpty() then
        skynet.error("[dbplayer:setstatus],please init first!!")
        return nil
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "status", v)
end
function dbplayer:getstatus()
    -- 状态 1:正常;
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "status")
end

function dbplayer:setname(v)
    -- 名称
    if self:isEmpty() then
        skynet.error("[dbplayer:setname],please init first!!")
        return nil
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "name", v)
end
function dbplayer:getname()
    -- 名称
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "name")
end

function dbplayer:setlev(v)
    -- 等级
    if self:isEmpty() then
        skynet.error("[dbplayer:setlev],please init first!!")
        return nil
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "lev", v)
end
function dbplayer:getlev()
    -- 等级
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "lev")
end

function dbplayer:setmoney(v)
    -- 充值总数
    if self:isEmpty() then
        skynet.error("[dbplayer:setmoney],please init first!!")
        return nil
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "money", v)
end
function dbplayer:getmoney()
    -- 充值总数
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "money")
end

function dbplayer:setdiam(v)
    -- 钻石
    if self:isEmpty() then
        skynet.error("[dbplayer:setdiam],please init first!!")
        return nil
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "diam", v)
end
function dbplayer:getdiam()
    -- 钻石
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "diam")
end

function dbplayer:setcityidx(v)
    -- 主城idx
    if self:isEmpty() then
        skynet.error("[dbplayer:setcityidx],please init first!!")
        return nil
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "cityidx", v)
end
function dbplayer:getcityidx()
    -- 主城idx
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "cityidx")
end

function dbplayer:setunionidx(v)
    -- 联盟idx
    if self:isEmpty() then
        skynet.error("[dbplayer:setunionidx],please init first!!")
        return nil
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "unionidx", v)
end
function dbplayer:getunionidx()
    -- 联盟idx
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "unionidx")
end

function dbplayer:setcrtTime(v)
    -- 创建时间
    if self:isEmpty() then
        skynet.error("[dbplayer:setcrtTime],please init first!!")
        return nil
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "crtTime", v)
end
function dbplayer:getcrtTime()
    -- 创建时间
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "crtTime")
end

function dbplayer:setlastEnTime(v)
    -- 最后登陆时间
    if self:isEmpty() then
        skynet.error("[dbplayer:setlastEnTime],please init first!!")
        return nil
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "lastEnTime", v)
end
function dbplayer:getlastEnTime()
    -- 最后登陆时间
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "lastEnTime")
end

function dbplayer:setchannel(v)
    -- 渠道
    if self:isEmpty() then
        skynet.error("[dbplayer:setchannel],please init first!!")
        return nil
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "channel", v)
end
function dbplayer:getchannel()
    -- 渠道
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "channel")
end

function dbplayer:setdeviceid(v)
    -- 机器id
    if self:isEmpty() then
        skynet.error("[dbplayer:setdeviceid],please init first!!")
        return nil
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "deviceid", v)
end
function dbplayer:getdeviceid()
    -- 机器id
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "deviceid")
end

-- 把数据flush到mysql里， immd=true 立即生效
function dbplayer:flush(immd)
    local sql
    if self.__isNew__ then
        sql = skynet.call("CLDB", "lua", "GETINSERTSQL", self.__name__, self:value2copy())
    else
        sql = skynet.call("CLDB", "lua", "GETUPDATESQL", self.__name__, self:value2copy())
    end
    return skynet.call("CLMySql", "lua", "save", sql, immd)
end

function dbplayer:isEmpty()
    return (self.__key__ == nil) or (self:getidx() == nil)
end

function dbplayer:release()
    skynet.call("CLDB", "lua", "SETUNUSE", self.__name__, self.__key__)
end

function dbplayer:delete()
    skynet.call("CLDB", "lua", "SETUNUSE", self.__name__, self.__key__)
    skynet.call("CLDB", "lua", "REMOVE", self.__name__, self.__key__)
    local sql = skynet.call("CLDB", "lua", "GETDELETESQL", self.__name__, self:value2copy())
    return skynet.call("CLMySql", "lua", "EXESQL", sql)
end

function dbplayer.querySql(idx)
    -- 如果某个参数为nil,则where条件中不包括该条件
    local where = {}
    if idx then
        table.insert(where, "`idx`=" .. idx)
    end
    if #where > 0 then
        return "SELECT * FROM player WHERE " .. table.concat(where, " and ") .. ";"
    else
       return "SELECT * FROM player;"
    end
end

function dbplayer.instanse(idx)
    if idx == nil then
        skynet.error("[dbplayer.instanse] all input params == nil")
        return nil
    end
    local key = (idx or "")
    if key == "" then
        error("the key is null", 0)
    end
    ---@type dbplayer
    local obj = dbplayer.new()
    obj.__key__ = key
    local d = skynet.call("CLDB", "lua", "get", dbplayer.name, key)
    if d == nil then
        d = skynet.call("CLMySQL", "lua", "exesql", dbplayer.querySql(idx))
        if d and d.errno == nil and #d > 0 then
            if #d == 1 then
                d = d[1]
                -- 取得mysql表里的数据
                obj.__isNew__ = false
                obj:init(d)
            else
                error("get data is more than one! count==" .. #d .. ", lua==dbplayer")
            end
        else
            -- 没有数据
            obj.__isNew__ = true
        end
    else
        obj.__isNew__ = false
        skynet.call("CLDB", "lua", "SETUSE", dbplayer.name, key)
    end
    return obj
end

------------------------------------
return dbplayer
