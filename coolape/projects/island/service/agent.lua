local skynet = require "skynet"
require "skynet.manager" -- import skynet.register
local socket = require "skynet.socket"
require("public.include")
require("Errcode")
local BioUtl = require("BioUtl")
local CLUtl = require("CLUtl")
require("dbplayer")
---@type CLNetSerialize
local CLNetSerialize = require("CLNetSerialize")
local KeyCodeProtocol = require("KeyCodeProtocol")

local WATCHDOG
local LogicMap = {}
local CMD = {}
local client_fd  -- socket fd
local mysql
---@type NetProtoIsland.ST_player
local player
local NetProtoName = skynet.getenv("NetProtoName")

---@public 处理接口指令
local function procCmd(map)
    if map == nil then
        return false
    end
    local result = skynet.call(NetProtoName, "lua", "dispatcher", skynet.self(), map, client_fd)
    if result then
        local list = CLNetSerialize.package(result)
        for i, pkg in ipairs(list) do
            socket.write(client_fd, pkg)
        end
        return true
    else
        skynet.error(result)
        return false
    end
end

---@public 注册协议
skynet.register_protocol {
    name = "client",
    id = skynet.PTYPE_CLIENT,
    unpack = function(msg, sz)
        local bytes = skynet.tostring(msg, sz)
        return CLNetSerialize.unPackage(bytes)
        -- skynet.tostring will copy msg to a string, so we must free msg here.
        -- skynet.trash(msg, sz)
    end,
    dispatch = function(fd, source, map, ...)
        assert(fd == client_fd) -- You can use fd to reply message
        skynet.ignoreret() -- session is fd, don't call skynet.ret
        -- skynet.trace()

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

---@public 客户端连接断开
function CMD.disconnect()
    print("agent disconnect. fd==" .. client_fd)
    for k, v in pairs(LogicMap) do
        if skynet.address(v) then
            skynet.call(v, "lua", "release")
            skynet.kill(v)
        end
    end
    LogicMap = {}
    -- 通知大地图服移除我
    skynet.call("LDSWorld", "lua", "rmPlayerCurrLook4WorldPage", skynet.self())
    local pidx = (player and player.idx or nil)
    skynet.call("LDSWorld", "lua", "onPlayerOffline", pidx, client_fd, skynet.self())
    skynet.exit()
end

---@param _player NetProtoIsland.ST_player
function CMD.onLogin(_player)
    player = _player
    skynet.call(WATCHDOG, "lua", "bindPlayer", player.idx, client_fd)
end

function CMD.log(msg)
    if player then
        printe(msg .. "pidx=[" .. player[dbplayer.keys.idx] .. "] name=[" .. player[dbplayer.keys.name] .. "]")
    else
        printe(msg)
    end
end

---@public 取得逻辑处理类
function CMD.getLogic(logicName)
    if logicName == "LDSWorld" then
        -- 全局服务器（已经启动了），直接返回
        return logicName
    end
    local logic = LogicMap[logicName]
    if logic == nil or skynet.address(logic) == nil then
        logic = skynet.newservice(logicName)
        LogicMap[logicName] = logic
    end
    return logic
end

---@public 关闭某个逻辑服务
function CMD.stopLogic(logicName)
    local logic = LogicMap[logicName]
    if logic then
        if skynet.address(logic) then
            skynet.call(logic, "lua", "release")
            skynet.kill(logic)
        end
    end
    LogicMap[logicName] = nil
end

---@public 发送一个数据包给客户端
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
    local package = pkg4Client({cmd = "sendNetCfg"}, ret, cfg, dateEx.nowMS())
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
