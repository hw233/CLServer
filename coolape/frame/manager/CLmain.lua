local skynet = require "skynet"

skynet.start(
        function()
            skynet.error("Server start")
            --if not skynet.getenv "daemon" then
            --    local console = skynet.newservice("console")
            --end

            --skynet.newservice("debug_console", 8000)

            -- http server
            skynet.newservice("CLweb",
                    8800, -- http port
                    2 -- 代理个数
            )

            skynet.exit()
        end
)
