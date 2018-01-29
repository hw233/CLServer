-- 停服代码
local skynet = require "skynet"
local httpc = require "http.httpc"
local dns = require "skynet.dns"

if #arg < 3 then
    print("err:参数错误！！第一个参数是工程名，第二个参数是端口。")
    return
end
local projectName = arg[2]
local port = arg[3]

skynet.start(
        function()

            httpc.dns()    -- set dns server
            httpc.timeout = 100    -- set timeout 1 second
            local respheader = {}
            local status, body = httpc.get("127.0.0.1:" .. port, "/" .. projectName .. "/stop", respheader)

        end
)
