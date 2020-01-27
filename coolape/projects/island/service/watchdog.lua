local skynet = require "skynet"
require "skynet.manager" -- import skynet.register
require("Errcode")
require("public.include")

local CMD = {}
local SOCKET = {}
local gate = nil
local agents = {} -- fd:agent
local playersWithFd = {} -- pidx:fd
local fdWithPlayers = {} -- fd:pidx
local fdLastMsgTime = {}
local mysql
local timeOutSec = 300 -- socket超时时间(秒)

local function close_agent(fd)
    local a = agents[fd]
    agents[fd] = nil
    if a then
        skynet.call(gate, "lua", "kick", fd)
        -- disconnect never return
        skynet.send(a, "lua", "disconnect")
    end
    if fdWithPlayers[fd] then
        playersWithFd[fdWithPlayers[fd]] = nil
        fdWithPlayers[fd] = nil
    end
    fdLastMsgTime[fd] = nil
end

local checkTimeOut = function(fdLastMsgTime)
    local currTime
    while true do
        currTime = skynet.time()
        for fd, lasttime in pairs(fdLastMsgTime) do
            if currTime - lasttime > timeOutSec then
                close_agent(fd)
            end
        end
        skynet.sleep(timeOutSec * 100)
    end
end

function SOCKET.open(fd, addr)
    skynet.error("New client from : " .. addr .. " fd==" .. fd)
    agents[fd] = skynet.newservice("agent")
    CMD.alivefd(fd)
    skynet.call(agents[fd], "lua", "start", {gate = gate, client = fd, mysql = mysql, watchdog = skynet.self()})
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
    -- cannot go into this logic
end

function CMD.start(conf)
    if gate == nil then
        gate = skynet.newservice("gate")
    end
    mysql = conf.mysql
    skynet.call(gate, "lua", "open", conf)
end

function CMD.close(fd)
    close_agent(fd)
end

-- 标志某个fd还活着
function CMD.alivefd(fd)
    fdLastMsgTime[fd] = skynet.time()
end

function CMD.bindPlayer(pidx, fd)
    playersWithFd[pidx] = fd
    fdWithPlayers[fd] = pidx
end

---@public 玩家是否在线
function CMD.isPlayerOnline(pidx)
    local fd = playersWithFd[pidx]
    return fd and true or false
end

---@public 取得数据
function CMD.getAgent(pidx)
    local fd = playersWithFd[pidx]
    return fd and agents[fd] or nil
end

---@public 取得数据
function CMD.getPidx(fd)
    return fdWithPlayers[fd]
end

---@public 通知所有用户
function CMD.notifyAll(map)
    for k, agentServer in pairs(agents) do
        skynet.call(agentServer, "lua", "sendPackage", map)
    end
    return Errcode.ok
end

function CMD.getAllAgents()
    return agents
end

-- 停服
function CMD.stop()
    -- 踢掉所有fd
    for fd, lasttime in pairs(fdLastMsgTime) do
        close_agent(fd)
    end
    -- 把网关停掉，以免有新的fd进来
    skynet.kill(gate)

    skynet.call("CLDB", "lua", "stop", false)
    -- skynet.kill("CLDB")
    skynet.call("CLMySQL", "lua", "stop", false)
    skynet.kill("CLMySQL")
    -- kill进程
    local projectname = skynet.getenv("projectName")
    local stopcmd = "ps -ef|grep config_" .. projectname .. "|grep -v grep |awk '{print $2}'|xargs -n1 kill -9"
    io.popen(stopcmd)
    skynet.exit()
end

skynet.start(
    function()
        skynet.fork(checkTimeOut, fdLastMsgTime)
        skynet.dispatch(
            "lua",
            function(session, source, cmd, subcmd, ...)
                if cmd == "socket" then
                    -- socket api don't need return
                    local f = SOCKET[subcmd]
                    f(...)
                else
                    local f = assert(CMD[cmd])
                    skynet.ret(skynet.pack(f(subcmd, ...)))
                end
            end
        )

        skynet.register "watchdog"
    end
)
