--[[
使用时特别注意：
1、常用方法如下，在不知道表里有没有数据时可以采用如下方法（可能会查询一次表）
    local obj＝ dbservers.instanse(idx);
    if obj:isEmpty() then
        -- 没有数据
    else
        -- 有数据
    end
2、使用如下用法时，程序会自动判断是否是insert还是update
    local obj＝ dbservers.new(data);
3、使用如下用法时，程序会自动判断是否是insert还是update
    local obj＝ dbservers.new();
    obj:init(data);
]]

require("class")
local skynet = require "skynet"
local tonumber = tonumber
require("dateEx")

-- 服务器列表
---@class dbservers : ClassBase
dbservers = class("dbservers")

dbservers.name = "servers"

dbservers.keys = {
    idx = "idx", -- 唯一标识
    appid = "appid", -- 应用id
    channel = "channel", -- 渠道id
    name = "name", -- 服务器名
    status = "status", -- 状态 1:正常; 2:爆满; 3:维护
    isnew = "isnew", -- 新服
    host = "host", -- ip
    port = "port", -- port
    androidVer = "androidVer", -- 客户端android版本
    iosVer = "iosVer", -- 客户端ios版本
    pcVer = "pcVer", -- 客户端PC版本
    macVer = "macVer", -- 客户端Mac版本
    note = "note", -- 备注说明
}

function dbservers:ctor(v)
    self.__name__ = "servers"    -- 表名
    self.__isNew__ = nil -- false:说明mysql里已经有数据了
    if v then
        self:init(v)
    end
end

function dbservers:init(data, isNew)
    data = dbservers.validData(data)
    self.__key__ = data.idx
    local hadCacheData = false
    if self.__isNew__ == nil and isNew == nil then
        local d = skynet.call("CLDB", "lua", "get", dbservers.name, self.__key__)
        if d == nil then
            d = skynet.call("CLMySQL", "lua", "exesql", dbservers.querySql(data.idx, nil, nil))
            if d and d.errno == nil and #d > 0 then
                self.__isNew__ = false
            else
                self.__isNew__ = true
            end
        else
            hadCacheData = true
            self.__isNew__ = false
        end
    else
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

function dbservers:tablename() -- 取得表名
    return self.__name__
end

function dbservers:value2copy()  -- 取得数据复样，注意是只读的数据且只有当前时刻是最新的，如果要取得最新数据及修改数据，请用get、set
    local ret = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__)
    if ret then
        ret.isnew = self:get_isnew()
    end
    return ret
end

function dbservers:refreshData(data)
    if data == nil or self.__key__ == nil then
        skynet.error("dbservers:refreshData error!")
        return
    end
    local orgData = self:value2copy()
    if orgData == nil then
        skynet.error("get old data error!!")
    end
    for k, v in pairs(data) do
        orgData[k] = v
    end
    orgData = dbservers.validData(orgData)
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, orgData)
end

function dbservers:set_idx(v)
    -- 唯一标识
    if self:isEmpty() then
        skynet.error("[dbservers:set_idx],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "idx", v)
end
function dbservers:get_idx()
    -- 唯一标识
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "idx")
    return (tonumber(val) or 0)
end

function dbservers:set_appid(v)
    -- 应用id
    if self:isEmpty() then
        skynet.error("[dbservers:set_appid],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "appid", v)
end
function dbservers:get_appid()
    -- 应用id
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "appid")
    return (tonumber(val) or 0)
end

function dbservers:set_channel(v)
    -- 渠道id
    if self:isEmpty() then
        skynet.error("[dbservers:set_channel],please init first!!")
        return nil
    end
    v = v or ""
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "channel", v)
end
function dbservers:get_channel()
    -- 渠道id
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "channel")
end

function dbservers:set_name(v)
    -- 服务器名
    if self:isEmpty() then
        skynet.error("[dbservers:set_name],please init first!!")
        return nil
    end
    v = v or ""
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "name", v)
end
function dbservers:get_name()
    -- 服务器名
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "name")
end

function dbservers:set_status(v)
    -- 状态 1:正常; 2:爆满; 3:维护
    if self:isEmpty() then
        skynet.error("[dbservers:set_status],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "status", v)
end
function dbservers:get_status()
    -- 状态 1:正常; 2:爆满; 3:维护
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "status")
    return (tonumber(val) or 0)
end

function dbservers:set_isnew(v)
    -- 新服
    if self:isEmpty() then
        skynet.error("[dbservers:set_isnew],please init first!!")
        return nil
    end
    local val = 0
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
    else
        val = 1
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "isnew", v)
end
function dbservers:get_isnew()
    -- 新服
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "isnew")
    if val == nil or val == 0 or val == false then
        return false
    else
        return true
    end
end

function dbservers:set_host(v)
    -- ip
    if self:isEmpty() then
        skynet.error("[dbservers:set_host],please init first!!")
        return nil
    end
    v = v or ""
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "host", v)
end
function dbservers:get_host()
    -- ip
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "host")
end

function dbservers:set_port(v)
    -- port
    if self:isEmpty() then
        skynet.error("[dbservers:set_port],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "port", v)
end
function dbservers:get_port()
    -- port
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "port")
    return (tonumber(val) or 0)
end

function dbservers:set_androidVer(v)
    -- 客户端android版本
    if self:isEmpty() then
        skynet.error("[dbservers:set_androidVer],please init first!!")
        return nil
    end
    v = v or ""
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "androidVer", v)
end
function dbservers:get_androidVer()
    -- 客户端android版本
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "androidVer")
end

function dbservers:set_iosVer(v)
    -- 客户端ios版本
    if self:isEmpty() then
        skynet.error("[dbservers:set_iosVer],please init first!!")
        return nil
    end
    v = v or ""
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "iosVer", v)
end
function dbservers:get_iosVer()
    -- 客户端ios版本
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "iosVer")
end

function dbservers:set_pcVer(v)
    -- 客户端PC版本
    if self:isEmpty() then
        skynet.error("[dbservers:set_pcVer],please init first!!")
        return nil
    end
    v = v or ""
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "pcVer", v)
end
function dbservers:get_pcVer()
    -- 客户端PC版本
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "pcVer")
end

function dbservers:set_macVer(v)
    -- 客户端Mac版本
    if self:isEmpty() then
        skynet.error("[dbservers:set_macVer],please init first!!")
        return nil
    end
    v = v or ""
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "macVer", v)
end
function dbservers:get_macVer()
    -- 客户端Mac版本
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "macVer")
end

function dbservers:set_note(v)
    -- 备注说明
    if self:isEmpty() then
        skynet.error("[dbservers:set_note],please init first!!")
        return nil
    end
    v = v or ""
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "note", v)
end
function dbservers:get_note()
    -- 备注说明
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "note")
end

-- 把数据flush到mysql里， immd=true 立即生效
function dbservers:flush(immd)
    local sql
    if self.__isNew__ then
        sql = skynet.call("CLDB", "lua", "GETINSERTSQL", self.__name__, self:value2copy())
        return skynet.call("CLMySQL", "lua", "exesql", sql, immd)
    else
        sql = skynet.call("CLDB", "lua", "GETUPDATESQL", self.__name__, self:value2copy())
        return skynet.call("CLMySQL", "lua", "save", sql, immd)
    end
end

function dbservers:isEmpty()
    return (self.__key__ == nil) or (self:get_idx() == nil)
end

function dbservers:release()
    skynet.call("CLDB", "lua", "SETUNUSE", self.__name__, self.__key__)
    self.__isNew__ = nil
    self.__key__ = nil
end

function dbservers:delete()
    local d = self:value2copy()
    skynet.call("CLDB", "lua", "SETUNUSE", self.__name__, self.__key__)
    skynet.call("CLDB", "lua", "REMOVE", self.__name__, self.__key__)
    local sql = skynet.call("CLDB", "lua", "GETDELETESQL", self.__name__, d)
    return skynet.call("CLMySQL", "lua", "exesql", sql)
end

---@public 设置触发器（当有数据改变时回调）
---@param server 触发回调服务地址
---@param cmd 触发回调服务方法
---@param fieldKey 字段key(可为nil)
function dbservers:setTrigger(server, cmd, fieldKey)
    skynet.call("CLDB", "lua", "ADDTRIGGER", self.__name__, self.__key__, server, cmd, fieldKey)
end

---@param server 触发回调服务地址
---@param cmd 触发回调服务方法
---@param fieldKey 字段key(可为nil)
function dbservers:unsetTrigger(server, cmd, fieldKey)
    skynet.call("CLDB", "lua", "REMOVETRIGGER", self.__name__, self.__key__, server, cmd, fieldKey)
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
        table.insert(where, "`channel`=" .. "'" .. channel  .. "'")
    end
    if #where > 0 then
        return "SELECT * FROM servers WHERE " .. table.concat(where, " and ") .. ";"
    else
       return "SELECT * FROM servers;"
    end
end

---@public 取得一个组
---@param forceSelect boolean 强制从mysql取数据
---@param orderby string 排序
function dbservers.getListByappid(appid, forceSelect, orderby, limitOffset, limitNum)
    if orderby and orderby ~= "" then
        forceSelect = true
    end
    local data
    local ret = {}
    local cachlist, isFullCached, list
    local groupInfor = skynet.call("CLDB", "lua", "GETGROUP", dbservers.name, appid) or {}
    cachlist = groupInfor[1] or {}
    isFullCached = groupInfor[2]
    if isFullCached == true and (not forceSelect) then
        list = cachlist
        for k, v in pairs(list) do
            data = dbservers.new(v, false)
            table.insert(ret, data:value2copy())
            data:release()
        end
    else
        local sql = "SELECT * FROM servers WHERE appid=" .. appid ..  (orderby and " ORDER BY" ..  orderby or "") .. ((limitOffset and limitNum) and (" LIMIT " ..  limitOffset .. "," .. limitNum) or "") .. ";"
        list = skynet.call("CLMySQL", "lua", "exesql", sql)
        if list and list.errno then
            skynet.error("[dbservers.getGroup] sql error==" .. sql)
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
             data = dbservers.new(v, false)
             ret[k] = data:value2copy()
             data:release()
         end
     end
     list = nil
     -- 设置当前缓存数据是全的数据
     skynet.call("CLDB", "lua", "SETGROUPISFULL", dbservers.name, appid)
     return ret
end

function dbservers.validData(data)
    if data == nil then return nil end

    if type(data.idx) ~= "number" then
        data.idx = tonumber(data.idx) or 0
    end
    if type(data.appid) ~= "number" then
        data.appid = tonumber(data.appid) or 0
    end
    if type(data.status) ~= "number" then
        data.status = tonumber(data.status) or 0
    end
    if type(data.isnew) == "string" then
        if data.isnew == "false" or data.isnew =="0" then
            data.isnew = 0
        else
            data.isnew = 1
        end
    elseif type(data.isnew) == "number" then
        if data.isnew == 0 then
            data.isnew = 0
        else
            data.isnew = 1
        end
    else
        data.isnew = 0
    end
    if type(data.port) ~= "number" then
        data.port = tonumber(data.port) or 0
    end
    return data
end

function dbservers.instanse(idx)
    if type(idx) == "table" then
        local d = idx
        idx = d.idx
    end
    if idx == nil then
        skynet.error("[dbservers.instanse] all input params == nil")
        return nil
    end
    local key = (idx or "")
    if key == "" then
        error("the key is null", 0)
    end
    ---@type dbservers
    local obj = dbservers.new()
    local d = skynet.call("CLDB", "lua", "get", dbservers.name, key)
    if d == nil then
        d = skynet.call("CLMySQL", "lua", "exesql", dbservers.querySql(idx, nil, nil))
        if d and d.errno == nil and #d > 0 then
            if #d == 1 then
                d = d[1]
                -- 取得mysql表里的数据
                obj.__isNew__ = false
                obj.__key__ = key
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
        obj.__key__ = key
        skynet.call("CLDB", "lua", "SETUSE", dbservers.name, key)
    end
    return obj
end

------------------------------------
return dbservers
