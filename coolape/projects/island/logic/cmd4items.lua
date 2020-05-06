---@class cmd4items 道具背包
local logic = {}
local skynet = require("skynet")
require "errcode"
require "db.dbrewardpkg"
require "db.dbrewardpkgplayer"
require "db.dbitems"
require "db.dbitemsused"
require "db.dbplayer"
local logic4city = require "logic4city"

local CMD = {}
------------------------------------------------
logic.newItem = function(pidx, id, type, num)
    local item = dbitems.new()
    item:init(
        {
            [dbitems.keys.idx] = DBUtl.nextVal(DBUtl.Keys.item),
            [dbitems.keys.pidx] = pidx,
            [dbitems.keys.id] = id,
            [dbitems.keys.type] = type,
            [dbitems.keys.num] = num
        },
        true
    )
    logic.onItemChg(item:get_idx())
    return item:release(true)
end

---public 取得道具数据
logic.getItemData = function(idx)
    local item = dbitems.instanse(idx)
    if not item:isEmpty() then
        return item:release(true)
    end
    item:release()
    return nil
end

---public 消耗道具
---@return number Errcode 成功与否
---@return NetProtoIsland.ST_item 如果成功的放，返回处理后的道具数据
logic.consumeItem2 = function(idx, num)
    local item = dbitems.instanse(idx)
    if item:isEmpty() then
        item:release()
        -- 说明是消耗道具
        return Errcode.itemIsNil
    else
        -- 找到了对应的道具
        local left = item:get_num() - num
        if left > 0 then
            item:set_num(left)
            logic.onItemChg(idx)
            -- 记录道具使用记录(是否一定要记录?)
            local usedHis = dbitemsused.new()
            local usedInfor = item:value2copy()
            usedInfor[dbitemsused.keys.itemidx] = usedInfor[dbitemsused.keys.idx]
            usedInfor[dbitemsused.keys.idx] = DBUtl.nextVal(DBUtl.Keys.itemused)
            usedInfor[dbitemsused.keys.dateuse] = dateEx.nowMS()
            usedInfor[dbitemsused.keys.num] = num
            usedHis:init(usedInfor, true)
            usedHis:release()
            -- 如果数量为0，则删除
            if item:get_num() <= 0 then
                local val = item:value2copy()
                item:delete()
                return Errcode.ok, val
            else
                return Errcode.ok, item:release(true)
            end
        else
            return Errcode.itemNotEnough, item:release(true)
        end
    end
end

---public 刷新道具(数量为负数时就是增加道具)
---@return number Errcode 成功与否
---@return NetProtoIsland.ST_item 如果成功的放，返回处理后的道具数据
logic.consumeItem = function(idx, pidx, id, type, num)
    if num == 0 then
        return Errcode.ok
    end
    if idx and idx > 0 then
        if num > 0 then
            -- 说明是消耗
            return logic.consumeItem(idx, num)
        else
            local item = dbitems.instanse(idx)
            item:set_num(item:get_num() - num)
            return Errcode.ok, item:release(true)
        end
    end

    if pidx then
        local items = dbitems.getListBypidx(pidx)
        for i, v in ipairs(items) do
            if v[dbitems.keys.id] == id and v[dbitems.keys.type] == type then
                -- 找到了对应的道具
                local left = v[dbitems.keys.num] - num
                if left > 0 then
                    local item = dbitems.instanse(v[dbitems.keys.idx])
                    item:set_num(left)
                    logic.onItemChg(v[dbitems.keys.idx])
                    return Errcode.ok, item:release(true)
                else
                    return Errcode.itemNotEnough, v
                end
                break
            end
        end
    end

    -- 未找道具时的处理
    if num > 0 then
        -- 说明是扣道具
        return Errcode.itemIsNil
    else
        -- 说明是新增
        return Errcode.ok, logic.newItem(pidx, id, type, -1 * num)
    end
end

---public 使用道具
---@return number Errcode 返回code
---@return NetProtoIsland.ST_item 道具数据
logic.doUseItem = function(idx, num)
    local item = dbitems.instanse(idx)
    if item:isEmpty() then
        item:release()
        return Errcode.itemIsNil
    end

    local code, itemVal = logic.consumeItem2(idx, num)
    if code ~= Errcode.ok then
        return code, item:release(true)
    end

    local attr = cfgUtl.getItemByID(item:get_id())
    local type = item:get_type()
    if type == IDConst.ItemType.box then
        -- //TODO:宝箱,要特殊处理
    elseif type == IDConst.ItemType.mapPaper then
        -- //TODO:图纸
    elseif type == IDConst.ItemType.protect then
        -- //TODO:护盾
    elseif type == IDConst.ItemType.revival then
        -- // TODO:复活
    elseif type == IDConst.ItemType.shard then
        -- // TODO:碎片(海怪碎片)
    elseif type == IDConst.ItemType.ship then
        -- // TODO:舰船
    elseif type == IDConst.ItemType.speedup then
    -- // TODO:加速
    end

    return Errcode.ok, item:release(true)
end

---public 推送道具变化
logic.onItemChg = function(idx)
    local item = dbitems.instanse(idx)
    if item:isEmpty() then
        item:release()
        return
    end
    local pkg = pkg4Client({cmd = "onItemChg"}, {code = Errcode.ok}, item:value2copy())
    -- 推送客户端
    sendPkg2Player(item:get_pidx(), pkg)
    item:release()
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
