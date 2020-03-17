---@public 当服务器启动后的初始化
local skynet = require("skynet")
require "skynet.manager" -- import skynet.register
require("public.include")
require "db.dbplayer"

---@public 添加gm账号
local addGMPlayerIfNotExist = function()
    local gmPidx = IDConst.gmPidx
    local player = dbplayer.instanse(gmPidx)
    if not player:isEmpty() then
        -- 说明已经有gm账号了
        return
    end
    local playerServer = skynet.newservice("cmd4player")
    ---@type NetProtoIsland.RC_login
    local p = {}
    p.uidx = gmPidx
    p.channel = "0000"
    p.isEditMode = false
    p.deviceID = ""
    skynet.call(playerServer, "lua", "newPlayer", p, IDConst.PlayerType.gm)
    player = dbplayer.instanse(gmPidx)

    -- 新建城市
    local cityServer = skynet.newservice("cmd4city")
    local city = skynet.call(cityServer, "lua", "new", gmPidx)
    player:set_cityidx(city.idx)

    player:release()

    skynet.call(playerServer, "lua", "release")
    skynet.kill(playerServer)

    skynet.call(cityServer, "lua", "release")
    skynet.kill(cityServer)
end

skynet.start(
    function()
        -- 如果没有GM账号就添加
        addGMPlayerIfNotExist()
        -- //TODO：其它的初如化处理

        skynet.exit()
    end
)
