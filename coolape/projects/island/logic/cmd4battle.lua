---@class cmd4city
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
local IDConstVals = require("IDConstVals")
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
    targetCity.tiles = dbtile.getListBycidx(cidx)
    targetCity.buildings = dbbuilding.getListBycidx(cidx)

    -- -- 取得舰船数据
    local targetShips = {}
    for idx, building in pairs(targetCity.buildings) do
        if building[dbbuilding.keys.attrid] == IDConstVals.dockyardBuildingID then
            local jsonstr = building[dbbuilding.keys.valstr]
            if not (CLUtl.isNilOrEmpty(jsonstr) or jsonstr == "nil") then
                local shipsMap = json.decode(jsonstr)
                if shipsMap then
                    table.insert(targetShips, shipsMap)
                end
            end
        end
    end

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
        targetCity:value2copy(),
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
