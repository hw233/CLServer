local skynet = require "skynet"
local socket = require "skynet.socket"
local BioUtl = require("BioUtl")
---@type NetProtoIsland
local NetProto =  require("NetProtoIslandServer")
local CLUtl = require("CLUtl")
local KeyCodeProtocol = require("KeyCodeProtocol")

local WATCHDOG

local CMD = {}
local client_fd     -- socket fd
local mysql
local strLen = string.len;
local strSub = string.sub;
local strPack = string.pack
local maxPackSize = 64 * 1024 - 1;
local subPackSize = 64 * 1024 - 1 - 50;

local function send_package(pack)
    if pack == nil then
        return
    end
    local bytes = BioUtl.writeObject(pack)
    local len = strLen(bytes)
    if len > maxPackSize then
        local subPackgeCount = math.floor(len / subPackSize)
        local left = len % subPackSize
        for i = 1, subPackgeCount do
            local subPackg = {}
            table.insert(subPackg, subPackgeCount);
            table.insert(subPackg, i);
            table.insert(subPackg, strSub(bytes, ((i - 1) * subPackSize) + 1, i * subPackSize));
            local package = strPack(">s2", BioUtl.writeObject(subPackg))
            socket.write(client_fd, package)
        end
        if left > 0 then
            local subPackg = {}
            table.insert(subPackg, subPackgeCount);
            table.insert(subPackg, subPackgeCount + 1);
            table.insert(subPackg, strSub(bytes, (subPackgeCount  * subPackSize) + 1, subPackgeCount * subPackSize + left));
            local package = strPack(">s2", BioUtl.writeObject(subPackg))
            socket.write(client_fd, package)
        end
    else
        local package = strPack(">s2", bytes)
        socket.write(client_fd, package)
    end
end

local function procCmd(map)
    --for k, v in pairs(map) do
    --    print(k, v)
    --end
    local ok, result = pcall(NetProto.dispatcher, map, client_fd)
    if ok then
        if result then
            send_package(result)
        end
    else
        skynet.error(result)
    end
end

-- 完整的接口都是table，当有分包的时候会收到list。list[1]=共有几个分包，list[2]＝第几个分包，list[3]＝ 内容
local function isSubPackage(m)
    if m[0] then --判断有没有cmd
        return false
    end
    if CLUtl.isArray(m) then
        return true;
    end
    return false
end

--[[ 处理分包的情况
-- 完整的接口都是table，当有分包的时候会收到list。list[1]=共有几个分包，list[2]＝第几个分包，list[3]＝ 内容
--]]
local currPack = {};
local function procPackage(m)
    if m == nil then
        return
    end

    if isSubPackage(m) then
        -- 是分包
        local len = m[1]
        local index = m[2]
        table.insert(currPack, index, m[3])
        if (#currPack == len) then
            -- 说明分包已经取完整
            local bytes = table.concat(currPack, "")
            local map = BioUtl.readObject(bytes)
            currPack = nil;
            currPack = {}
            procCmd(map);
        end
    else
        procCmd(m)
    end
end

skynet.register_protocol {
    name = "client",
    id = skynet.PTYPE_CLIENT,
    unpack = function(msg, sz)
        local bytes = skynet.tostring(msg, sz);
        return BioUtl.readObject(bytes)
    end,
    dispatch = function(_, _, map, ...)
        skynet.call(WATCHDOG, "lua", "alivefd", client_fd)
        pcall(procPackage, map);
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
end

function CMD.disconnect()
    local map = {}
    map[0] = KeyCodeProtocol.getKeyCode("release")
    NetProto.dispatcher(map, client_fd)

    skynet.exit()
end

skynet.start(function()
    skynet.dispatch("lua", function(_, _, command, ...)
        local f = CMD[command]
        skynet.ret(skynet.pack(f(...)))
    end)
end)
