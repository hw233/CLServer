local skynet = require "skynet"
require "skynet.manager" -- import skynet.register
local socket = require "skynet.socket"
local reload = require "reload"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local table = table
local string = string
local webList = {} -- 代码缓存

local agentserver  -- 代理
local socketId = 0
local port = skynet.getenv("httpPort") -- http port
local agentSize = 3 -- 代理个数
local mode

local parmas = {...}
if #parmas > 1 then
    port = parmas[1]
    agentSize = parmas[2]
    mode = ""
else
    mode = parmas[1]
end

-- ================================================
-- ================================================
---public 重载服务
local reloadConsole = function(serverName)
    for i, g in ipairs(webList) do
        skynet.send(g, "lua", 0, "reloadConsole", serverName)
    end
    return true
end

-- ================================================
-- ================================================
if mode == "agent" then
    local function response(fd, ...)
        local ok, err = httpd.write_response(sockethelper.writefunc(fd), ...)
        if not ok then
            -- if err == sockethelper.socket_error , that means socket closed.
            skynet.error(string.format("fd = %d, %s", fd, err))
        end
    end

    local function setUft8(header)
        header["Content-Type"] = "text/html; charset=utf-8"
        return header
    end

    skynet.start(
        function()
            agentserver = skynet.newservice("agenthttp")
            skynet.dispatch(
                "lua",
                function(_, _, fd, cmd, ...)
                    -- print(fd)
                    -- print(cmd)
                    if cmd == nil or cmd == "" then
                        socket.start(fd)
                        -- limit request body size to 8192 (you can pass nil to unlimit)
                        local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(fd), 8192)
                        if code then
                            if code ~= 200 then
                                response(fd, code)
                            else
                                local result = skynet.call(agentserver, "lua", "onrequset", url, method, header, body)
                                response(fd, code, result, setUft8({}))
                            end
                        else
                            if url == sockethelper.socket_error then
                                skynet.error("socket closed")
                            else
                                skynet.error(url)
                            end
                        end
                        socket.close(fd)
                    else
                        if cmd == "reloadConsole" then
                            -- 重载服务
                            skynet.send(agentserver, "lua", "reloadServer", ...)
                        end
                    end
                end
            )
        end
    )
else
    -- print("============121212121========================")
    skynet.start(
        function()
            for i = 1, agentSize do
                webList[i] = skynet.newservice(SERVICE_NAME, "agent")
            end
            local balance = 1
            socketId = socket.listen("0.0.0.0", port)
            skynet.error("Listen web port " .. port)
            socket.start(
                socketId,
                function(fd, addr)
                    -- skynet.error(string.format("%s connected, pass it to agent :%08x", addr, webList[balance]))
                    skynet.send(webList[balance], "lua", fd)
                    balance = balance + 1
                    if balance > #webList then
                        balance = 1
                    end
                end
            )
            ------------------------------------------------------------
            skynet.dispatch(
                "lua",
                function(_, _, command, ...)
                    if command == "reloadConsole" then
                        skynet.ret(skynet.pack(reloadConsole(...)))
                    end
                end
            )
            skynet.register "myweb"
        end
    )
end
