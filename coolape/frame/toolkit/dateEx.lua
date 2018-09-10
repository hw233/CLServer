﻿-- 时间
local skynet = require "skynet"
local string = string
---@class dateEx
dateEx = {}
dateEx.yy_mm_dd_HH_MM_SS = "%Y-%m-%d %H:%M:%S"
dateEx.yymmddHHMMSS = "%Y%m%d%H%M%S"
dateEx.yy_mm_dd = "%Y-%m-%d"
dateEx.yymmdd = "%Y%m%d"
dateEx.HH_MM_SS = "%H:%M:%S"
dateEx.HHMMSS = "%H%M%S"

---@public 当前时间的str
function dateEx.nowStr(format)
    format = format or dateEx.yy_mm_dd_HH_MM_SS
    return os.date(format, math.floor(skynet.time()))
end

---@public 秒数转成时间格式字符串
function dateEx.seconds2Str(sec, format)
    format = format or dateEx.yy_mm_dd_HH_MM_SS
    return os.date(format, sec)
end


---@public 时间格式字符转成秒数
function dateEx.str2Seconds(srcDateTime)
    --从日期字符串中截取出年月日时分秒
    local Y = string.sub(srcDateTime,1,4)
    local M = string.sub(srcDateTime,6,7)
    local D = string.sub(srcDateTime,9,10)
    local H = string.sub(srcDateTime,12,13)
    local MM = string.sub(srcDateTime,15,16)
    local SS = string.sub(srcDateTime,18,19)

    --把日期时间字符串转换成对应的日期时间
    local dt1 = os.time{year=Y, month=M, day=D, hour=H,min=MM,sec=SS}
    printe(dt1)
    return dt1
end

function dateEx.now()
    return skynet.time()
end

---@public 当前时间（毫秒）
function dateEx.nowMS()
    return skynet.time()*1000
end

return dateEx
