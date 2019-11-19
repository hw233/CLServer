local skynet = require("skynet")
require "skynet.manager" -- import skynet.register
require("XXTEA")
require("base64")
---@type CLUtl
local CLUtl = require("CLUtl")
local DBUtl = require "DBUtl"
---@type dateEx
local dateEx = require("dateEx")
require("CLGlobal")

-- 取得参数
local parmas = { ... }
local xxteaKey = nil
if #parmas > 0 then
    xxteaKey = parmas[1]
end

---@class CLSessionMgr 会话管理
local CLSessionMgr = {}
local data = {}
local CMD = {}
local defaultTime = 3600 * 3 -- 秒
local refreshTime = 3600 * 3 * 100

local function checktimeout()
    while (true) do
        for k, v in pairs(data) do
            local diff = dateEx.nowMS() - v
            if diff >= defaultTime * 1000 then
                data[k] = nil
            end
        end
        skynet.sleep(refreshTime)
    end
end

function CMD.GETBYID(id)
    if not id then
        return
    end
    local session = base64.encode(XXTEA.encrypt(tostring(id), xxteaKey))
    return CMD.GET(session)
end

function CMD.GET(session)
    if (not session) or (not data[session]) then
        return nil
    end
    local bytes = base64.decode(session)
    local id = XXTEA.decrypt(bytes, xxteaKey)
    return {id = id, loginTime = data[session]}
end

function CMD.SET(id)
    if not id then
        return
    end
    local session = base64.encode(XXTEA.encrypt(tostring(id), xxteaKey))
    data[session] = dateEx.nowMS()
    return session
end

function CMD.DELETE(session)
    data[session] = nil
end

---@public 会话是否有效
---@param timeOutSec number 超时时间（单位秒），为nil时者使用默认超时时间
function CMD.VALID(session, timeOutSec)
    if (not session) or (not data[session]) then
        return false
    end
    timeOutSec = timeOutSec or defaultTime
    local diff = dateEx.nowMS() - data[session]
    if diff >= timeOutSec * 1000 then
        data[session] = nil
        return false
    end
    return true
end

-- ============================================================
skynet.start(
    function()
        skynet.dispatch(
            "lua",
            function(session, address, cmd, ...)
                cmd = cmd:upper()
                local f = CMD[cmd]
                if f then
                    skynet.ret(skynet.pack(f(...)))
                else
                    error(string.format("Unknown command %s", tostring(cmd)))
                end
            end
        )

        skynet.fork(checktimeout)
        skynet.register "CLSessionMgr"
    end
)
