local skynet = require "skynet"

local max_client = 1024*1024

skynet.start(
function()
    skynet.error("Server start")
    if not skynet.getenv "daemon" then
        local console = skynet.newservice("console")
    end

    skynet.newservice("debug_console", 8003)

    -- 配制数据
    skynet.uniqueservice("CLCfg")

    -- 连接mysql
    local mysql = skynet.uniqueservice("CLMySQL")
    skynet.call(mysql, "lua", "connect", {
        host = "127.0.0.1",
        port = 3306,
        database = "island",
        user = "root",
        password = "123.",
        max_packet_size = 1024 * 1024,
        synchrotime = 0.5*60*100, -- 同步数据时间间隔 100=1秒
        isDebug = true,
    })

    -- 简单缓存数据库
    skynet.uniqueservice("CLDB")
    skynet.call("CLDB", "lua", "SETTIMEOUT", 1*60)     -- 半小时

    -- world Grid
    skynet.uniqueservice("LDSWorld")

    -- 监听socket
    local watchdog = skynet.uniqueservice("watchdog")
    skynet.call(watchdog, "lua", "start", {
        port = 9000, -- socket port
        maxclient = max_client,
        nodelay = true,
        mysql = mysql,
    })
    skynet.error("Watchdog listen on", 9000)

    -- http server
    skynet.newservice("myweb",
        8803, -- http port
        10 -- 代理个数
    )

    skynet.exit()
end
)
