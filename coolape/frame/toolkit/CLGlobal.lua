local skynet = require "skynet"

function print(msg)
    msg = msg or ""
    skynet.error("[debug]:" .. msg)
end
function printe(msg)
    msg = msg or ""
    skynet.error("[err]:" .. msg)
end

function printw(msg)
    msg = msg or ""
    skynet.error("[warn]:" .. msg)
end
