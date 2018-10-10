local skynet = require "skynet"

local max_client = 1024 * 512
local dataSynSec = 30 -- 数据同步时间（秒）

skynet.start(
        function()
            skynet.error("Server start")
            if not skynet.getenv "daemon" then
                --local console = skynet.newservice("console")
            end
            local consoleport = skynet.getenv("consolePort")
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
                synchrotime = dataSynSec * 100, -- 同步数据时间间隔 100=1秒
                isDebug = true,
            })

            -- 网络接口
            skynet.uniqueservice("NetProtoUsermgrServer")

            -- 简单缓存数据库
            skynet.uniqueservice("CLDB")
            skynet.call("CLDB", "lua", "SETTIMEOUT", 20 * dataSynSec)     -- 设置数据缓存时间 秒

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
