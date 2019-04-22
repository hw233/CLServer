require("public.include")
require("Errcode")
local skynet = require "skynet"
local socket = require "skynet.socket"
local BioUtl = require("BioUtl")
local CLUtl = require("CLUtl")
---@type CLNetSerialize
local CLNetSerialize = require("CLNetSerialize")
local KeyCodeProtocol = require("KeyCodeProtocol")

local WATCHDOG
local LogicMap = {}
local CMD = {}
local client_fd  -- socket fd
local mysql

local function procCmd(map)
    if map == nil then
        return
    end
    local result = skynet.call("NetProtoIsland", "lua", "dispatcher", skynet.self(), map, client_fd)
    if result then
        local list = CLNetSerialize.package(result)
        for i, pkg in ipairs(list) do
            socket.write(client_fd, pkg)
        end
    else
        skynet.error(result)
    end
end

---@public 注册协议
skynet.register_protocol {
    name = "client",
    id = skynet.PTYPE_CLIENT,
    unpack = function(msg, sz)
        local bytes = skynet.tostring(msg, sz)
        return CLNetSerialize.unPackage(bytes)
        -- return BioUtl.readObject(bytes)
    end,
    dispatch = function(_, _, map, ...)
        skynet.call(WATCHDOG, "lua", "alivefd", client_fd)
        procCmd(map)
    end
}

function CMD.start(conf)
    skynet.error("start")
    local fd = conf.client
    local gate = conf.gate
    WATCHDOG = conf.watchdog
    mysql = conf.mysql

    client_fd = fd
    skynet.call(gate, "lua", "forward", fd)

    -- 设置net通信的配置
    CLNetSerialize.setCfg()
    CMD.notifyNetCfg()
end

function CMD.disconnect()
    print("agent disconnect. fd==" .. client_fd)
    for k, v in pairs(LogicMap) do
        skynet.call(v, "lua", "release")
    end
    LogicMap = {}

    skynet.exit()
end

-- 取得逻辑处理类
function CMD.getLogic(logicName)
    if logicName == "LDSWorld" then
        return logicName
    end
    local logic = LogicMap[logicName]
    if logic == nil then
        logic = skynet.newservice(logicName)
        LogicMap[logicName] = logic
    end
    return logic
end

-- 发送一个数据包给客户端
function CMD.sendPackage(map)
    local list = CLNetSerialize.package(map)
    if list then
        for i, pkg in ipairs(list) do
            socket.write(client_fd, pkg)
        end
    else
        printe("CMD.sendPackage the list is nil!")
    end
end

---@public 通知客户端网络配置
function CMD.notifyNetCfg()
    local cfg = CLNetSerialize.getCfg()
    local ret = {}
    ret.code = Errcode.ok
    local package = skynet.call("NetProtoIsland", "lua", "send", "sendNetCfg", ret, cfg)
    CMD.sendPackage(package)
end

skynet.start(
    function()
        skynet.dispatch(
            "lua",
            function(_, _, command, ...)
                local f = CMD[command]
                skynet.ret(skynet.pack(f(...)))
            end
        )
    end
)
