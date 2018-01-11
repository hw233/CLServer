local skynet = require "skynet"
local socket = require "skynet.socket"
require("BioUtl")
require("NetProtoServer")
require("CLUtl")

local WATCHDOG

local CMD = {}
local client_fd
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

local function doProcCmd(map)
    for k, v in pairs(map) do
        --print(k, v)
    end
    local cmd = map[0]
    if cmd == nil then
        skynet.error("get cmd is nil");
        return nil;
    end
    local cmdInfor = NetProto.dispatch[cmd]
    if cmdInfor == nil then
        skynet.error("get protocol cfg is nil");
        return nil;
    end

    local m = cmdInfor.onReceive(map)
    local retInfor = { code = 0, msg = "" }
    local city = { id = 1, name = "city" }
    local userInfor = { id = 12, name = "大又", isNew = true, ver = 12}

    local sql = "INSERT INTO `user` (`idx`, `uid`, `password`) VALUES "
    .. " (0, '1', '11231');";
    skynet.call(mysql, "lua", "save", sql)
    local sql = "INSERT INTO `user` (`idx`, `uid`, `password`) VALUES "
    .. " (0, '12', '11232');";
    skynet.call(mysql, "lua", "save", sql)
    --skynet.call("CLMySQL", "lua", "flushall")

    m = NetProto.send.login(retInfor, userInfor, 9080)
    return m;
end

local function procCmd(map)
    local ok, result = pcall( doProcCmd, map)
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
    if Utl.isArray(m) then
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
    -- todo: do something before exit
    skynet.exit()
end

skynet.start(function()
    skynet.dispatch("lua", function(_, _, command, ...)
        local f = CMD[command]
        skynet.ret(skynet.pack(f(...)))
    end)
end)
