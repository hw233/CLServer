local skynet = require "skynet"

local max_client = 1024

skynet.start(
function()
    skynet.error("Server start")
    if not skynet.getenv "daemon" then
        local console = skynet.newservice("console")
    end

    skynet.newservice("debug_console", 8000)

    -- 连接mysql
    local mysql = skynet.uniqueservice("CLMysql")
    skynet.call(mysql, "lua", "connect", {
        host = "127.0.0.1",
        port = 3306,
        database = "mibao",
        user = "root",
        password = "123.",
        max_packet_size = 1024 * 1024,
        synchrotime = 5*60*100,      -- 同步数据时间间隔 100=1秒
    })

    -- 简单缓存数据库
    skynet.uniqueservice("CLLDB")

    --
    local watchdog = skynet.newservice("watchdog")
    skynet.call(watchdog, "lua", "start", {
        port = 2018,
        maxclient = max_client,
        nodelay = true,
        mysql = mysql,
    })
    skynet.error("Watchdog listen on", 8888)
    skynet.exit()
end
)
