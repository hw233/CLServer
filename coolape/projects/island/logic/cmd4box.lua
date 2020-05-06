---@class cmd4box 宝箱
local logic = {}
local skynet = require("skynet")
require "errcode"
require "db.dbrewardpkg"
require "db.dbrewardpkgplayer"
require "db.dbbox"
---@type CLQuickSort
local Sort = require "CLQuickSort"

local logic4city = require "logic4city"

local CMD = {}
------------------------------------------------
---public 新宝箱
logic.newBox = function(rwidx, icon, namekey, desckey, maxOutput)
    local box = dbbox.new()
    box:init(
        {
            [dbbox.keys.idx] = DBUtl.nextVal(DBUtl.Keys.box),
            [dbbox.keys.rwidx] = rwidx,
            [dbbox.keys.icon] = icon,
            [dbbox.keys.nameKey] = namekey,
            [dbbox.keys.descKey] = desckey,
            [dbbox.keys.maxOutput] = maxOutput or -1
        },
        true
    )
    return box:release(true)
end

---public 打开宝箱
---@return number Errcode 返回code
---@return {NetProtoIsland.ST_rewardInfor} 物品列表
logic.openBox = function(pidx, idx)
    local box = dbbox.instanse(idx)
    if box:isEmpty() then
        box:release()
        return Errcode.boxIsNil
    end

    -- 奖励包的服务
    local rewardpkgServer = skynet.newservice("cmd4rewardpkg")
    -- 取得宝箱对应的奖励包数据
    local rewardpkgs = dbrewardpkg.getListByrwidx(box:get_rwidx())
    local recode, output
    if box:get_maxOutput() <= 0 then
        -- 不限制数量， 直接领取奖励包（就是在奖励包里抽奖）
        recode, output = skynet.call(rewardpkgServer, "lua", "receiveRewardpkg", pidx, box:get_rwidx())
    else
        -- 是要限制数量的
        -- 先按千分率由小到大排序（数值超大的掉落概率越大，1000可以理解为保底）
        Sort.quickSort(rewardpkgs, logic.compRewards)
        local output = {}
        for i, v in ipairs(rewardpkgs) do
            if #output >= box:get_maxOutput() then
                -- 已达最大掉落数量
                break
            end
            -- 千分率，处理掉落问题
            if skynet.call(rewardpkgServer, "lua", "lotteryRewardCell", pidx, v[dbrewardpkg.keys.idx]) then
                table.insert(output, v)
            end
        end
    end
    -- 释放服务
    skynet.send(rewardpkgServer, "lua", "release", true)
    rewardpkgServer = nil
    box:release()
    
    return recode, output
end

logic.compRewards = function(a, b)
    local permillage1 = a[dbrewardpkg.keys.permillage]
    local permillage2 = b[dbrewardpkg.keys.permillage]
    return permillage1 < permillage2
end

---public 释放
logic.release = function(killSelf)
    if killSelf then
        skynet.exit()
    end
end
------------------------------------------------

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
