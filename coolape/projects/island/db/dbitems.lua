--[[
使用时特别注意：
1、常用方法如下，在不知道表里有没有数据时可以采用如下方法（可能会查询一次表）
    local obj＝ dbitems.instanse(idx);
    if obj:isEmpty() then
        -- 没有数据
    else
        -- 有数据
    end
2、使用如下用法时，程序会自动判断是否是insert还是update
    local obj＝ dbitems.new(data);
3、使用如下用法时，程序会自动判断是否是insert还是update
    local obj＝ dbitems.new();
    obj:init(data);
]]

require("class")
local skynet = require "skynet"
local tonumber = tonumber
require("dateEx")

-- 道具物品
---@class dbitems : ClassBase
dbitems = class("dbitems")

dbitems.name = "items"

dbitems.keys = {
    idx = "idx", -- 唯一标识
    pidx = "pidx", -- 玩家唯一标识
    id = "id", -- 对应的id
    type = "type", -- 类型，1：资源、经验值等（领奖就直接把数值加上），2：加速(建筑、造船、科技)，3：护盾4：碎片(海怪碎片)，5：图纸，6：舰船，7：复活药水(建筑、海怪)99：宝箱(嵌套礼包)
    num = "num", -- 数量
}

function dbitems:ctor(v)
    self.__name__ = "items"    -- 表名
    self.__isNew__ = nil -- false:说明mysql里已经有数据了
    if v then
        self:init(v)
    end
end

function dbitems:init(data, isNew)
    data = dbitems.validData(data)
    self.__key__ = data.idx
    local hadCacheData = false
    if self.__isNew__ == nil and isNew == nil then
        local d = skynet.call("CLDB", "lua", "get", dbitems.name, self.__key__)
        if d == nil then
            d = skynet.call("CLMySQL", "lua", "exesql", dbitems.querySql(data.idx, nil))
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

function dbitems:getInsertSql()
    if self:isEmpty() then
        return nil
    end
    local data = dbitems.validData(self:value2copy())
    local sql = skynet.call("CLDB", "lua", "GETINSERTSQL", self.__name__, data)
    return sql
end
function dbitems:tablename() -- 取得表名
    return self.__name__
end

function dbitems:value2copy()  -- 取得数据复样，注意是只读的数据且只有当前时刻是最新的，如果要取得最新数据及修改数据，请用get、set
    local ret = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__)
    if ret then
    end
    return ret
end

function dbitems:refreshData(data)
    if data == nil or self.__key__ == nil then
        skynet.error("dbitems:refreshData error!")
        return
    end
    local orgData = self:value2copy()
    if orgData == nil then
        skynet.error("get old data error!!")
    end
    for k, v in pairs(data) do
        orgData[k] = v
    end
    orgData = dbitems.validData(orgData)
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, orgData)
end

function dbitems:set_idx(v)
    -- 唯一标识
    if self:isEmpty() then
        skynet.error("[dbitems:set_idx],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "idx", v)
end
function dbitems:get_idx()
    -- 唯一标识
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "idx")
    return (tonumber(val) or 0)
end

function dbitems:set_pidx(v)
    -- 玩家唯一标识
    if self:isEmpty() then
        skynet.error("[dbitems:set_pidx],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "pidx", v)
end
function dbitems:get_pidx()
    -- 玩家唯一标识
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "pidx")
    return (tonumber(val) or 0)
end

function dbitems:set_id(v)
    -- 对应的id
    if self:isEmpty() then
        skynet.error("[dbitems:set_id],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "id", v)
end
function dbitems:get_id()
    -- 对应的id
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "id")
    return (tonumber(val) or 0)
end

function dbitems:set_type(v)
    -- 类型，1：资源、经验值等（领奖就直接把数值加上），2：加速(建筑、造船、科技)，3：护盾4：碎片(海怪碎片)，5：图纸，6：舰船，7：复活药水(建筑、海怪)99：宝箱(嵌套礼包)
    if self:isEmpty() then
        skynet.error("[dbitems:set_type],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "type", v)
end
function dbitems:get_type()
    -- 类型，1：资源、经验值等（领奖就直接把数值加上），2：加速(建筑、造船、科技)，3：护盾4：碎片(海怪碎片)，5：图纸，6：舰船，7：复活药水(建筑、海怪)99：宝箱(嵌套礼包)
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "type")
    return (tonumber(val) or 0)
end

function dbitems:set_num(v)
    -- 数量
    if self:isEmpty() then
        skynet.error("[dbitems:set_num],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "num", v)
end
function dbitems:get_num()
    -- 数量
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "num")
    return (tonumber(val) or 0)
end

-- 把数据flush到mysql里， immd=true 立即生效
function dbitems:flush(immd)
    local sql
    local data = dbitems.validData(self:value2copy())
    if self.__isNew__ then
        sql = skynet.call("CLDB", "lua", "GETINSERTSQL", self.__name__, data)
        return skynet.call("CLMySQL", "lua", "exesql", sql, immd)
    else
        sql = skynet.call("CLDB", "lua", "GETUPDATESQL", self.__name__, data)
        return skynet.call("CLMySQL", "lua", "save", sql, immd)
    end
end

function dbitems:isEmpty()
    return (self.__key__ == nil) or (self:get_idx() == nil)
end

function dbitems:release(returnVal)
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

function dbitems:delete()
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
function dbitems:setTrigger(server, cmd, fieldKey)
    skynet.call("CLDB", "lua", "ADDTRIGGER", self.__name__, self.__key__, server, cmd, fieldKey)
end

---@param server 触发回调服务地址
---@param cmd 触发回调服务方法
---@param fieldKey 字段key(可为nil)
function dbitems:unsetTrigger(server, cmd, fieldKey)
    skynet.call("CLDB", "lua", "REMOVETRIGGER", self.__name__, self.__key__, server, cmd, fieldKey)
end

function dbitems.querySql(idx, pidx)
    -- 如果某个参数为nil,则where条件中不包括该条件
    local where = {}
    if idx then
        table.insert(where, "`idx`=" .. idx)
    end
    if pidx then
        table.insert(where, "`pidx`=" .. pidx)
    end
    if #where > 0 then
        return "SELECT * FROM items WHERE " .. table.concat(where, " and ") .. ";"
    else
       return "SELECT * FROM items;"
    end
end

---public 取得一个组
---@param forceSelect boolean 强制从mysql取数据
---@param orderby string 排序
function dbitems.getListBypidx(pidx, forceSelect, orderby, limitOffset, limitNum)
    if orderby and orderby ~= "" then
        forceSelect = true
    end
    local data
    local ret = {}
    local cachlist, isFullCached, list
    local groupKey = "pidx_" .. pidx
    local groupInfor = skynet.call("CLDB", "lua", "GETGROUP", dbitems.name,  groupKey) or {}
    cachlist = groupInfor[1] or {}
    isFullCached = groupInfor[2]
    if isFullCached == true and (not forceSelect) then
        list = cachlist
        for k, v in pairs(list) do
            data = dbitems.new(v, false)
            table.insert(ret, data:value2copy())
            data:release()
        end
    else
        local sql = "SELECT * FROM items WHERE pidx=" .. pidx ..  (orderby and " ORDER BY" ..  orderby or "") .. ((limitOffset and limitNum) and (" LIMIT " ..  limitOffset .. "," .. limitNum) or "") .. ";"
        list = skynet.call("CLMySQL", "lua", "exesql", sql)
        if list and list.errno then
            skynet.error("[dbitems.getGroup] sql error==" .. sql)
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
             data = dbitems.new(v, false)
             ret[k] = data:value2copy()
             data:release()
         end
     end
     list = nil
     -- 设置当前缓存数据是全的数据
     skynet.call("CLDB", "lua", "SETGROUPISFULL", dbitems.name, groupKey)
     return ret
end

function dbitems.validData(data)
    if data == nil then return nil end

    if type(data.idx) ~= "number" then
        data.idx = tonumber(data.idx) or 0
    end
    if type(data.pidx) ~= "number" then
        data.pidx = tonumber(data.pidx) or 0
    end
    if type(data.id) ~= "number" then
        data.id = tonumber(data.id) or 0
    end
    if type(data.type) ~= "number" then
        data.type = tonumber(data.type) or 0
    end
    if type(data.num) ~= "number" then
        data.num = tonumber(data.num) or 0
    end
    return data
end

function dbitems.instanse(idx)
    if type(idx) == "table" then
        local d = idx
        idx = d.idx
    end
    if idx == nil then
        skynet.error("[dbitems.instanse] all input params == nil")
        return nil
    end
    local key = (idx or "")
    if key == "" then
        error("the key is null", 0)
    end
    ---@type dbitems
    local obj = dbitems.new()
    local d = skynet.call("CLDB", "lua", "get", dbitems.name, key)
    if d == nil then
        d = skynet.call("CLMySQL", "lua", "exesql", dbitems.querySql(idx, nil))
        if d and d.errno == nil and #d > 0 then
            if #d == 1 then
                d = d[1]
                -- 取得mysql表里的数据
                obj.__isNew__ = false
                obj.__key__ = key
                obj:init(d)
            else
                error("get data is more than one! count==" .. #d .. ", lua==dbitems")
            end
        else
            -- 没有数据
            obj.__isNew__ = true
        end
    else
        obj.__isNew__ = false
        obj.__key__ = key
        skynet.call("CLDB", "lua", "SETUSE", dbitems.name, key)
    end
    return obj
end

------------------------------------
return dbitems
