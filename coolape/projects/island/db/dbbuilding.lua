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
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__)
end

function dbbuilding:set_idx(v)
    -- 唯一标识
    if self:isEmpty() then
        skynet.error("[dbbuilding:setidx],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "idx", v)
end
function dbbuilding:get_idx()
    -- 唯一标识
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "idx")
end

function dbbuilding:set_cidx(v)
    -- 主城idx
    if self:isEmpty() then
        skynet.error("[dbbuilding:setcidx],please init first!!")
        return nil
    end
    v = v or ""
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "cidx", v)
end
function dbbuilding:get_cidx()
    -- 主城idx
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "cidx")
end

function dbbuilding:set_pos(v)
    -- 位置，即在城的gird中的index
    if self:isEmpty() then
        skynet.error("[dbbuilding:setpos],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "pos", v)
end
function dbbuilding:get_pos()
    -- 位置，即在城的gird中的index
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "pos")
end

function dbbuilding:set_attrid(v)
    -- 属性配置id
    if self:isEmpty() then
        skynet.error("[dbbuilding:setattrid],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "attrid", v)
end
function dbbuilding:get_attrid()
    -- 属性配置id
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "attrid")
end

function dbbuilding:set_lev(v)
    -- 等级
    if self:isEmpty() then
        skynet.error("[dbbuilding:setlev],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "lev", v)
end
function dbbuilding:get_lev()
    -- 等级
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "lev")
end

function dbbuilding:set_state(v)
    -- 状态. 0：正常；1：升级中；9：恢复中
    if self:isEmpty() then
        skynet.error("[dbbuilding:setstate],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "state", v)
end
function dbbuilding:get_state()
    -- 状态. 0：正常；1：升级中；9：恢复中
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "state")
end

function dbbuilding:set_starttime(v)
    -- 开始升级、恢复、采集等的时间点
    if self:isEmpty() then
        skynet.error("[dbbuilding:setstarttime],please init first!!")
        return nil
    end
    v = v or ""
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "starttime", v)
end
function dbbuilding:get_starttime()
    -- 开始升级、恢复、采集等的时间点
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "starttime")
end

function dbbuilding:set_endtime(v)
    -- 完成升级、恢复、采集等的时间点
    if self:isEmpty() then
        skynet.error("[dbbuilding:setendtime],please init first!!")
        return nil
    end
    v = v or ""
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "endtime", v)
end
function dbbuilding:get_endtime()
    -- 完成升级、恢复、采集等的时间点
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "endtime")
end

function dbbuilding:set_val(v)
    -- 值。如:产量，仓库的存储量等
    if self:isEmpty() then
        skynet.error("[dbbuilding:setval],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "val", v)
end
function dbbuilding:get_val()
    -- 值。如:产量，仓库的存储量等
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "val")
end

function dbbuilding:set_val2(v)
    -- 值2。如:产量，仓库的存储量等
    if self:isEmpty() then
        skynet.error("[dbbuilding:setval2],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "val2", v)
end
function dbbuilding:get_val2()
    -- 值2。如:产量，仓库的存储量等
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "val2")
end

function dbbuilding:set_val3(v)
    -- 值3。如:产量，仓库的存储量等
    if self:isEmpty() then
        skynet.error("[dbbuilding:setval3],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "val3", v)
end
function dbbuilding:get_val3()
    -- 值3。如:产量，仓库的存储量等
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "val3")
end

function dbbuilding:set_val4(v)
    -- 值4。如:产量，仓库的存储量等
    if self:isEmpty() then
        skynet.error("[dbbuilding:setval4],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "val4", v)
end
function dbbuilding:get_val4()
    -- 值4。如:产量，仓库的存储量等
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "val4")
end

function dbbuilding:set_val5(v)
    -- 值5。如:产量，仓库的存储量等
    if self:isEmpty() then
        skynet.error("[dbbuilding:setval5],please init first!!")
        return nil
    end
    v = tonumber(v) or 0
    skynet.call("CLDB", "lua", "set", self.__name__, self.__key__, "val5", v)
end
function dbbuilding:get_val5()
    -- 值5。如:产量，仓库的存储量等
    return skynet.call("CLDB", "lua", "get", self.__name__, self.__key__, "val5")
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
    return (self.__key__ == nil) or (self:get_idx() == nil)
end

function dbbuilding:release()
    skynet.call("CLDB", "lua", "SETUNUSE", self.__name__, self.__key__)
    self.__isNew__ = nil
    self.__key__ = nil
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
