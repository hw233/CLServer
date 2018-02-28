local skynet = require "skynet"
require "skynet.manager"    -- import skynet.register

local CMD = {}
local SOCKET = {}
local gate = nil
local agent = {}
local fdLastMsgTime = {}
local mysql;
local timeOutSec = 20;     -- socket超时时间(秒)

local function close_agent(fd)
    local a = agent[fd]
    agent[fd] = nil
    if a then
        skynet.call(gate, "lua", "kick", fd)
        -- disconnect never return
        skynet.send(a, "lua", "disconnect")
    end
    fdLastMsgTime[fd] = nil
end

local checkTimeOut = function(fdLastMsgTime)
    local currTime;
    while true do
        currTime = skynet.time()
        for fd, lasttime in pairs(fdLastMsgTime) do
            if currTime - lasttime > timeOutSec then
                close_agent(fd)
            end
        end
        skynet.sleep(timeOutSec)
    end
end

function SOCKET.open(fd, addr)
    skynet.error("New client from : " .. addr .. " fd==" .. fd)
    agent[fd] = skynet.newservice("agent")
    CMD.alivefd(fd)
    skynet.call(agent[fd], "lua", "start", { gate = gate, client = fd, mysql = mysql, watchdog = skynet.self() })
end

function SOCKET.close(fd)
    --print("socket close",fd)
    close_agent(fd)
end

function SOCKET.error(fd, msg)
    --print("socket error",fd, msg)
    close_agent(fd)
end

function SOCKET.warning(fd, size)
    -- size K bytes havn't send out in fd
    skynet.error("socket warning", fd, size)
end

function SOCKET.data(fd, msg)
    -- cannot gointo this logic
end

function CMD.start(conf)
    if gate == nil then
        gate = skynet.newservice("gate")
    end
    mysql = conf.mysql;
    skynet.call(gate, "lua", "open", conf)
end

function CMD.close(fd)
    close_agent(fd)
end

-- 标志某个fd还活着
function CMD.alivefd(fd)
    fdLastMsgTime[fd] = skynet.time()
end

-- 停服
function CMD.stop()
    -- 踢掉所有fd
    for fd, lasttime in pairs(fdLastMsgTime) do
        close_agent(fd)
    end
    -- 把网关停掉，以免有新的fd进来
    skynet.kill(gate)

    skynet.call("CLDB", "lua", "stop")
    skynet.call("CLMySQL", "lua", "stop")
    -- kill进程
    local projectname = skynet.getenv("projectName")
    local stopcmd = "ps -ef|grep config_" .. projectname .. "|grep -v grep |awk '{print $2}'|xargs -n1 kill -9"
    io.popen(stopcmd)
    skynet.exit()
end

skynet.start(function()
    skynet.fork( checkTimeOut, fdLastMsgTime );
    skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
        if cmd == "socket" then
            local f = SOCKET[subcmd]
            f(...)
            -- socket api don't need return
        else
            local f = assert(CMD[cmd])
            skynet.ret(skynet.pack(f(subcmd, ...)))
        end
    end)

    skynet.register "watchdog"
end)
