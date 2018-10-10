--[[
使用时特别注意：
1、常用方法如下，在不知道表里有没有数据时可以采用如下方法（可能会查询一次表）
    local obj＝ dbbuilding.instanse(idx);
    if obj:isEmpty() then
        -- 没有数据
    else
        -- 有数据
    end
2、使用如下用法时，程序会自动判断是否是insert还是update
    local obj＝ dbbuilding.new(data);
3、使用如下用法时，程序会自动判断是否是insert还是update
    local obj＝ dbbuilding.new();
    obj:init(data);
]]

require("class")
local skynet = require "skynet"
local tonumber = tonumber
require("dateEx")

-- 建筑表
---@class dbbuilding
dbbuilding = class("dbbuilding")

dbbuilding.name = "building"

function dbbuilding:ctor(v)
    self.__name__ = "building"    -- 表名
    self.__isNew__ = nil -- false:说明mysql里已经有数据了
    if v then
        self:init(v)
    end
end

function dbbuilding:init(data, isNew)
    data = dbbuilding.validData(data)
    self.__key__ = data.idx
    if self.__isNew__ == nil and isNew == nil then
        local d = skynet.call("CLDB", "lua", "get", dbbuilding.name, self.__key__)
        if d == nil then
            d = skynet.call("CLMySQL", "lua", "exesql", dbbuilding.querySql(data.idx, nil))
            if d and d.errno == nil and #d > 0 then
                self.__isNew__ = false
            else
                self.__isNew__ = true
            end
        else
            self.__isNew__ = false
        end
    else
        self.__isNew__ = isNew
    end
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
    local ret = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__)
    ret.starttime = self:get_starttime()
    ret.endtime = self:get_endtime()
    return ret
end

function dbbuilding:set_idx(v)
    -- 唯一标识
    if self:isEmpty() then
        skynet.error("[dbbuilding:set_idx],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "idx", v)
end
function dbbuilding:get_idx()
    -- 唯一标识
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "idx")
    return (tonumber(val) or 0)
end

function dbbuilding:set_cidx(v)
    -- 主城idx
    if self:isEmpty() then
        skynet.error("[dbbuilding:set_cidx],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "cidx", v)
end
function dbbuilding:get_cidx()
    -- 主城idx
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "cidx")
    return (tonumber(val) or 0)
end

function dbbuilding:set_pos(v)
    -- 位置，即在城的gird中的index
    if self:isEmpty() then
        skynet.error("[dbbuilding:set_pos],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "pos", v)
end
function dbbuilding:get_pos()
    -- 位置，即在城的gird中的index
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "pos")
    return (tonumber(val) or 0)
end

function dbbuilding:set_attrid(v)
    -- 属性配置id
    if self:isEmpty() then
        skynet.error("[dbbuilding:set_attrid],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "attrid", v)
end
function dbbuilding:get_attrid()
    -- 属性配置id
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "attrid")
    return (tonumber(val) or 0)
end

function dbbuilding:set_lev(v)
    -- 等级
    if self:isEmpty() then
        skynet.error("[dbbuilding:set_lev],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "lev", v)
end
function dbbuilding:get_lev()
    -- 等级
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "lev")
    return (tonumber(val) or 0)
end

function dbbuilding:set_state(v)
    -- 状态. 0：正常；1：升级中；9：恢复中
    if self:isEmpty() then
        skynet.error("[dbbuilding:set_state],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "state", v)
end
function dbbuilding:get_state()
    -- 状态. 0：正常；1：升级中；9：恢复中
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "state")
    return (tonumber(val) or 0)
end

function dbbuilding:set_starttime(v)
    -- 开始升级、恢复、采集等的时间点
    if self:isEmpty() then
        skynet.error("[dbbuilding:set_starttime],please init first!!")
        return nil
    end
    if type(v) == "number" then
        v = dateEx.seconds2Str(v/1000)
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "starttime", v)
end
function dbbuilding:get_starttime()
    -- 开始升级、恢复、采集等的时间点
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "starttime")
    if type(val) == "string" then
        return dateEx.str2Seconds(val)*1000 -- 转成毫秒
    else
        return val
    end
end

function dbbuilding:set_endtime(v)
    -- 完成升级、恢复、采集等的时间点
    if self:isEmpty() then
        skynet.error("[dbbuilding:set_endtime],please init first!!")
        return nil
    end
    if type(v) == "number" then
        v = dateEx.seconds2Str(v/1000)
    end
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "endtime", v)
end
function dbbuilding:get_endtime()
    -- 完成升级、恢复、采集等的时间点
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "endtime")
    if type(val) == "string" then
        return dateEx.str2Seconds(val)*1000 -- 转成毫秒
    else
        return val
    end
end

function dbbuilding:set_val(v)
    -- 值。如:产量，仓库的存储量等
    if self:isEmpty() then
        skynet.error("[dbbuilding:set_val],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "val", v)
end
function dbbuilding:get_val()
    -- 值。如:产量，仓库的存储量等
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "val")
    return (tonumber(val) or 0)
end

function dbbuilding:set_val2(v)
    -- 值2。如:产量，仓库的存储量等
    if self:isEmpty() then
        skynet.error("[dbbuilding:set_val2],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "val2", v)
end
function dbbuilding:get_val2()
    -- 值2。如:产量，仓库的存储量等
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "val2")
    return (tonumber(val) or 0)
end

function dbbuilding:set_val3(v)
    -- 值3。如:产量，仓库的存储量等
    if self:isEmpty() then
        skynet.error("[dbbuilding:set_val3],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "val3", v)
end
function dbbuilding:get_val3()
    -- 值3。如:产量，仓库的存储量等
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "val3")
    return (tonumber(val) or 0)
end

function dbbuilding:set_val4(v)
    -- 值4。如:产量，仓库的存储量等
    if self:isEmpty() then
        skynet.error("[dbbuilding:set_val4],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "val4", v)
end
function dbbuilding:get_val4()
    -- 值4。如:产量，仓库的存储量等
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "val4")
    return (tonumber(val) or 0)
end

function dbbuilding:set_val5(v)
    -- 值5。如:产量，仓库的存储量等
    if self:isEmpty() then
        skynet.error("[dbbuilding:set_val5],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "val5", v)
end
function dbbuilding:get_val5()
    -- 值5。如:产量，仓库的存储量等
    local val = skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "val5")
    return (tonumber(val) or 0)
end

-- 把数据flush到mysql里， immd=true 立即生效
function dbbuilding:flush(immd)
    local sql
    if self.__isNew__ then
        sql = skynet.call("CLDB", "lua", "GETINSERTSQL", self.__name__, self:value2copy())
    else
        sql = skynet.call("CLDB", "lua", "GETUPDATESQL", self.__name__, self:value2copy())
    end
    return skynet.call("CLMySQL", "lua", "save", sql, immd)
end

function dbbuilding:isEmpty()
    return (self.__key__ == nil) or (self:get_idx() == nil)
end

function dbbuilding:release()
    skynet.call("CLDB", "lua", "SETUNUSE", self.__name__, self.__key__)
    self.__isNew__ = nil
    self.__key__ = nil
end

function dbbuilding:delete()
    local d = self:value2copy()
    skynet.call("CLDB", "lua", "SETUNUSE", self.__name__, self.__key__)
    skynet.call("CLDB", "lua", "REMOVE", self.__name__, self.__key__)
    local sql = skynet.call("CLDB", "lua", "GETDELETESQL", self.__name__, d)
    return skynet.call("CLMySQL", "lua", "EXESQL", sql)
end

---@public 设置触发器（当有数据改变时回调）
---@param server 触发回调服务地址
---@param cmd 触发回调服务方法
---@param fieldKey 字段key(可为nil)
function dbbuilding:setTrigger(server, cmd, fieldKey)
    skynet.call("CLDB", "lua", "ADDTRIGGER", self.__name__, self.__key__, server, cmd, fieldKey)
end

---@param server 触发回调服务地址
---@param cmd 触发回调服务方法
---@param fieldKey 字段key(可为nil)
function dbbuilding:unsetTrigger(server, cmd, fieldKey)
    skynet.call("CLDB", "lua", "REMOVETRIGGER", self.__name__, self.__key__, server, cmd, fieldKey)
end

function dbbuilding.querySql(idx, cidx)
    -- 如果某个参数为nil,则where条件中不包括该条件
    local where = {}
    if idx then
        table.insert(where, "`idx`=" .. idx)
    end
    if cidx then
        table.insert(where, "`cidx`=" .. cidx)
    end
    if #where > 0 then
        return "SELECT * FROM building WHERE " .. table.concat(where, " and ") .. ";"
    else
       return "SELECT * FROM building;"
    end
end

-- 取得一个组
function dbbuilding.getListBycidx(cidx, orderby, limitOffset, limitNum)
    local sql = "SELECT * FROM building WHERE cidx=" .. cidx ..  (orderby and " ORDER BY" ..  orderby or "") .. ((limitOffset and limitNum) and (" LIMIT " ..  limitOffset .. "," .. limitNum) or "") .. ";"
    local list = skynet.call("CLMySQL", "lua", "exesql", sql)
    if list and list.errno then
        skynet.error("[dbbuilding.getGroup] sql error==" .. sql)
        return nil
     end
     local cachlist = skynet.call("CLDB", "lua", "GETGROUP", dbbuilding.name, cidx) or {}
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
     local data
     local ret = {}
     for k, v in ipairs(list) do
         data = dbbuilding.new(v, false)
         ret[k] = data:value2copy()
         data:release()
     end
     list = nil
     return ret
end

function dbbuilding.validData(data)
    if data == nil then return nil end

    if type(data.idx) ~= "number" then
        data.idx = tonumber(data.idx) or 0
    end
    if type(data.cidx) ~= "number" then
        data.cidx = tonumber(data.cidx) or 0
    end
    if type(data.pos) ~= "number" then
        data.pos = tonumber(data.pos) or 0
    end
    if type(data.attrid) ~= "number" then
        data.attrid = tonumber(data.attrid) or 0
    end
    if type(data.lev) ~= "number" then
        data.lev = tonumber(data.lev) or 0
    end
    if type(data.state) ~= "number" then
        data.state = tonumber(data.state) or 0
    end
    if type(data.starttime) == "number" then
        data.starttime = dateEx.seconds2Str(data.starttime/1000)
    end
    if type(data.endtime) == "number" then
        data.endtime = dateEx.seconds2Str(data.endtime/1000)
    end
    if type(data.val) ~= "number" then
        data.val = tonumber(data.val) or 0
    end
    if type(data.val2) ~= "number" then
        data.val2 = tonumber(data.val2) or 0
    end
    if type(data.val3) ~= "number" then
        data.val3 = tonumber(data.val3) or 0
    end
    if type(data.val4) ~= "number" then
        data.val4 = tonumber(data.val4) or 0
    end
    if type(data.val5) ~= "number" then
        data.val5 = tonumber(data.val5) or 0
    end
    return data
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
    local d = skynet.call("CLDB", "lua", "get", dbbuilding.name, key)
    if d == nil then
        d = skynet.call("CLMySQL", "lua", "exesql", dbbuilding.querySql(idx, nil))
        if d and d.errno == nil and #d > 0 then
            if #d == 1 then
                d = d[1]
                -- 取得mysql表里的数据
                obj.__isNew__ = false
                obj.__key__ = key
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
        obj.__key__ = key
        skynet.call("CLDB", "lua", "SETUSE", dbbuilding.name, key)
    end
    return obj
end

------------------------------------
return dbbuilding
