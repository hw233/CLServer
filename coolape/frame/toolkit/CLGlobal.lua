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

function print(...)
    if logLev < LogLev.debug then
        return
    end
    local params = {...}
    if params == nil or #params == 0 then
        return skynet.error(params)
    end
    local trace = debug.traceback("")
    local msg = table.concat(params, "|")
    msg = msg or ""
    skynet.error("[debug]:" .. msg .. "\n" .. parseBackTrace(trace, logTraceLev))
end

function printw(...)
    if logLev < LogLev.warning then
        return
    end
    local params = {...}
    if params == nil or #params == 0 then
        return skynet.error(params)
    end
    local trace = debug.traceback("")
    local msg = table.concat(params, "|")
    msg = msg or ""
    skynet.error("[warn]:" .. msg .. "\n" .. parseBackTrace(trace, logTraceLev))
end

function printe(...)
    if logLev < LogLev.error then
        return
    end
    local params = {...}
    if params == nil or #params == 0 then
        return skynet.error(params)
    end
    local trace = debug.traceback("")
    local msg = table.concat(params, "|")
    msg = msg or ""
    skynet.error("[err]:" .. msg .. "\n" .. parseBackTrace(trace, logTraceLev))
end


