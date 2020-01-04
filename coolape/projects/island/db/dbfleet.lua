--[[
使用时特别注意：
1、常用方法如下，在不知道表里有没有数据时可以采用如下方法（可能会查询一次表）
    local obj＝ dbfleet.instanse(idx);
    if obj:isEmpty() then
        -- 没有数据
    else
        -- 有数据
    end
2、使用如下用法时，程序会自动判断是否是insert还是update
    local obj＝ dbfleet.new(data);
3、使用如下用法时，程序会自动判断是否是insert还是update
    local obj＝ dbfleet.new();
    obj:init(data);
]]

require("class")
local skynet = require "skynet"
local tonumber = tonumber
require("dateEx")

-- 舰队
---@class dbfleet : ClassBase
dbfleet = class("dbfleet")

dbfleet.name = "fleet"

dbfleet.keys = {
    idx = "idx", -- 唯一标识
    cidx = "cidx", -- 城市idx
    name = "name", -- 名称
    curpos = "curpos", -- 当前所在世界grid的index
    frompos = "frompos", -- 出征的开始所在世界grid的index
    topos = "topos", -- 出征的目地所在世界grid的index
    task = "task", -- 执行任务类型 idel = 1, -- 待命状态;voyage = 2, -- 出征;back = 3, -- 返航;attack = 4 -- 攻击
    status = "status", -- 状态 none = 1, -- 无;moving = 2, -- 航行中;docked = 3, -- 停泊在港口;stay = 4, -- 停留在海面;fighting = 5 -- 正在战斗中
    arrivetime = "arrivetime", -- 到达时间
    deadtime = "deadtime", -- 沉没的时间
}

function dbfleet:ctor(v)
    self.__name__ = "fleet"    -- 表名
    self.__isNew__ = nil -- false:说明mysql里已经有数据了
    if v then
        self:init(v)
    end
end

function dbfleet:init(data, isNew)
    data = dbfleet.validData(data)
    self.__key__ = data.idx
    local hadCacheData = false
    if self.__isNew__ == nil and isNew == nil then
        local d = skynet.call("CLDB", "lua", "get", dbfleet.name, self.__key__)
        if d == nil then
            d = skynet.call("CLMySQL", "lua", "exesql", dbfleet.querySql(data.idx, nil))
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

function dbfleet:tablename() -- 取得表名
    return self.__name__
end

function dbfleet:value2copy()  -- 取得数据复样，注意是只读的数据且只有当前时刻是最新的，如果要取得最新数据及修改数据，请用get、set
    local ret = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__)
    if ret then
        ret.arrivetime = self:get_arrivetime()
        ret.deadtime = self:get_deadtime()
    end
    return ret
end

function dbfleet:refreshData(data)
    if data == nil or self.__key__ == nil then
        skynet.error("dbfleet:refreshData error!")
        return
    end
    local orgData = self:value2copy()
    if orgData == nil then
        skynet.error("get old data error!!")
    end
    for k, v in pairs(data) do
        orgData[k] = v
    end
    orgData = dbfleet.validData(orgData)
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, orgData)
end

function dbfleet:set_idx(v)
    -- 唯一标识
    if self:isEmpty() then
        skynet.error("[dbfleet:set_idx],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "idx", v)
end
function dbfleet:get_idx()
    -- 唯一标识
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "idx")
    return (tonumber(val) or 0)
end

function dbfleet:set_cidx(v)
    -- 城市idx
    if self:isEmpty() then
        skynet.error("[dbfleet:set_cidx],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "cidx", v)
end
function dbfleet:get_cidx()
    -- 城市idx
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "cidx")
    return (tonumber(val) or 0)
end

function dbfleet:set_name(v)
    -- 名称
    if self:isEmpty() then
        skynet.error("[dbfleet:set_name],please init first!!")
        return nil
    end
    v = v or ""
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "name", v)
end
function dbfleet:get_name()
    -- 名称
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "name")
end

function dbfleet:set_curpos(v)
    -- 当前所在世界grid的index
    if self:isEmpty() then
        skynet.error("[dbfleet:set_curpos],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "curpos", v)
end
function dbfleet:get_curpos()
    -- 当前所在世界grid的index
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "curpos")
    return (tonumber(val) or 0)
end

function dbfleet:set_frompos(v)
    -- 出征的开始所在世界grid的index
    if self:isEmpty() then
        skynet.error("[dbfleet:set_frompos],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "frompos", v)
end
function dbfleet:get_frompos()
    -- 出征的开始所在世界grid的index
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "frompos")
    return (tonumber(val) or 0)
end

function dbfleet:set_topos(v)
    -- 出征的目地所在世界grid的index
    if self:isEmpty() then
        skynet.error("[dbfleet:set_topos],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "topos", v)
end
function dbfleet:get_topos()
    -- 出征的目地所在世界grid的index
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "topos")
    return (tonumber(val) or 0)
end

function dbfleet:set_task(v)
    -- 执行任务类型 idel = 1, -- 待命状态;voyage = 2, -- 出征;back = 3, -- 返航;attack = 4 -- 攻击
    if self:isEmpty() then
        skynet.error("[dbfleet:set_task],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "task", v)
end
function dbfleet:get_task()
    -- 执行任务类型 idel = 1, -- 待命状态;voyage = 2, -- 出征;back = 3, -- 返航;attack = 4 -- 攻击
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "task")
    return (tonumber(val) or 0)
end

function dbfleet:set_status(v)
    -- 状态 none = 1, -- 无;moving = 2, -- 航行中;docked = 3, -- 停泊在港口;stay = 4, -- 停留在海面;fighting = 5 -- 正在战斗中
    if self:isEmpty() then
        skynet.error("[dbfleet:set_status],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "status", v)
end
function dbfleet:get_status()
    -- 状态 none = 1, -- 无;moving = 2, -- 航行中;docked = 3, -- 停泊在港口;stay = 4, -- 停留在海面;fighting = 5 -- 正在战斗中
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "status")
    return (tonumber(val) or 0)
end

function dbfleet:set_arrivetime(v)
    -- 到达时间
    if self:isEmpty() then
        skynet.error("[dbfleet:set_arrivetime],please init first!!")
        return nil
    end
    if type(v) == "number" then
        v = dateEx.seconds2Str(v/1000)
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "arrivetime", v)
end
function dbfleet:get_arrivetime()
    -- 到达时间
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "arrivetime")
    if type(val) == "string" then
        return dateEx.str2Seconds(val)*1000 -- 转成毫秒
    else
        return val
    end
end

function dbfleet:set_deadtime(v)
    -- 沉没的时间
    if self:isEmpty() then
        skynet.error("[dbfleet:set_deadtime],please init first!!")
        return nil
    end
    if type(v) == "number" then
        v = dateEx.seconds2Str(v/1000)
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "deadtime", v)
end
function dbfleet:get_deadtime()
    -- 沉没的时间
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "deadtime")
    if type(val) == "string" then
        return dateEx.str2Seconds(val)*1000 -- 转成毫秒
    else
        return val
    end
end

-- 把数据flush到mysql里， immd=true 立即生效
function dbfleet:flush(immd)
    local sql
    if self.__isNew__ then
        sql = skynet.call("CLDB", "lua", "GETINSERTSQL", self.__name__, self:value2copy())
        return skynet.call("CLMySQL", "lua", "exesql", sql, immd)
    else
        sql = skynet.call("CLDB", "lua", "GETUPDATESQL", self.__name__, self:value2copy())
        return skynet.call("CLMySQL", "lua", "save", sql, immd)
    end
end

function dbfleet:isEmpty()
    return (self.__key__ == nil) or (self:get_idx() == nil)
end

function dbfleet:release()
    skynet.call("CLDB", "lua", "SETUNUSE", self.__name__, self.__key__)
    self.__isNew__ = nil
    self.__key__ = nil
end

function dbfleet:delete()
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
function dbfleet:setTrigger(server, cmd, fieldKey)
    skynet.call("CLDB", "lua", "ADDTRIGGER", self.__name__, self.__key__, server, cmd, fieldKey)
end

---@param server 触发回调服务地址
---@param cmd 触发回调服务方法
---@param fieldKey 字段key(可为nil)
function dbfleet:unsetTrigger(server, cmd, fieldKey)
    skynet.call("CLDB", "lua", "REMOVETRIGGER", self.__name__, self.__key__, server, cmd, fieldKey)
end

function dbfleet.querySql(idx, cidx)
    -- 如果某个参数为nil,则where条件中不包括该条件
    local where = {}
    if idx then
        table.insert(where, "`idx`=" .. idx)
    end
    if cidx then
        table.insert(where, "`cidx`=" .. cidx)
    end
    if #where > 0 then
        return "SELECT * FROM fleet WHERE " .. table.concat(where, " and ") .. ";"
    else
       return "SELECT * FROM fleet;"
    end
end

---@public 取得一个组
---@param forceSelect boolean 强制从mysql取数据
---@param orderby string 排序
function dbfleet.getListBycidx(cidx, forceSelect, orderby, limitOffset, limitNum)
    if orderby and orderby ~= "" then
        forceSelect = true
    end
    local data
    local ret = {}
    local cachlist, isFullCached, list
    local groupInfor = skynet.call("CLDB", "lua", "GETGROUP", dbfleet.name, cidx) or {}
    cachlist = groupInfor[1] or {}
    isFullCached = groupInfor[2]
    if isFullCached == true and (not forceSelect) then
        list = cachlist
        for k, v in pairs(list) do
            data = dbfleet.new(v, false)
            table.insert(ret, data:value2copy())
            data:release()
        end
    else
        local sql = "SELECT * FROM fleet WHERE cidx=" .. cidx ..  (orderby and " ORDER BY" ..  orderby or "") .. ((limitOffset and limitNum) and (" LIMIT " ..  limitOffset .. "," .. limitNum) or "") .. ";"
        list = skynet.call("CLMySQL", "lua", "exesql", sql)
        if list and list.errno then
            skynet.error("[dbfleet.getGroup] sql error==" .. sql)
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
             data = dbfleet.new(v, false)
             ret[k] = data:value2copy()
             data:release()
         end
     end
     list = nil
     -- 设置当前缓存数据是全的数据
     skynet.call("CLDB", "lua", "SETGROUPISFULL", dbfleet.name, cidx)
     return ret
end

function dbfleet.validData(data)
    if data == nil then return nil end

    if type(data.idx) ~= "number" then
        data.idx = tonumber(data.idx) or 0
    end
    if type(data.cidx) ~= "number" then
        data.cidx = tonumber(data.cidx) or 0
    end
    if type(data.curpos) ~= "number" then
        data.curpos = tonumber(data.curpos) or 0
    end
    if type(data.frompos) ~= "number" then
        data.frompos = tonumber(data.frompos) or 0
    end
    if type(data.topos) ~= "number" then
        data.topos = tonumber(data.topos) or 0
    end
    if type(data.task) ~= "number" then
        data.task = tonumber(data.task) or 0
    end
    if type(data.status) ~= "number" then
        data.status = tonumber(data.status) or 0
    end
    if type(data.arrivetime) == "number" then
        data.arrivetime = dateEx.seconds2Str(data.arrivetime/1000)
    end
    if type(data.deadtime) == "number" then
        data.deadtime = dateEx.seconds2Str(data.deadtime/1000)
    end
    return data
end

function dbfleet.instanse(idx)
    if type(idx) == "table" then
        local d = idx
        idx = d.idx
    end
    if idx == nil then
        skynet.error("[dbfleet.instanse] all input params == nil")
        return nil
    end
    local key = (idx or "")
    if key == "" then
        error("the key is null", 0)
    end
    ---@type dbfleet
    local obj = dbfleet.new()
    local d = skynet.call("CLDB", "lua", "get", dbfleet.name, key)
    if d == nil then
        d = skynet.call("CLMySQL", "lua", "exesql", dbfleet.querySql(idx, nil))
        if d and d.errno == nil and #d > 0 then
            if #d == 1 then
                d = d[1]
                -- 取得mysql表里的数据
                obj.__isNew__ = false
                obj.__key__ = key
                obj:init(d)
            else
                error("get data is more than one! count==" .. #d .. ", lua==dbfleet")
            end
        else
            -- 没有数据
            obj.__isNew__ = true
        end
    else
        obj.__isNew__ = false
        obj.__key__ = key
        skynet.call("CLDB", "lua", "SETUSE", dbfleet.name, key)
    end
    return obj
end

------------------------------------
return dbfleet
