local skynet = require "skynet"
local string = string
local LogLev = {
    error = 1,
    warning = 2,
    debug = 3,
}
local logLev = LogLev[skynet.getenv("logLev") or "debug"] or LogLev.debug

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
    return ""
end

function print(...)
    if logLev < LogLev.debug then
        return
    end
    local trace = debug.traceback("")
    local msg = table.concat({...}, "|")
    msg = msg or ""
    skynet.error("[debug]:" .. msg .. "\n" .. parseBackTrace(trace, 3))
end

function printw(...)
    if logLev < LogLev.warning then
        return
    end
    local trace = debug.traceback("")
    local msg = table.concat({...}, "|")
    msg = msg or ""
    skynet.error("[warn]:" .. msg .. "\n" .. parseBackTrace(trace, 3))
end

function printe(...)
    if logLev < LogLev.error then
        return
    end
    local trace = debug.traceback("")
    local msg = table.concat({...}, "|")
    msg = msg or ""
    skynet.error("[err]:" .. msg .. "\n" .. parseBackTrace(trace, 3))
end


