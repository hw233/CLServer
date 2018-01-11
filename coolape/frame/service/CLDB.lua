local skynet = require "skynet"
require "skynet.manager"    -- import skynet.register
local db = {}
local dbTimeout = {}
local command = {}
local timeoutsec = 30 * 60;   -- 数据超时时间（秒）

-- 处理超时的数据，把数据写入mysql
local function checktimeout(db, dbTimeout)
    local now = skynet.time();
    local hasTimeout = false;
    for tName, timoutList in pairs(dbTimeout) do
        for key, time in pairs(timoutList) do
            if now > time then
                -- 超时数据
                local val = command.GET(tName, key)
                if val then
                    skynet.call("CLMySQL", "lua", "save", val:toSql())
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
end

-- 取得数据
function command.GET(tableName, key)
    local t = db[tableName]
    if t then
        return t[key]
    end
    return nil;
end

-- 设置数据
function command.SET(tableName, key, value)
    local t = db[tableName]
    if t == nil then
        t = {}
        db[tableName] = t
    end
    local last = t[key]
    t[key] = value
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
        if immd then
            skynet.call("CLMySQL", "lua", "exeSql", val:toSql())
        else
            skynet.call("CLMySQL", "lua", "save", val:toSql())
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
                skynet.call("CLMySQL", "lua", "save", val:toSql())
                timoutList[key] = nil;
                command.REMOVE(tName, key)
            end
        end
    end
    if immd then
        skynet.call("CLMySQL", "lua", "FLUSHAll");
    end
end

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
