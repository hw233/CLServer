-- 时间
local skynet = require "skynet"
---@class dateEx
dateEx = {}
dateEx.yy_mm_dd_HH_MM_SS = "%Y-%m-%d %H:%M:%S"
dateEx.yymmddHHMMSS = "%Y%m%d%H%M%S"
dateEx.yy_mm_dd = "%Y-%m-%d"
dateEx.yymmdd = "%Y%m%d"
dateEx.HH_MM_SS = "%H:%M:%S"
dateEx.HHMMSS = "%H%M%S"

-- 当前时间的str
function dateEx.nowStr(format)
    format = format or dateEx.yy_mm_dd_HH_MM_SS
    return os.date(format, math.floor(skynet.time()))
end

-- 当前时间（毫秒）
function dateEx.nowMS()
    return skynet.time()*1000
end

return dateEx;
