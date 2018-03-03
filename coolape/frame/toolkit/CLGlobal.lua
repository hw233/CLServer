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
            file = string.match(file, "/%a+%.%a+") or ""
            func = string.match(func, "'%a+'") or ""
            return file .. ":" .. line .. ":" .. func
        end
    end
    return ""
end

function print(msg)
    local trace = debug.traceback("")
    if logLev < LogLev.debug then
        return
    end
    msg = msg or ""
    skynet.error("[debug:" .. parseBackTrace(trace, 3) .. "]:" .. msg)
end

function printw(msg)
    if logLev < LogLev.warning then
        return
    end
    msg = msg or ""
    skynet.error("[warn:" .. parseBackTrace(trace, 3) .. "]:" .. msg)
end

function printe(msg)
    if logLev < LogLev.error then
        return
    end
    msg = msg or ""
    skynet.error("[err:" .. parseBackTrace(trace, 3) .. "]:" .. msg)
end


