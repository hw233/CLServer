---@class cmd4city
local cmd4battle = {}
local skynet = require("skynet")
require("public.include")
require("Errcode")
require("dbworldmap")
require("dbcity")
require("dbplayer")
local CMD = {}
local NetProtoIsland = "NetProtoIsland"

---@public 攻击
CMD.attack = function(map, fd, agent)
    local pos = map.pos
    local ret = {}
    ---@type dbworldmap
    local cell = dbworldmap.instanse(pos)
    if cell:isEmpty() then
        ret.code = Errcode.notFoundInWorld
        ret.msg = "世界地图中没找到玩家城"
        return skynet.call(NetProtoIsland, "lua", "send", map.cmd, ret, nil, nil, nil, nil, map)
    end
    local cidx = cell:get_cidx()
    cell:release()
    if cidx <= 0 then
        ret.code = Errcode.notFoundInWorld
        ret.msg = "世界地图中没找到玩家城2"
        return skynet.call(NetProtoIsland, "lua", "send", map.cmd, ret, nil, nil, nil, nil, map)
    end

    local cityServer = skynet.newservice("cmd4city")
    local targetCity = skynet.call(cityServer, "lua", "getSelf", cidx)
    local pidx = targetCity[dbcity.keys.pidx]
    local targetPlayer = dbplayer.instanse(pidx)
    --//TODO:判断能否攻击该玩家，比如是免战状态
    if targetPlayer:get_status() == IDConstVals.PlayerState.protect then
        targetCity:release()
        targetPlayer:release()
        skynet.call(cityServer, "lua", "release")
        ret.code = Errcode.protectedCannotAttack
        ret.msg = "玩家处在免战保护中，不可攻击"
        return skynet.call(NetProtoIsland, "lua", "send", map.cmd, ret, nil, nil, nil, nil, map)
    end
    local tiles = skynet.call(cityServer, "lua", "getSelfTiles")
    targetCity.tiles = tiles
    local buildings = skynet.call(cityServer, "lua", "getSelfBuildings")
    targetCity.buildings = buildings
    -- 取得舰船数据
    local targetShips = skynet.call(cityServer, "lua", "getAllShips")
    local myCityServer = skynet.call(agent, "lua", "getLogic", "cmd4city")
    local selfShips = skynet.call(myCityServer, "lua", "getAllShips")

    local retMsg =
        skynet.call(
        NetProtoIsland,
        "lua",
        "send",
        map.cmd,
        targetPlayer:value2copy(),
        targetCity,
        targetShips,
        selfShips,
        map
    )
    -- 释放资源
    targetCity:release()
    targetPlayer:release()
    skynet.call(cityServer, "lua", "release") -- 关闭服务
    return retMsg
end

CMD.release = function()
    skynet.exit()
end

skynet.start(
    function()
        skynet.dispatch(
            "lua",
            function(_, _, command, ...)
                local f = CMD[command]
                if f == nil then
                    error("func is nill.cmd =" .. command)
                else
                    skynet.ret(skynet.pack(f(...)))
                end
            end
        )
    end
)
