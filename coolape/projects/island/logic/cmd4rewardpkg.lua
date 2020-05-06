---@class cmd4rewardpkg 奖励包服务
local logic = {}
local skynet = require("skynet")
require "db.dbrewardpkg"
require "db.dbrewardpkgplayer"
require "db.dbitems"
require "db.dbplayer"
local logic4city = require "logic4city"
local itemsServer  -- 道具的服务
local CMD = {}
------------------------------------------------
---public 创建一个奖励包
---@return table 返回奖励包的内容，是个list
logic.newPkg = function(list)
    if list == nil then
        return nil
    end
    local rwidx = DBUtl.nextVal(DBUtl.Keys.reward)
    local result = {}
    for i, v in ipairs(list) do
        table.insert(
            result,
            logic.newOne(
                rwidx,
                v[dbrewardpkg.keys.id],
                v[dbrewardpkg.keys.type],
                v[dbrewardpkg.keys.num],
                v[dbrewardpkg.keys.permillage]
            )
        )
    end
    return result
end

---public 新奖励包
logic.newOne = function(rwidx, id, type, num, permillage)
    local r = dbrewardpkg.new()
    r:init(
        {
            [dbrewardpkg.keys.idx] = DBUtl.nextVal(DBUtl.Keys.reward),
            [dbrewardpkg.keys.rwidx] = rwidx,
            [dbrewardpkg.keys.id] = id,
            [dbrewardpkg.keys.type] = type,
            [dbrewardpkg.keys.num] = num or 1,
            [dbrewardpkg.keys.permillage] = permillage or 1000
        },
        true
    )
    return r:release(true)
end

---public 取得奖励包信息
logic.getRewardPkgList = function(rwidx)
    return dbrewardpkg.getListByrwidx(rwidx)
end

logic.getItemsServer = function()
    if itemsServer == nil then
        itemsServer = skynet.newservice("cmd4items")
    end
    return itemsServer
end

---public 添加道具
logic.addItem = function(pidx, reward)
    logic.getItemsServer()

    skynet.call(
        itemsServer,
        "lua",
        "consumeItem",
        0,
        pidx,
        reward[dbrewardpkg.keys.id],
        reward[dbrewardpkg.keys.type],
        -1 * reward[dbrewardpkg.keys.num]
    )
end

---public 抽奖励（就是处理千分率）
---@return boolean 是否抽中
logic.lotteryRewardCell = function(pidx, idx)
    local rw = dbrewardpkg.instanse(idx)
    local player = dbplayer.instanse(pidx)
    local ret = false
    
    -- 千分率，处理掉落问题
    if numEx.nextInt(1, 1000) <= rw:get_permillage() then
        if rw:get_type() == IDConst.ItemType.attrVal then
            -- 直接加属性
            local attr = cfgUtl.getItemByID(rw:get_id())
            local resType = attr.Function
            if resType == IDConst.ResType.food or resType == IDConst.ResType.gold or resType == IDConst.ResType.oil then
                local res = {}
                res[IDConst.ResTypeKey[resType]] = -1 * rw:get_num() -- 负数就是增加
                logic4city.consumeRes(player:get_cityidx(), res)
            elseif resType == IDConst.ResType.exp then
                player:set_exp(player:get_exp() + rw:get_num())
            elseif resType == IDConst.ResType.honor then
                player:set_honor(player:get_honor() + rw:get_num())
            elseif resType == IDConst.ResType.diam then
                player:set_diam(player:get_diam() + rw:get_num())
            end
        else
            -- 添加到道具表里
            logic.addItem(pidx, rw:value2copy())
        end
        ret = true
    end
    -- 未抽中
    player:release()

    return ret, rw:release(true)
end

---public 领取奖励
---@return number Errcode
---@return table 奖励包信息
logic.receiveRewardpkg = function(pidx, rwidx)
    local res = {}
    local items = {}
    local list = logic.getRewardPkgList(rwidx)
    local output = {}
    local idx
    for i, v in ipairs(list) do
        idx = v[dbrewardpkg.keys.idx]
        -- 抽奖（千分率，处理掉落问题）
        if logic.lotteryRewardCell(pidx, idx) then
            -- 记录得到了那些奖励
            table.insert(output, v)
        end
    end

    -- 清除关系表
    local rwp = dbrewardpkgplayer.instanse(pidx, rwidx)
    rwp:delete()
    rwp = nil
    return Errcode.ok, output
end

logic.release = function(killself)
    if itemsServer then
        skynet.send(itemsServer, "lua", "release", true)
        itemsServer = nil
    end

    if killself then
        skynet.exit()
    end
end
------------------------------------------------
---@param m NetProtoIsland.RC_getRewardInfor
CMD.getRewardInfor = function(m, fd, agent)
    ---@type NetProtoIsland.ST_retInfor
    local ret = {}
    local pidx = getPlayerIdx(m.__session__)
    local rwidx = m.rwidx
    local rwp = dbrewardpkgplayer.instanse(pidx, rwidx)
    if rwp:isEmpty() then
        rwp:release()
        ret.code = Errcode.rewardNot4Player
        ret.msg = "该奖励包不属于此玩家"
        return pkg4Client(m, ret)
    end
    rwp:release()
    rwp = nil

    local list = logic.getRewardPkgList(rwidx)
    if #list == 0 then
        ret.code = Errcode.rewardIsNil
        ret.msg = "该奖励包为空"
        return pkg4Client(m, ret)
    end
    return pkg4Client(m, ret, list)
end

---@param m NetProtoIsland.RC_receiveReward
CMD.receiveReward = function(m, fd, agent)
    ---@type NetProtoIsland.ST_retInfor
    local ret = {}
    local pidx = getPlayerIdx(m.__session__)
    local rwidx = m.rwidx
    local rwp = dbrewardpkgplayer.instanse(pidx, rwidx)
    if rwp:isEmpty() then
        rwp:release()
        ret.code = Errcode.rewardNot4Player
        ret.msg = "该奖励包不属于此玩家"
        return pkg4Client(m, ret)
    end
    rwp:release()
    rwp = nil

    local code, list = logic.receiveRewardpkg(pidx, rwidx)
    ret.code = code
    ret.msg = ""
    return pkg4Client(m, ret, list)
end

------------------------------------------------
skynet.start(
    function()
        skynet.dispatch(
            "lua",
            function(_, _, command, ...)
                local f = CMD[command] or cmd4player[command]
                if f then
                    skynet.ret(skynet.pack(f(...)))
                else
                    error("cmd func is nil.cmd == " .. command)
                end
            end
        )
    end
)
