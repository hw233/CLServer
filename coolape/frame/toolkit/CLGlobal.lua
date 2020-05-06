local table = table
local skynet = require "skynet"
local string = string
local LogLev = {
    error = 1,
    warning = 2,
    debug = 3,
}
local logLev = LogLev[skynet.getenv("logLev") or "debug"] or LogLev.debug
local logTraceLev = tonumber(skynet.getenv("logTraceLev") or 3)

function parseBackTrace(traceInfor, level)
    if traceInfor and level > 1 then
        local traces = CLUtl.strSplit(traceInfor, "\n")
        if #traces >= level then
            local str = CLUtl.trim(traces[level])
            local sList = CLUtl.strSplit(str, ":")
            local file = sList[1]
            local line = sList[2]
            local func = sList[3] or ""
            --file = string.match(file, "/%a+%.%a+") or ""
            func = string.match(func, "'%a+'") or ""
            return file .. ":" .. line .. ":" .. func
        end
    end
    return traceInfor or ""
end

local wrapMsg = function (...)
    local tb = {}
    local v
    for i = 1, select("#", ...) do
        v = select(i, ...)
        if v or type(v) == "bool" then
            table.insert(tb, tostring(v))
        else
            table.insert(tb, "nil")
        end
    end
    return table.concat(tb, "|")
end

function print(...)
    if logLev < LogLev.debug then
        return
    end
    local msg = wrapMsg(...)
    msg = msg or ""
    local trace = debug.traceback("")
    skynet.error("[debug]:" .. msg .. "\n" .. parseBackTrace(trace, logTraceLev))
end

function printw(...)
    if logLev < LogLev.warning then
        return
    end
    local trace = debug.traceback("")
    local msg = wrapMsg(...)
    msg = msg or ""
    skynet.error("[warn]:" .. msg .. "\n" .. parseBackTrace(trace, logTraceLev))
end

function printe(...)
    if logLev < LogLev.error then
        return
    end
    local trace = debug.traceback("")
    local msg = wrapMsg(...)
    msg = msg or ""
    logTraceLev = 0 -- 表示所有层级
    
    skynet.error("[err]:" .. msg .. parseBackTrace(trace, logTraceLev))
    -- error("[err]:" .. msg .. parseBackTrace(trace, logTraceLev))
end


