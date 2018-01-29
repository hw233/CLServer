package.cpath = "./skynet/luaclib/?.so"
package.path = "./skynet/lualib/?.lua;" .. "./coolape/frame/client/?.lua"

if _VERSION ~= "Lua 5.3" then
    error "Use lua 5.3"
end

local socket = require "client.socket"
local internal = require "http.internal"
--local dns = require "skynet.dns"
local string = string
local table = table

local readbytes = socket.recv
local writebytes = socket.send
local socket_error = "";

---@class CLHttpc
local CLHttpc = {}

local function preread(fd, str)
    return function (sz)
        if str then
            if sz == #str or sz == nil then
                local ret = str
                str = nil
                return ret
            else
                if sz < #str then
                    local ret = str:sub(1,sz)
                    str = str:sub(sz + 1)
                    return ret
                else
                    sz = sz - #str
                    local ret = readbytes(fd, sz)
                    if ret then
                        return str .. ret
                    else
                        print(socket_error)
                    end
                end
            end
        else
            local ret = readbytes(fd, sz)
            if ret then
                return ret
            else
                print(socket_error)
            end
        end
    end
end

local function readfunc(fd, pre)
    if pre then
        return preread(fd, pre)
    end
    return function (sz)
        local ret = readbytes(fd, sz)
        if ret then
            return ret
        else
            print(socket_error)
        end
        return ""
    end
end

local function writefunc(fd)
    return function(content)
        local ok = writebytes(fd, content)
        if not ok then
            print(socket_error)
        end
    end
end
--==============================================
local function request(fd, method, host, url, recvheader, header, content)
    local read = readfunc(fd)
    local write = writefunc(fd)
    local header_content = ""
    if header then
        if not header.host then
            header.host = host
        end
        for k, v in pairs(header) do
            header_content = string.format("%s%s:%s\r\n", header_content, k, v)
        end
    else
        header_content = string.format("host:%s\r\n", host)
    end

    if content then
        local data = string.format("%s %s HTTP/1.1\r\n%scontent-length:%d\r\n\r\n", method, url, header_content, #content)
        write(data)
        write(content)
    else
        local request_header = string.format("%s %s HTTP/1.1\r\n%scontent-length:0\r\n\r\n", method, url, header_content)
        write(request_header)
    end

    local tmpline = {}
    local body = internal.recvheader(read, tmpline, "")
    if not body then
        error(socket.socket_error)
    end

    local statusline = tmpline[1]
    local code, info = statusline:match "HTTP/[%d%.]+%s+([%d]+)%s+(.*)$"
    code = assert(tonumber(code))

    local header = internal.parseheader(tmpline, 2, recvheader or {})
    if not header then
        error("Invalid HTTP response header")
    end

    local length = header["content-length"]
    if length then
        length = tonumber(length)
    end
    local mode = header["transfer-encoding"]
    if mode then
        if mode ~= "identity" and mode ~= "chunked" then
            error ("Unsupport transfer-encoding")
        end
    end

    if mode == "chunked" then
        body, header = internal.recvchunkedbody(read, nil, header, body)
        if not body then
            error("Invalid response body")
        end
    else
        -- identity mode
        if length then
            if #body >= length then
                body = body:sub(1, length)
            else
                local padding = read(length - #body)
                body = body .. padding
            end
        else
            -- no content-length, read all
            body = body .. socket.recv(fd)
        end
    end

    return code, body
end

local async_dns

--function CLHttpc.dns(server,port)
--	async_dns = true
--	dns.server(server,port)
--end

function CLHttpc.request(method, host, url, recvheader, header, content)
    local timeout = CLHttpc.timeout    -- get CLHttpc.timeout before any blocked api
    local hostname, port = host:match"([^:]+):?(%d*)$"
    if port == "" then
        port = 80
    else
        port = tonumber(port)
    end
    if async_dns and not hostname:match(".*%d+$") then
        hostname = dns.resolve(hostname)
    end
    local fd = socket.connect(hostname, port, timeout)
    if not fd then
        error(string.format("http connect error host:%s, port:%s, timeout:%s", hostname, port, timeout))
        return
    end
    local finish
    if timeout then
        skynet.timeout(timeout, function()
            if not finish then
                socket.close(fd)    -- shutdown the socket fd, need close later.
            end
        end)
    end
    local ok, statuscode, body = pcall(request, fd, method, host, url, recvheader, header, content)
    finish = true
    socket.close(fd)
    if ok then
        return statuscode, body
    else
        error(statuscode)
    end
end

function CLHttpc.get(...)
    return CLHttpc.request("GET", ...)
end

local function escape(s)
    return (string.gsub(s, "([^A-Za-z0-9_])", function(c)
        return string.format("%%%02X", string.byte(c))
    end))
end

function CLHttpc.post(host, url, form, recvheader)
    local header = {
        ["content-type"] = "application/x-www-form-urlencoded"
    }
    local body = {}
    for k, v in pairs(form) do
        table.insert(body, string.format("%s=%s", escape(k), escape(v)))
    end

    return CLHttpc.request("POST", host, url, recvheader, header, table.concat(body, "&"))
end

return CLHttpc
