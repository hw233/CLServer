local skynet = require "skynet"

local max_client = 1024*512

skynet.start(
function()
    skynet.error("Server start")
    if not skynet.getenv "daemon" then
        local console = skynet.newservice("console")
    end
    local consoleport =  skynet.getenv("consolePort")
    skynet.newservice("debug_console", consoleport)

    -- 配制数据
    skynet.uniqueservice("CLCfg")

    -- 连接mysql
    local mysql = skynet.uniqueservice("CLMySQL")
    skynet.call(mysql, "lua", "connect", {
        host = "127.0.0.1",
        port = 3306,
        database = "usermgr",
        user = "root",
        password = "123.",
        max_packet_size = 1024 * 1024,
        synchrotime = 0.5*60*100, -- 同步数据时间间隔 100=1秒
        isDebug = true,
    })

    -- 网络接口
    skynet.uniqueservice("NetProtoUsermgrServer")

    -- 简单缓存数据库
    skynet.uniqueservice("CLDB")
    -- 服务器管理
    skynet.uniqueservice("servermgr")

    -- 监听socket
    --local watchdog = skynet.uniqueservice("watchdog")
    --skynet.call(watchdog, "lua", "start", {
    --    port = 2018, -- socket port
    --    maxclient = max_client,
    --    nodelay = true,
    --    mysql = mysql,
    --})
    --skynet.error("Watchdog listen on", 2018)

    -- http server
    skynet.newservice("myweb",
            skynet.getenv("httpPort"), -- http port
        20 -- 代理个数
    )

    skynet.exit()
end
)
