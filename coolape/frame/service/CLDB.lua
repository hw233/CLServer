-- cache db
local skynet = require "skynet"
local sharedata = require "skynet.sharedata"
require "skynet.manager"    -- import skynet.register
local tablesdesign = "tablesdesign"
local db = {}
local dbTimeout = {}
local command = {}
local timeoutsec = 30 * 60;   -- 数据超时时间（秒）
local refreshsec = 1 * 60;   -- 数据更新时间（秒）
local insert = table.insert
local concat = table.concat

-- 处理超时的数据，把数据写入mysql
local function checktimeout(db, dbTimeout)
    while true do
        local now = skynet.time();
        local hasTimeout = false;
        for tName, timoutList in pairs(dbTimeout) do
            for key, time in pairs(timoutList) do
                if now > time then
                    -- 超时数据
                    local val = command.GET(tName, key)
                    if val then
                        local sql = command.GETUPDATESQL(tName, val)
                        skynet.call("CLMySQL", "lua", "save", sql)
                        timoutList[key] = nil;
                        command.REMOVE(tName, key)
                        hasTimeout = true;
                    end
                end
            end
        end

        if hasTimeout then
            skynet.call("CLMySQL", "lua", "FLUSHAll")
        end

        skynet.sleep(refreshsec)
    end
end

-- ============================================================
-- 取得数据.支持多个key
function command.GET(tableName, key, ...)
    local t = db[tableName]
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
    return t[key]
end

--[[
    设置数据.支持多个key，最后一个参数是要设置的value,例如：
    command.SET("user", "u001", "name", "小张")
    更新user表的key＝"u001"记录的，字段为name的值为"小张"
]]
function command.SET(tableName, key, ...)
    local t = db[tableName]
    if t == nil then
        t = {}
        db[tableName] = t
    end
    local params = { ... }
    if #params < 1 then
        skynet.error("[CLDB.SET] parmas error")
        return nil;
    end
    local count = #params
    local val = params[count]
    local subt = nil;
    for i = 1, count -1 do
        if t[params[i]] == nil then
            t[params[i]] = {}
        end
        t = t[params[i]]
    end
    local last = t[key]
    t[key] = val
    return last
end

-- 移除数据
function command.REMOVE(tableName, key)
    local t = db[tableName]
    if t then
        local last = t[key]
        t[key] = nil;
        return last
    end
end

-- 设置数据超时
function command.SETTIMEOUT(tableName, key)
    local t = dbTimeout[tableName]
    if t == nil then
        t = {}
        dbTimeout[tableName] = t
    end
    local last = t[key]
    t[key] = skynet.time() + timeoutsec;
    return last;
end

-- 移除数据超时
function command.REMOVETIMEOUT(tableName, key)
    local t = dbTimeout[tableName]
    if t == nil then
        t = {}
        dbTimeout[tableName] = t
    end
    local last = t[key]
    t[key] = nil
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
        command.REMOVETIMEOUT(tableName, key)
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


-- 生成insert的sql
function command.GETINSERTSQL(tableName, data)
    local tableCfg = skynet.call("CLCfg", "lua", "GETTABLESCFG", tableName)
    if tableCfg == nil then
        skynet.error("[getUpdateSql],get tabel config is nil==" .. tableName)
        return nil
    end

    local dataInsert = {}
    local columns = {}
    for i, v in ipairs(tableCfg.columns) do
        insert(columns, "`" .. v[1] .. "`" )
        local types = v[2]:upper()
        if types:find("INT") or types:find("FLOAT") or types:find("DOUBLE") then
            insert(dataInsert, (data[v[1]] and data[v[1]] or 0));
        else
            insert(dataInsert, (data[v[1]] and "'" .. data[v[1]] .. "'" or "NULL") );
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
        skynet.error("[getUpdateSql],get tabel config is nil==" .. tableName)
        return nil
    end

    local dataUpdate = {}
    local where = {}
    for i, v in ipairs(tableCfg.columns) do
        local types = v[2]:upper()
        if types:find("INT") or types:find("FLOAT") or types:find("DOUBLE") then
            insert(dataUpdate, "`" .. v[1] .. "`=" .. (data[v[1]] and data[v[1]] or 0));
        else
            insert(dataUpdate, "`" .. v[1] .. "`=" .. (data[v[1]] and "'" ..data[v[1]] .. "'" or "NULL"));
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

            if types:find("INT") or types:find("FLOAT") or types:find("DOUBLE") then
                insert(where, "`" .. pkey .. "`=" .. (data[pkey] and data[pkey] or 0));
            else
                insert(where, "`" .. pkey .. "`=" .. (data[pkey] and "'".. data[pkey] .. "'" or "NULL"));
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
        skynet.error("[getUpdateSql],get tabel config is nil==" .. tableName)
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

            if types:find("INT") or types:find("FLOAT") or types:find("DOUBLE") then
                insert(where, "`" .. pkey .. "`=" .. (data[pkey] and data[pkey] or 0));
            else
                insert(where, "`" .. pkey .. "`=" .. (data[pkey] and "'".. data[pkey] .. "'" or "NULL"));
            end
        end
    end
    local sql = "DELETE FROM " .. tableCfg.name .. " WHERE " .. concat(where, " AND ") .. ";"
    return sql
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

    skynet.fork( checktimeout, db, dbTimeout);
    skynet.register "CLDB"
end)
