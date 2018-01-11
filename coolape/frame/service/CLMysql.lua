---
--- Created by chenbin.
--- DateTime: 17-12-31 下午7:13
---

local skynet = require "skynet"
require "skynet.manager"    -- import skynet.register
local mysql = require "skynet.db.mysql"
require("CLLQueue")

local CMD = {}
local db;
local sqlQueue = CLLQueue.new();
local synchrotime -- 数据同步时间

---------------------------------------------
-- 数据入库
local function storeData(db)
    local i = 1
    local sql = {}
    while true do
        if db and (not sqlQueue:isEmpty()) then
            sql = {}
            i = 1
            while (not sqlQueue:isEmpty()) and i < 100 do
                table.insert(sql, sqlQueue:deQueue())
                i = i + 1
            end
            local sqlstr = table.concat(sql, "\n")
            if sqlstr then
                local ret = db:query(sqlstr)
                if not ret then
                    skynet.error(dump(ret) .. "[" .. sqlstr .. "]")
                end
            end
            sql = {}
        end
        skynet.sleep(synchrotime)
    end
end
--[[
cfg={
        host="127.0.0.1",
        port=3306,
        database="mibao",
        user="root",
        password="123.",
        max_packet_size = 1024 * 1024,
        on_connect = on_connect,
        synchrotime = 500,      -- 同步数据时间间隔 100=1秒
    }
--]]
function CMD.CONNECT(cfg)
    local function on_connect(db)
        db:query("set charset utf8");
    end

    cfg.on_connect = on_connect
    synchrotime = cfg.synchrotime or 6000

    db = mysql.connect(cfg)
    if not db then
        skynet.error("failed to connect")
        return false
    end

    -- 启动一个线路保存数据
    skynet.fork( storeData, db);
    return true
end

-- 断开
function CMD.DISCONNECT()
    if db then
        db:disconnect()
        db = nil;
    end
end

-- 执行sql
function CMD.EXESQL(sql)
    if db and sql then
        return db:query(sql)
    end
    return nil;
end

-- 保数据
function CMD.SAVE(sql, immediately)
    if immediately then
        CMD.EXESQL(sql)
    else
        sqlQueue:enQueue(sql)
    end
end

-- 保存所有数据
function CMD.FLUSHALL()
    if db then
        local sql = {};
        while (not sqlQueue:isEmpty()) do
            table.insert(sql, sqlQueue:deQueue())
        end

        local sqlstr = table.concat(sql, "\n")
        if sqlstr then
            local error, result = pcall(CMD.EXESQL, sqlstr)
            if not error then
                skynet.error(result .. "[" .. sqlstr .. "]")
            end
        end
    end
end
---------------------------------------------
skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        cmd = cmd:upper()
        local f = assert(CMD[cmd])
        skynet.ret(skynet.pack(f(...)))
    end)

    skynet.register "CLMySQL"
end)
