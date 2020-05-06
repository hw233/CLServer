--[[
使用时特别注意：
1、常用方法如下，在不知道表里有没有数据时可以采用如下方法（可能会查询一次表）
    local obj＝ dbmail.instanse(idx);
    if obj:isEmpty() then
        -- 没有数据
    else
        -- 有数据
    end
2、使用如下用法时，程序会自动判断是否是insert还是update
    local obj＝ dbmail.new(data);
3、使用如下用法时，程序会自动判断是否是insert还是update
    local obj＝ dbmail.new();
    obj:init(data);
]]

require("class")
local skynet = require "skynet"
local tonumber = tonumber
require("dateEx")

-- 邮件表
---@class dbmail : ClassBase
dbmail = class("dbmail")

dbmail.name = "mail"

dbmail.keys = {
    idx = "idx", -- 唯一标识
    parent = "parent", -- 父idx(其实就是邮件的idx，回复的邮件指向的主邮件的idx)
    type = "type", -- 类型，1：系统，2：战报；3：私信，4:联盟，5：客服
    fromPidx = "fromPidx", -- 发件人
    toPidx = "toPidx", -- 收件人
    titleKey = "titleKey", -- 标题key
    titleParams = "titleParams", -- 标题的参数(json的map)
    contentKey = "contentKey", -- 内容key
    contentParams = "contentParams", -- 内容参数(json的map)
    date = "date", -- 时间
    rewardIdx = "rewardIdx", -- 奖励idx
    comIdx = "comIdx", -- 通用ID,可以关联到比如战报id等
    backup = "backup", -- 备用
}

function dbmail:ctor(v)
    self.__name__ = "mail"    -- 表名
    self.__isNew__ = nil -- false:说明mysql里已经有数据了
    if v then
        self:init(v)
    end
end

function dbmail:init(data, isNew)
    data = dbmail.validData(data)
    self.__key__ = data.idx
    local hadCacheData = false
    if self.__isNew__ == nil and isNew == nil then
        local d = skynet.call("CLDB", "lua", "get", dbmail.name, self.__key__)
        if d == nil then
            d = skynet.call("CLMySQL", "lua", "exesql", dbmail.querySql(data.idx))
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

function dbmail:getInsertSql()
    if self:isEmpty() then
        return nil
    end
    local data = dbmail.validData(self:value2copy())
    local sql = skynet.call("CLDB", "lua", "GETINSERTSQL", self.__name__, data)
    return sql
end
function dbmail:tablename() -- 取得表名
    return self.__name__
end

function dbmail:value2copy()  -- 取得数据复样，注意是只读的数据且只有当前时刻是最新的，如果要取得最新数据及修改数据，请用get、set
    local ret = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__)
    if ret then
        ret.date = self:get_date()
    end
    return ret
end

function dbmail:refreshData(data)
    if data == nil or self.__key__ == nil then
        skynet.error("dbmail:refreshData error!")
        return
    end
    local orgData = self:value2copy()
    if orgData == nil then
        skynet.error("get old data error!!")
    end
    for k, v in pairs(data) do
        orgData[k] = v
    end
    orgData = dbmail.validData(orgData)
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, orgData)
end

function dbmail:set_idx(v)
    -- 唯一标识
    if self:isEmpty() then
        skynet.error("[dbmail:set_idx],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "idx", v)
end
function dbmail:get_idx()
    -- 唯一标识
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "idx")
    return (tonumber(val) or 0)
end

function dbmail:set_parent(v)
    -- 父idx(其实就是邮件的idx，回复的邮件指向的主邮件的idx)
    if self:isEmpty() then
        skynet.error("[dbmail:set_parent],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "parent", v)
end
function dbmail:get_parent()
    -- 父idx(其实就是邮件的idx，回复的邮件指向的主邮件的idx)
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "parent")
    return (tonumber(val) or 0)
end

function dbmail:set_type(v)
    -- 类型，1：系统，2：战报；3：私信，4:联盟，5：客服
    if self:isEmpty() then
        skynet.error("[dbmail:set_type],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "type", v)
end
function dbmail:get_type()
    -- 类型，1：系统，2：战报；3：私信，4:联盟，5：客服
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "type")
    return (tonumber(val) or 0)
end

function dbmail:set_fromPidx(v)
    -- 发件人
    if self:isEmpty() then
        skynet.error("[dbmail:set_fromPidx],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "fromPidx", v)
end
function dbmail:get_fromPidx()
    -- 发件人
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "fromPidx")
    return (tonumber(val) or 0)
end

function dbmail:set_toPidx(v)
    -- 收件人
    if self:isEmpty() then
        skynet.error("[dbmail:set_toPidx],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "toPidx", v)
end
function dbmail:get_toPidx()
    -- 收件人
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "toPidx")
    return (tonumber(val) or 0)
end

function dbmail:set_titleKey(v)
    -- 标题key
    if self:isEmpty() then
        skynet.error("[dbmail:set_titleKey],please init first!!")
        return nil
    end
    v = v or ""
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "titleKey", v)
end
function dbmail:get_titleKey()
    -- 标题key
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "titleKey")
end

function dbmail:set_titleParams(v)
    -- 标题的参数(json的map)
    if self:isEmpty() then
        skynet.error("[dbmail:set_titleParams],please init first!!")
        return nil
    end
    v = v or ""
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "titleParams", v)
end
function dbmail:get_titleParams()
    -- 标题的参数(json的map)
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "titleParams")
end

function dbmail:set_contentKey(v)
    -- 内容key
    if self:isEmpty() then
        skynet.error("[dbmail:set_contentKey],please init first!!")
        return nil
    end
    v = v or ""
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "contentKey", v)
end
function dbmail:get_contentKey()
    -- 内容key
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "contentKey")
end

function dbmail:set_contentParams(v)
    -- 内容参数(json的map)
    if self:isEmpty() then
        skynet.error("[dbmail:set_contentParams],please init first!!")
        return nil
    end
    v = v or ""
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "contentParams", v)
end
function dbmail:get_contentParams()
    -- 内容参数(json的map)
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "contentParams")
end

function dbmail:set_date(v)
    -- 时间
    if self:isEmpty() then
        skynet.error("[dbmail:set_date],please init first!!")
        return nil
    end
    if type(v) == "number" then
        v = dateEx.seconds2Str(v/1000)
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "date", v)
end
function dbmail:get_date()
    -- 时间
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "date")
    if type(val) == "string" then
        return dateEx.str2Seconds(val)*1000 -- 转成毫秒
    else
        return val or 0
    end
end

function dbmail:set_rewardIdx(v)
    -- 奖励idx
    if self:isEmpty() then
        skynet.error("[dbmail:set_rewardIdx],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "rewardIdx", v)
end
function dbmail:get_rewardIdx()
    -- 奖励idx
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "rewardIdx")
    return (tonumber(val) or 0)
end

function dbmail:set_comIdx(v)
    -- 通用ID,可以关联到比如战报id等
    if self:isEmpty() then
        skynet.error("[dbmail:set_comIdx],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "comIdx", v)
end
function dbmail:get_comIdx()
    -- 通用ID,可以关联到比如战报id等
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "comIdx")
    return (tonumber(val) or 0)
end

function dbmail:set_backup(v)
    -- 备用
    if self:isEmpty() then
        skynet.error("[dbmail:set_backup],please init first!!")
        return nil
    end
    v = v or ""
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "backup", v)
end
function dbmail:get_backup()
    -- 备用
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "backup")
end

-- 把数据flush到mysql里， immd=true 立即生效
function dbmail:flush(immd)
    local sql
    local data = dbmail.validData(self:value2copy())
    if self.__isNew__ then
        sql = skynet.call("CLDB", "lua", "GETINSERTSQL", self.__name__, data)
        return skynet.call("CLMySQL", "lua", "exesql", sql, immd)
    else
        sql = skynet.call("CLDB", "lua", "GETUPDATESQL", self.__name__, data)
        return skynet.call("CLMySQL", "lua", "save", sql, immd)
    end
end

function dbmail:isEmpty()
    return (self.__key__ == nil) or (self:get_idx() == nil)
end

function dbmail:release(returnVal)
    local val = nil
    if not self:isEmpty() then
        if returnVal then
            val = self:value2copy()
        end
        skynet.call("CLDB", "lua", "SETUNUSE", self.__name__, self.__key__)
    end
    self.__isNew__ = nil
    self.__key__ = nil
    self = nil
    return val
end

function dbmail:delete()
    local d = self:value2copy()
    skynet.call("CLDB", "lua", "SETUNUSE", self.__name__, self.__key__)
    skynet.call("CLDB", "lua", "REMOVE", self.__name__, self.__key__)
    local sql = skynet.call("CLDB", "lua", "GETDELETESQL", self.__name__, d)
    self.__key__ = nil
    return skynet.call("CLMySQL", "lua", "exesql", sql)
end

---public 设置触发器（当有数据改变时回调）
---@param server 触发回调服务地址
---@param cmd 触发回调服务方法
---@param fieldKey 字段key(可为nil)
function dbmail:setTrigger(server, cmd, fieldKey)
    skynet.call("CLDB", "lua", "ADDTRIGGER", self.__name__, self.__key__, server, cmd, fieldKey)
end

---@param server 触发回调服务地址
---@param cmd 触发回调服务方法
---@param fieldKey 字段key(可为nil)
function dbmail:unsetTrigger(server, cmd, fieldKey)
    skynet.call("CLDB", "lua", "REMOVETRIGGER", self.__name__, self.__key__, server, cmd, fieldKey)
end

function dbmail.querySql(idx)
    -- 如果某个参数为nil,则where条件中不包括该条件
    local where = {}
    if idx then
        table.insert(where, "`idx`=" .. idx)
    end
    if #where > 0 then
        return "SELECT * FROM mail WHERE " .. table.concat(where, " and ") .. ";"
    else
       return "SELECT * FROM mail;"
    end
end

---public 取得一个组
---@param forceSelect boolean 强制从mysql取数据
---@param orderby string 排序
function dbmail.getListByparent(parent, forceSelect, orderby, limitOffset, limitNum)
    if orderby and orderby ~= "" then
        forceSelect = true
    end
    local data
    local ret = {}
    local cachlist, isFullCached, list
    local groupKey = "parent_" .. parent
    local groupInfor = skynet.call("CLDB", "lua", "GETGROUP", dbmail.name,  groupKey) or {}
    cachlist = groupInfor[1] or {}
    isFullCached = groupInfor[2]
    if isFullCached == true and (not forceSelect) then
        list = cachlist
        for k, v in pairs(list) do
            data = dbmail.new(v, false)
            table.insert(ret, data:value2copy())
            data:release()
        end
    else
        local sql = "SELECT * FROM mail WHERE parent=" .. parent ..  (orderby and " ORDER BY" ..  orderby or "") .. ((limitOffset and limitNum) and (" LIMIT " ..  limitOffset .. "," .. limitNum) or "") .. ";"
        list = skynet.call("CLMySQL", "lua", "exesql", sql)
        if list and list.errno then
            skynet.error("[dbmail.getGroup] sql error==" .. sql)
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
             data = dbmail.new(v, false)
             ret[k] = data:value2copy()
             data:release()
         end
     end
     list = nil
     -- 设置当前缓存数据是全的数据
     skynet.call("CLDB", "lua", "SETGROUPISFULL", dbmail.name, groupKey)
     return ret
end

function dbmail.validData(data)
    if data == nil then return nil end

    if type(data.idx) ~= "number" then
        data.idx = tonumber(data.idx) or 0
    end
    if type(data.parent) ~= "number" then
        data.parent = tonumber(data.parent) or 0
    end
    if type(data.type) ~= "number" then
        data.type = tonumber(data.type) or 0
    end
    if type(data.fromPidx) ~= "number" then
        data.fromPidx = tonumber(data.fromPidx) or 0
    end
    if type(data.toPidx) ~= "number" then
        data.toPidx = tonumber(data.toPidx) or 0
    end
    if type(data.date) == "number" then
        data.date = dateEx.seconds2Str(data.date/1000)
    end
    if type(data.rewardIdx) ~= "number" then
        data.rewardIdx = tonumber(data.rewardIdx) or 0
    end
    if type(data.comIdx) ~= "number" then
        data.comIdx = tonumber(data.comIdx) or 0
    end
    return data
end

function dbmail.instanse(idx)
    if type(idx) == "table" then
        local d = idx
        idx = d.idx
    end
    if idx == nil then
        skynet.error("[dbmail.instanse] all input params == nil")
        return nil
    end
    local key = (idx or "")
    if key == "" then
        error("the key is null", 0)
    end
    ---@type dbmail
    local obj = dbmail.new()
    local d = skynet.call("CLDB", "lua", "get", dbmail.name, key)
    if d == nil then
        d = skynet.call("CLMySQL", "lua", "exesql", dbmail.querySql(idx))
        if d and d.errno == nil and #d > 0 then
            if #d == 1 then
                d = d[1]
                -- 取得mysql表里的数据
                obj.__isNew__ = false
                obj.__key__ = key
                obj:init(d)
            else
                error("get data is more than one! count==" .. #d .. ", lua==dbmail")
            end
        else
            -- 没有数据
            obj.__isNew__ = true
        end
    else
        obj.__isNew__ = false
        obj.__key__ = key
        skynet.call("CLDB", "lua", "SETUSE", dbmail.name, key)
    end
    return obj
end

------------------------------------
return dbmail
