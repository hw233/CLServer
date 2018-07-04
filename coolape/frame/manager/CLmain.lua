local skynet = require "skynet"

skynet.start(
        function()
            skynet.error("Server start")
            --if not skynet.getenv "daemon" then
            --    local console = skynet.newservice("console")
            --end

            --skynet.newservice("debug_console", skynet.getenv("consolePort"))

            -- http server
            skynet.newservice("CLweb",
                    skynet.getenv("httpPort"), -- http port
                    2 -- 代理个数
            )

            skynet.exit()
        end
)
