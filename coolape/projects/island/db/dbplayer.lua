--[[
使用时特别注意：
1、常用方法如下，在不知道表里有没有数据时可以采用如下方法（可能会查询一次表）
    local obj＝ dbplayer.instanse(idx);
    if obj:isEmpty() then
        -- 没有数据
    else
        -- 有数据
    end
2、使用如下用法时，程序会自动判断是否是insert还是update
    local obj＝ dbplayer.new(data);
3、使用如下用法时，程序会自动判断是否是insert还是update
    local obj＝ dbplayer.new();
    obj:init(data);
]]

require("class")
local skynet = require "skynet"
local tonumber = tonumber
require("dateEx")

-- 玩家表
---@class dbplayer : ClassBase
dbplayer = class("dbplayer")

dbplayer.name = "player"

dbplayer.keys = {
    idx = "idx", -- 唯一标识
    status = "status", -- 状态 1:正常;
    attacking = "attacking", -- 正在攻击玩家的岛屿
    beingattacked = "beingattacked", -- 正在被玩家攻击
    name = "name", -- 名称
    lev = "lev", -- 等级
    exp = "exp", -- 经验值
    money = "money", -- 充值总数
    diam = "diam", -- 钻石
    diam4reward = "diam4reward", -- 系统奖励钻石
    cityidx = "cityidx", -- 主城idx
    unionidx = "unionidx", -- 联盟idx
    crtTime = "crtTime", -- 创建时间
    lastEnTime = "lastEnTime", -- 最后登陆时间
    channel = "channel", -- 渠道
    deviceid = "deviceid", -- 机器id
}

function dbplayer:ctor(v)
    self.__name__ = "player"    -- 表名
    self.__isNew__ = nil -- false:说明mysql里已经有数据了
    if v then
        self:init(v)
    end
end

function dbplayer:init(data, isNew)
    data = dbplayer.validData(data)
    self.__key__ = data.idx
    local hadCacheData = false
    if self.__isNew__ == nil and isNew == nil then
        local d = skynet.call("CLDB", "lua", "get", dbplayer.name, self.__key__)
        if d == nil then
            d = skynet.call("CLMySQL", "lua", "exesql", dbplayer.querySql(data.idx, nil))
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

function dbplayer:tablename() -- 取得表名
    return self.__name__
end

function dbplayer:value2copy()  -- 取得数据复样，注意是只读的数据且只有当前时刻是最新的，如果要取得最新数据及修改数据，请用get、set
    local ret = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__)
    if ret then
        ret.attacking = self:get_attacking()
        ret.beingattacked = self:get_beingattacked()
        ret.crtTime = self:get_crtTime()
        ret.lastEnTime = self:get_lastEnTime()
    end
    return ret
end

function dbplayer:refreshData(data)
    if data == nil or self.__key__ == nil then
        skynet.error("dbplayer:refreshData error!")
        return
    end
    local orgData = self:value2copy()
    if orgData == nil then
        skynet.error("get old data error!!")
    end
    for k, v in pairs(data) do
        orgData[k] = v
    end
    orgData = dbplayer.validData(orgData)
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, orgData)
end

function dbplayer:set_idx(v)
    -- 唯一标识
    if self:isEmpty() then
        skynet.error("[dbplayer:set_idx],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "idx", v)
end
function dbplayer:get_idx()
    -- 唯一标识
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "idx")
    return (tonumber(val) or 0)
end

function dbplayer:set_status(v)
    -- 状态 1:正常;
    if self:isEmpty() then
        skynet.error("[dbplayer:set_status],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "status", v)
end
function dbplayer:get_status()
    -- 状态 1:正常;
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "status")
    return (tonumber(val) or 0)
end

function dbplayer:set_attacking(v)
    -- 正在攻击玩家的岛屿
    if self:isEmpty() then
        skynet.error("[dbplayer:set_attacking],please init first!!")
        return nil
    end
    if type(v) == "string" then
        if v == "false" or v =="0" then
            v = 0
        else
            v = 1
        end
    elseif type(v) == "number" then
        if v == 0 then
            v = 0
        else
            v = 1
        end
    elseif type(v) == "boolean" then
        if v then
            v = 1
        else
            v = 0
        end
    else
        v = 0
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "attacking", v)
end
function dbplayer:get_attacking()
    -- 正在攻击玩家的岛屿
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "attacking")
    if val == nil or val == 0 or val == false then
        return false
    else
        return true
    end
end

function dbplayer:set_beingattacked(v)
    -- 正在被玩家攻击
    if self:isEmpty() then
        skynet.error("[dbplayer:set_beingattacked],please init first!!")
        return nil
    end
    if type(v) == "string" then
        if v == "false" or v =="0" then
            v = 0
        else
            v = 1
        end
    elseif type(v) == "number" then
        if v == 0 then
            v = 0
        else
            v = 1
        end
    elseif type(v) == "boolean" then
        if v then
            v = 1
        else
            v = 0
        end
    else
        v = 0
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "beingattacked", v)
end
function dbplayer:get_beingattacked()
    -- 正在被玩家攻击
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "beingattacked")
    if val == nil or val == 0 or val == false then
        return false
    else
        return true
    end
end

function dbplayer:set_name(v)
    -- 名称
    if self:isEmpty() then
        skynet.error("[dbplayer:set_name],please init first!!")
        return nil
    end
    v = v or ""
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "name", v)
end
function dbplayer:get_name()
    -- 名称
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "name")
end

function dbplayer:set_lev(v)
    -- 等级
    if self:isEmpty() then
        skynet.error("[dbplayer:set_lev],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "lev", v)
end
function dbplayer:get_lev()
    -- 等级
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "lev")
    return (tonumber(val) or 0)
end

function dbplayer:set_exp(v)
    -- 经验值
    if self:isEmpty() then
        skynet.error("[dbplayer:set_exp],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "exp", v)
end
function dbplayer:get_exp()
    -- 经验值
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "exp")
    return (tonumber(val) or 0)
end

function dbplayer:set_money(v)
    -- 充值总数
    if self:isEmpty() then
        skynet.error("[dbplayer:set_money],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "money", v)
end
function dbplayer:get_money()
    -- 充值总数
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "money")
    return (tonumber(val) or 0)
end

function dbplayer:set_diam(v)
    -- 钻石
    if self:isEmpty() then
        skynet.error("[dbplayer:set_diam],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "diam", v)
end
function dbplayer:get_diam()
    -- 钻石
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "diam")
    return (tonumber(val) or 0)
end

function dbplayer:set_diam4reward(v)
    -- 系统奖励钻石
    if self:isEmpty() then
        skynet.error("[dbplayer:set_diam4reward],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "diam4reward", v)
end
function dbplayer:get_diam4reward()
    -- 系统奖励钻石
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "diam4reward")
    return (tonumber(val) or 0)
end

function dbplayer:set_cityidx(v)
    -- 主城idx
    if self:isEmpty() then
        skynet.error("[dbplayer:set_cityidx],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "cityidx", v)
end
function dbplayer:get_cityidx()
    -- 主城idx
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "cityidx")
    return (tonumber(val) or 0)
end

function dbplayer:set_unionidx(v)
    -- 联盟idx
    if self:isEmpty() then
        skynet.error("[dbplayer:set_unionidx],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "unionidx", v)
end
function dbplayer:get_unionidx()
    -- 联盟idx
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "unionidx")
    return (tonumber(val) or 0)
end

function dbplayer:set_crtTime(v)
    -- 创建时间
    if self:isEmpty() then
        skynet.error("[dbplayer:set_crtTime],please init first!!")
        return nil
    end
    if type(v) == "number" then
        v = dateEx.seconds2Str(v/1000)
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "crtTime", v)
end
function dbplayer:get_crtTime()
    -- 创建时间
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "crtTime")
    if type(val) == "string" then
        return dateEx.str2Seconds(val)*1000 -- 转成毫秒
    else
        return val
    end
end

function dbplayer:set_lastEnTime(v)
    -- 最后登陆时间
    if self:isEmpty() then
        skynet.error("[dbplayer:set_lastEnTime],please init first!!")
        return nil
    end
    if type(v) == "number" then
        v = dateEx.seconds2Str(v/1000)
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "lastEnTime", v)
end
function dbplayer:get_lastEnTime()
    -- 最后登陆时间
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "lastEnTime")
    if type(val) == "string" then
        return dateEx.str2Seconds(val)*1000 -- 转成毫秒
    else
        return val
    end
end

function dbplayer:set_channel(v)
    -- 渠道
    if self:isEmpty() then
        skynet.error("[dbplayer:set_channel],please init first!!")
        return nil
    end
    v = v or ""
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "channel", v)
end
function dbplayer:get_channel()
    -- 渠道
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "channel")
end

function dbplayer:set_deviceid(v)
    -- 机器id
    if self:isEmpty() then
        skynet.error("[dbplayer:set_deviceid],please init first!!")
        return nil
    end
    v = v or ""
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "deviceid", v)
end
function dbplayer:get_deviceid()
    -- 机器id
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "deviceid")
end

-- 把数据flush到mysql里， immd=true 立即生效
function dbplayer:flush(immd)
    local sql
    if self.__isNew__ then
        sql = skynet.call("CLDB", "lua", "GETINSERTSQL", self.__name__, self:value2copy())
        return skynet.call("CLMySQL", "lua", "exesql", sql, immd)
    else
        sql = skynet.call("CLDB", "lua", "GETUPDATESQL", self.__name__, self:value2copy())
        return skynet.call("CLMySQL", "lua", "save", sql, immd)
    end
end

function dbplayer:isEmpty()
    return (self.__key__ == nil) or (self:get_idx() == nil)
end

function dbplayer:release()
    skynet.call("CLDB", "lua", "SETUNUSE", self.__name__, self.__key__)
    self.__isNew__ = nil
    self.__key__ = nil
end

function dbplayer:delete()
    local d = self:value2copy()
    skynet.call("CLDB", "lua", "SETUNUSE", self.__name__, self.__key__)
    skynet.call("CLDB", "lua", "REMOVE", self.__name__, self.__key__)
    local sql = skynet.call("CLDB", "lua", "GETDELETESQL", self.__name__, d)
    self.__key__ = nil
    return skynet.call("CLMySQL", "lua", "exesql", sql)
end

---@public 设置触发器（当有数据改变时回调）
---@param server 触发回调服务地址
---@param cmd 触发回调服务方法
---@param fieldKey 字段key(可为nil)
function dbplayer:setTrigger(server, cmd, fieldKey)
    skynet.call("CLDB", "lua", "ADDTRIGGER", self.__name__, self.__key__, server, cmd, fieldKey)
end

---@param server 触发回调服务地址
---@param cmd 触发回调服务方法
---@param fieldKey 字段key(可为nil)
function dbplayer:unsetTrigger(server, cmd, fieldKey)
    skynet.call("CLDB", "lua", "REMOVETRIGGER", self.__name__, self.__key__, server, cmd, fieldKey)
end

function dbplayer.querySql(idx, name)
    -- 如果某个参数为nil,则where条件中不包括该条件
    local where = {}
    if idx then
        table.insert(where, "`idx`=" .. idx)
    end
    if name then
        table.insert(where, "`name`=" .. "'" .. name  .. "'")
    end
    if #where > 0 then
        return "SELECT * FROM player WHERE " .. table.concat(where, " and ") .. ";"
    else
       return "SELECT * FROM player;"
    end
end

function dbplayer.validData(data)
    if data == nil then return nil end

    if type(data.idx) ~= "number" then
        data.idx = tonumber(data.idx) or 0
    end
    if type(data.status) ~= "number" then
        data.status = tonumber(data.status) or 0
    end
    if type(data.attacking) == "string" then
        if data.attacking == "false" or data.attacking =="0" then
            data.attacking = 0
        else
            data.attacking = 1
        end
    elseif type(data.attacking) == "number" then
        if data.attacking == 0 then
            data.attacking = 0
        else
            data.attacking = 1
        end
    else
        data.attacking = 0
    end
    if type(data.beingattacked) == "string" then
        if data.beingattacked == "false" or data.beingattacked =="0" then
            data.beingattacked = 0
        else
            data.beingattacked = 1
        end
    elseif type(data.beingattacked) == "number" then
        if data.beingattacked == 0 then
            data.beingattacked = 0
        else
            data.beingattacked = 1
        end
    else
        data.beingattacked = 0
    end
    if type(data.lev) ~= "number" then
        data.lev = tonumber(data.lev) or 0
    end
    if type(data.exp) ~= "number" then
        data.exp = tonumber(data.exp) or 0
    end
    if type(data.money) ~= "number" then
        data.money = tonumber(data.money) or 0
    end
    if type(data.diam) ~= "number" then
        data.diam = tonumber(data.diam) or 0
    end
    if type(data.diam4reward) ~= "number" then
        data.diam4reward = tonumber(data.diam4reward) or 0
    end
    if type(data.cityidx) ~= "number" then
        data.cityidx = tonumber(data.cityidx) or 0
    end
    if type(data.unionidx) ~= "number" then
        data.unionidx = tonumber(data.unionidx) or 0
    end
    if type(data.crtTime) == "number" then
        data.crtTime = dateEx.seconds2Str(data.crtTime/1000)
    end
    if type(data.lastEnTime) == "number" then
        data.lastEnTime = dateEx.seconds2Str(data.lastEnTime/1000)
    end
    return data
end

function dbplayer.instanse(idx)
    if type(idx) == "table" then
        local d = idx
        idx = d.idx
    end
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
    local d = skynet.call("CLDB", "lua", "get", dbplayer.name, key)
    if d == nil then
        d = skynet.call("CLMySQL", "lua", "exesql", dbplayer.querySql(idx, nil))
        if d and d.errno == nil and #d > 0 then
            if #d == 1 then
                d = d[1]
                -- 取得mysql表里的数据
                obj.__isNew__ = false
                obj.__key__ = key
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
        obj.__key__ = key
        skynet.call("CLDB", "lua", "SETUSE", dbplayer.name, key)
    end
    return obj
end

------------------------------------
return dbplayer
