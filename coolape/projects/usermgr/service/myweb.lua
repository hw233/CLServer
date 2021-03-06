local skynet = require "skynet"
local socket = require "skynet.socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local table = table
local string = string

local agentserver -- 代理
local parmas = { ... }
local port
local agentSize
local mode
if #parmas > 1 then
    port = parmas[1]
    agentSize = parmas[2]
    mode = ""
else
    mode = parmas[1]
end

-- ================================================
-- ================================================
if mode == "agent" then
    local function response(id, ...)
        local ok, err = httpd.write_response(sockethelper.writefunc(id), ...)
        if not ok then
            -- if err == sockethelper.socket_error , that means socket closed.
            skynet.error(string.format("fd = %d, %s", id, err))
        end
    end

    local function setUft8(header)
        header["Content-Type"] = "text/html; charset=utf-8"
        return header;
    end

    skynet.start(function()
        agentserver = skynet.newservice("agenthttp")
        skynet.dispatch("lua", function(_, _, id)
            socket.start(id)
            -- limit request body size to 8192 (you can pass nil to unlimit)
            local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 8192)
            if code then
                if code ~= 200 then
                    response(id, code)
                else
                    local result = skynet.call(agentserver, "lua", "onrequset", url, method, header, body)
                    response(id, code, result, setUft8({}))
                end
            else
                if url == sockethelper.socket_error then
                    skynet.error("socket closed")
                else
                    skynet.error(url)
                end
            end
            socket.close(id)
        end)
    end)
else
    port = port
    agentSize = agentSize or 5
    skynet.start(function()
        local agent = {}
        for i = 1, agentSize do
            agent[i] = skynet.newservice(SERVICE_NAME, "agent")
        end
        local balance = 1
        local id = socket.listen("0.0.0.0", port)
        skynet.error("Listen web port " .. port)
        socket.start(id, function(id, addr)
            skynet.error(string.format("%s connected, pass it to agent :%08x", addr, agent[balance]))
            skynet.send(agent[balance], "lua", id)
            balance = balance + 1
            if balance > #agent then
                balance = 1
            end
        end)
    end)

end
