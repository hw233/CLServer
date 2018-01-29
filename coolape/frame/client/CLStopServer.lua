package.cpath = "./skynet/luaclib/?.so"
package.path = "./skynet/lualib/?.lua;" .. "./coolape/frame/client/?.lua"

if _VERSION ~= "Lua 5.3" then
    error "Use lua 5.3"
end
local httpc = require("CLHttpc")
--httpc.timeout = 500	-- set timeout 1 second

if #arg < 3 then
    print("err:参数错误！！第一个参数是工程名，第二个参数是端口。")
    return
end
local projectName = arg[1]
local host = arg[2]
local port = arg[3]
local force = arg[4]

print(projectName, host, port)

-- 请求停服处理
local ok,result= pcall(httpc.get, host ..":"..port, "/"..projectName .. "/stopserver")
if not ok then
    print(result)
    if force then
        local stopcmd = "ps -ef|grep config_" .. projectName .. "|grep -v grep |awk '{print $2}'|xargs -n1 kill -9"
        io.popen(stopcmd)
    end
end
