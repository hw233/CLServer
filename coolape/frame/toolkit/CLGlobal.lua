local skynet = require "skynet"

local LogLev = {
    error = 1,
    warning = 2,
    debug = 3,
}
local logLev = LogLev[skynet.getenv("logLev") or "debug"] or LogLev.debug

function print(msg)
    if logLev < LogLev.debug then return end
    msg = msg or ""
    skynet.error("[debug]:" .. msg)
end

function printw(msg)
    if logLev < LogLev.warning then return end
    msg = msg or ""
    skynet.error("[warn]:" .. msg)
end

function printe(msg)
    if logLev < LogLev.error then return end
    msg = msg or ""
    skynet.error("[err]:" .. msg)
end

