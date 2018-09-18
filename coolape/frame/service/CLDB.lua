-- cache db
local skynet = require "skynet"
local sharedata = require "skynet.sharedata"
require "skynet.manager"    -- import skynet.register
local tablesdesign = "tablesdesign"
require("CLGlobal")
require("CLLQueue")

---@type CLUtl
local CLUtl = require("CLUtl")
local db = {}
local db4Group = {}
local dbTimeout = {}
local dbUsedTimes = {}
local command = {}
local needUpdateData = CLLQueue.new(100)  -- 需要更新的数据
local timeoutsec = 30 * 60;   -- 数据超时时间（秒）
local refreshsec = 1 * 60 * 100;   -- 数据更新时间（秒*100）
local insert = table.insert
local concat = table.concat
local tostring = tostring


-- 处理超时的数据，把数据写入mysql
local function checktimeout(db, dbTimeout)
    while true do
        local now = skynet.time();
        local hasTimeout = false;
        local d, data
        local sql
        local hadUpdated = {}
        local key2
        -- 把有变化的数据更新
        for i = 1, needUpdateData:size() do
            d = needUpdateData:deQueue()
            key2 = d.tableName .. "_" .. d.key
            if not hadUpdated[key2] then
                -- 为了不要频繁更新表
                data = command.GET(d.tableName, d.key)
                -- 说明是设置某个字段的值，这个时候才需要考虑更新到表
                if data then
                    sql = command.GETUPDATESQL(d.tableName, data)
                    skynet.call("CLMySQL", "lua", "save", sql)
                end
                hadUpdated[key2] = true
            end
        end
        hadUpdated = {}

        -- 把超时的数据去掉
        for tName, timoutList in pairs(dbTimeout) do
            for key, time in pairs(timoutList) do
                if now > time then
                    -- 超时数据
                    local val = command.GET(tName, key)
                    if val then
                        -- 数据更新到mysql（目前来看不需要更新，因为每次更新时都已经更新了）
                        --local sql = command.GETUPDATESQL(tName, val)
                        --skynet.call("CLMySQL", "lua", "save", sql)
                        timoutList[key] = nil;
                        command.REMOVE(tName, key)
                        hasTimeout = true;
                    end
                end
            end
        end

        --if hasTimeout then
        --    skynet.call("CLMySQL", "lua", "FLUSHAll")
        --end

        skynet.sleep(refreshsec)
    end
end

-- 更新组
local function setGroup(tableName, groupKey, key)
    local d = command.GET(tableName, key)
    local t = db4Group[tableName] or {}
    local group = t[tostring(groupKey)] or {}
    group[tostring(key)] = d
    t[tostring(groupKey)] = group
    db4Group[tableName] = t
end

-- 移除组里的数据
local function removeGroup(tableName, groupKey, key)
    local t = db4Group[tableName] or {}
    local group = t[tostring(groupKey)] or {}
    group[tostring(key)] = nil
    t[tostring(groupKey)] = group
    db4Group[tableName] = t
end

-- ============================================================
-- 取得一个组，注意这个组不是list而是个table
function command.GETGROUP(tableName, groupKey)
    local t = db4Group[tableName] or {}
    local cacheGroup = t[tostring(groupKey)] or {}
    return cacheGroup;
end

-- 取得数据.支持多个key
function command.GET(tableName, key, ...)
    local t = db[tableName]
    if t == nil then
        return nil
    end
    key = tostring(key)
    t = t[key]
    if t == nil then
        return nil
    end
    local params = { ... }
    if #params > 0 then
        for i, k in ipairs(params) do
            t = t[k]
            if t == nil then
                return nil
            end
        end
    end
    return t;
end

--[[
    设置数据.支持多个key，最后一个参数是要设置的value,例如：
    command.SET("user", "u001", "name", "小张")
    更新user表的key＝"u001"记录的，字段为name的值为"小张"
]]
function command.SET(tableName, key, ...)
    local params = { ... }
    if #params < 1 then
        printe("[CLDB.SET] parmas error")
        return nil;
    end

    local t = db[tableName]
    if t == nil then
        t = {}
        db[tableName] = t
    end
    key = tostring(key)
    local count = #params
    local val = params[count]
    local last = t[key]
    if count > 1 then
        local subt = nil;
        for i = 1, count - 1 do
            subt = last
            if subt == nil then
                subt = {}
            end
            last = subt[params[i]] -- 取得old数据
        end
        subt[params[count - 1]] = val   -- 设置成新数据
    else
        t[key] = val
    end

    --..........................................
    if last ~= val then
        if count > 1 then
            -- 记录下需要更新
            needUpdateData:enQueue({ tableName = tableName, key = key })
        end
        local d = command.GET(tableName, key)
        -- 如果有组，则更新
        local tableCfg = skynet.call("CLCfg", "lua", "GETTABLESCFG", tableName)
        if tableCfg == nil then
            printe("[cldb.remove],get tabel config is nil==" .. tableName)
        end
        if not CLUtl.isNilOrEmpty(tableCfg.groupKey) then
            setGroup(tableName, d[tableCfg.groupKey], key)
        end
    end

    return last
end

-- 移除数据
function command.REMOVE(tableName, key)
    local t = db[tableName]
    local last = nil
    if t then
        last = t[tostring(key)]
        t[tostring(key)] = nil
    end

    t = dbTimeout[tableName]
    if t then
        t[tostring(key)] = nil
    end
    t = dbUsedTimes[tableName]
    if t then
        t[tostring(key)] = nil
    end

    if last then
        -- 清除组里的数据
        local tableCfg = skynet.call("CLCfg", "lua", "GETTABLESCFG", tableName)
        if tableCfg == nil then
            printe("[cldb.remove],get tabel config is nil==" .. tableName)
        end
        if not CLUtl.isNilOrEmpty(tableCfg.groupKey) then
            removeGroup(tableName, last[tableCfg.groupKey], key)
        end
    end
    return last
end

-- 设置数据超时
function command.SETUSE(tableName, key)
    local t = dbTimeout[tableName]
    if t == nil then
        t = {}
        dbTimeout[tableName] = t
    else
        t[tostring(key)] = nil
    end
    dbTimeout[tableName] = t
    --==================================
    local t2 = dbUsedTimes[tableName]
    if t2 == nil then
        t2 = {}
        dbUsedTimes[tableName] = t2
    end
    local last = t2[tostring(key)] or 0
    t2[tostring(key)] = last + 1;
    dbUsedTimes[tableName] = t2
    --print(tableName .. "=SETUSE=" .. key .. "==" .. t2[key])
    return last;
end

-- 移除数据超时
function command.SETUNUSE(tableName, key)
    if key == nil then
        printe("command.SETUNUSE err, key is nil. tableName == " .. tableName)
        return
    end
    key = tostring(key)
    local t = dbUsedTimes[tableName]
    if t == nil then
        t = {}
        dbUsedTimes[tableName] = t
    end
    local last = t[key] or 0
    t[key] = last - 1
    dbUsedTimes[tableName] = t
    --print(tableName .. "=SETUNUSE=" .. key .. "==" .. t[key])
    if t[key] < 0 then
        printe("relase cache data less then 0. tableName=" .. tableName .. " key ==" .. key)
    end
    --==========================
    if t[key] <= 0 then
        local t2 = dbTimeout[tableName]
        if t2 == nil then
            t2 = {}
            dbTimeout[tableName] = t2
        end
        t2[key] = skynet.time() + timeoutsec
        dbTimeout[tableName] = t2
    end
    return last;
end

-- 数据写入mysql，immd＝true,表时立即生效
function command.FLUSH(tableName, key, immd)
    local val = command.GET(tableName, key)
    if val then
        local sql = command.GETUPDATESQL(tableName, val)
        if immd then
            skynet.call("CLMySQL", "lua", "exeSql", sql)
        else
            skynet.call("CLMySQL", "lua", "save", sql)
        end
        command.REMOVE(tableName, key)
    end
end

-- 全部数据写入mysql，immd＝true,表时立即生效
function command.FLUSHALL(immd)
    for tName, timoutList in pairs(dbTimeout) do
        for key, time in pairs(timoutList) do
            -- 超时数据
            local val = command.GET(tName, key)
            if val then
                skynet.call("CLMySQL", "lua", "save", command.GETUPDATESQL(tName, val))
                timoutList[key] = nil;
                command.REMOVE(tName, key)
            end
        end
    end
    if immd then
        skynet.call("CLMySQL", "lua", "FLUSHAll");
    end
end

-- 取得序列号
function command.NEXTVAL(key)
    if CLUtl.isNilOrEmpty(key) then
        key = "default"
    end

    local sql = "select nextval('" .. key .. "') as val;"
    local ret = skynet.call("CLMySQL", "lua", "exesql", sql)
    if ret and ret.errno then
        printe("get nextval error" .. ret.errno .. ",sql=[" .. sql .. "]")
        return -1
    end
    ret = ret[1]
    return ret.val
end

-- 生成insert的sql
function command.GETINSERTSQL(tableName, data)
    local tableCfg = skynet.call("CLCfg", "lua", "GETTABLESCFG", tableName)
    if tableCfg == nil then
        printe("[getUpdateSql],get tabel config is nil==" .. tableName)
        return nil
    end

    local dataInsert = {}
    local columns = {}
    for i, v in ipairs(tableCfg.columns) do
        insert(columns, "`" .. v[1] .. "`")
        local types = v[2]:upper()
        if types:find("DEC") or types:find("INT") or types:find("FLOAT") or types:find("DOUBLE") or types:find("BOOL") then
            insert(dataInsert, (data[v[1]] and data[v[1]] or 0));
        else
            insert(dataInsert, (data[v[1]] and "'" .. data[v[1]] .. "'" or "NULL"));
        end
    end

    local sql = {}
    insert(sql, "INSERT INTO `" .. tableCfg.name .. "` (" .. concat(columns, ",") .. ") VALUES (")
    insert(sql, concat(dataInsert, ", ") .. ");")

    local sqlstr = concat(sql)
    return sqlstr
end

-- 生成更新的sql
function command.GETUPDATESQL(tableName, data)
    local tableCfg = skynet.call("CLCfg", "lua", "GETTABLESCFG", tableName)
    if tableCfg == nil then
        printe("[getUpdateSql],get tabel config is nil==" .. tableName)
        return nil
    end

    local dataUpdate = {}
    local where = {}
    for i, v in ipairs(tableCfg.columns) do
        local types = v[2]:upper()
        if types:find("DEC") or types:find("INT") or types:find("FLOAT") or types:find("DOUBLE") or types:find("BOOL") then
            insert(dataUpdate, "`" .. v[1] .. "`=" .. (data[v[1]] and data[v[1]] or 0));
        else
            insert(dataUpdate, "`" .. v[1] .. "`=" .. (data[v[1]] and "'" .. data[v[1]] .. "'" or "NULL"));
        end
    end

    if tableCfg.primaryKey then
        for i, pkey in ipairs(tableCfg.primaryKey) do
            local types = ""
            for j, col in ipairs(tableCfg.columns) do
                if pkey == col[1] then
                    types = col[2]:upper()
                    break
                end
            end

            if types:find("DEC") or types:find("INT") or types:find("FLOAT") or types:find("DOUBLE") or types:find("BOOL") then
                insert(where, "`" .. pkey .. "`=" .. (data[pkey] and data[pkey] or 0));
            else
                insert(where, "`" .. pkey .. "`=" .. (data[pkey] and "'" .. data[pkey] .. "'" or "NULL"));
            end
        end
    end
    local sql = {}
    insert(sql, "UPDATE " .. tableCfg.name .. " SET ")
    insert(sql, concat(dataUpdate, ", "))
    insert(sql, " WHERE " .. concat(where, " AND ") .. ";")
    local sqlstr = concat(sql)
    return sqlstr
end

-- 生成del的sql
function command.GETDELETESQL(tableName, data)
    local tableCfg = skynet.call("CLCfg", "lua", "GETTABLESCFG", tableName)
    if tableCfg == nil then
        printe("[getUpdateSql],get tabel config is nil==" .. tableName)
        return nil
    end

    local where = {}

    if tableCfg.primaryKey then
        for i, pkey in ipairs(tableCfg.primaryKey) do
            local types = ""
            for j, col in ipairs(tableCfg.columns) do
                if pkey == col[1] then
                    types = col[2]:upper()
                    break
                end
            end

            if types:find("DEC") or types:find("INT") or types:find("FLOAT") or types:find("DOUBLE") or types:find("BOOL") then
                insert(where, "`" .. pkey .. "`=" .. (data[pkey] and data[pkey] or 0));
            else
                insert(where, "`" .. pkey .. "`=" .. (data[pkey] and "'" .. data[pkey] .. "'" or "NULL"));
            end
        end
    end
    local sql = "DELETE FROM " .. tableCfg.name .. " WHERE " .. concat(where, " AND ") .. ";"
    return sql
end

function command.STOP(exit)
    --command.FLUSHALL(false)
    if exit then
        skynet.exit()
    end
end

-- 设置数据缓存时间
function command.SETTIMEOUT(v)
    timeoutsec = v
end
-- ============================================================
skynet.start(function()
    skynet.dispatch("lua", function(session, address, cmd, ...)
        cmd = cmd:upper()
        local f = command[cmd]
        if f then
            skynet.ret(skynet.pack(f(...)))
        else
            error(string.format("Unknown command %s", tostring(cmd)))
        end
    end)

    skynet.fork(checktimeout, db, dbTimeout);
    skynet.register "CLDB"
end)
