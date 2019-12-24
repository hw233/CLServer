---@class cmd4battle
local cmd4battle = {}
local skynet = require("skynet")
require "skynet.manager" -- import skynet.register
require("public.include")
require("Errcode")
require("dbworldmap")
require("dbcity")
require("dbtile")
require("dbbuilding")
require("dbplayer")
require("dbunit")
local IDConstVals = require("IDConstVals")
local CMD = {}
local NetProtoIsland = skynet.getenv("NetProtoName")

---@public 攻击
---@param map NetProtoIsland.RC_attack
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

    local targetCity = dbcity.instanse(cidx)
    local pidx = targetCity:get_pidx()
    local targetPlayer = dbplayer.instanse(pidx)
    --//TODO:判断能否攻击该玩家，比如是免战状态
    if targetPlayer:get_status() == IDConstVals.PlayerState.protect then
        targetCity:release()
        targetPlayer:release()
        ret.code = Errcode.protectedCannotAttack
        ret.msg = "玩家处在免战保护中，不可攻击"
        return skynet.call(NetProtoIsland, "lua", "send", map.cmd, ret, nil, nil, nil, nil, map)
    end
    local targetCityVal = targetCity:value2copy()
    targetCityVal.tiles = dbtile.getListBycidx(cidx)
    targetCityVal.buildings = dbbuilding.getListBycidx(cidx)

    --------------------------------------------------
    -- 取得舰船数据
    -- 取被攻击方的舰船数据(只需要联盟里的舰船会出来)
    ---@type NetProtoIsland.ST_dockyardShips
    local targetShips = {}
    for idx, building in pairs(targetCityVal.buildings) do
        if building[dbbuilding.keys.attrid] == IDConstVals.AllianceID then
            targetShips.buildingIdx = building[dbbuilding.keys.idx]
            targetShips.ships = dbunit.getListBybidx(building[dbbuilding.keys.idx])
            break
        end
    end

    -- 取得自己的战斗单元
    local myCityServer = skynet.call(agent, "lua", "getLogic", "cmd4city")
    local selfShips = skynet.call(myCityServer, "lua", "getAllShips")

    ret.code = Errcode.ok
    local retMsg =
        skynet.call(
        NetProtoIsland,
        "lua",
        "send",
        map.cmd,
        ret,
        targetPlayer:value2copy(),
        targetCityVal,
        targetShips,
        selfShips,
        map
    )
    -- 释放资源
    targetCity:release()
    targetPlayer:release()
    return retMsg
end

CMD.release = function()
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
