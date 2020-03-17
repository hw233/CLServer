---@class logic4city
local logic4city = {}
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
require("dbfleet")
local IDConst = require("IDConst")

---@public 取得城市实例同时会处理城市的相关timer(注意要释放）
---@return dbcity
logic4city.insCityAndRefresh = function(cidx)
    local city = dbcity.instanse(cidx)
    if isPlayerOnline(city:get_pidx()) then
        return city
    else
        -- 不在线，需要处理主城的timer
        -- 保护时间
        if city:get_status() == IDConst.CityState.protect then
            if city:get_protectEndTime() <= dateEx.nowMS() then
                -- 保护时间结束
                city:set_status(IDConst.CityState.normal)
            end
        end
        -- 建筑的升级、建造、恢复
        local list = dbbuilding.getListBycidx(city:get_idx())
        ---@type dbbuilding
        local b
        for i, v in ipairs(list) do
            b = dbbuilding.new(v)
            if b:get_state() == IDConst.BuildingState.upgrade then
                if b:get_endtime() <= dateEx.nowMS() then
                    local val = {}
                    val[dbbuilding.keys.state] = IDConst.BuildingState.normal
                    val[dbbuilding.keys.lev] = b:get_lev() + 1
                    val[dbbuilding.keys.starttime] = b:get_endtime()
                    b:refreshData(val) -- 这样处理的目的是保证不会多次触发通知客户端
                end
            elseif b:get_state() == IDConst.BuildingState.working then
                -- 正生产
                if b:get_attrid() == IDConst.BuildingID.dockyard then
                    -- 造船厂
                    local roleAttrId = b:get_val()
                    local num = b:get_val2()
                    if roleAttrId <= 0 or num <= 0 then
                        local data = {}
                        data[dbbuilding.keys.val] = 0
                        data[dbbuilding.keys.val2] = 0
                        data[dbbuilding.keys.val3] = 0
                        data[dbbuilding.keys.starttime] = b:get_endtime()
                        data[dbbuilding.keys.state] = IDConst.BuildingState.normal
                        b:refreshData(data)
                    else
                        local attr = cfgUtl.getRoleByID(roleAttrId)
                        -- 建船时间
                        local BuildTimeS = attr.BuildTimeS / 10
                        local starttime = b:get_val3() -- 保存的是上次造船的开始时间
                        local diffSec = (dateEx.nowMS() - starttime) / 1000
                        local finishBuildNum = numEx.getIntPart(diffSec / BuildTimeS)
                        if finishBuildNum > 0 then
                            if finishBuildNum >= num then
                                -- 说明全部已经完成
                                finishBuildNum = num
                                local data = {}
                                data[dbbuilding.keys.val] = 0
                                data[dbbuilding.keys.val2] = 0
                                data[dbbuilding.keys.val3] = 0
                                data[dbbuilding.keys.starttime] = b:get_endtime()
                                data[dbbuilding.keys.state] = IDConst.BuildingState.normal
                                b:refreshData(data)
                            else
                                local leftSec = diffSec % BuildTimeS
                                local data = {}
                                data[dbbuilding.keys.val2] = b:get_val2() - finishBuildNum
                                data[dbbuilding.keys.val3] = dateEx.nowMS() - numEx.getIntPart(leftSec * 1000)
                                b:refreshData(data)
                            end
                        end
                    end
                end
            elseif b:get_state() == IDConst.BuildingState.renew then
                -- 正在恢复
                if b:get_endtime() <= dateEx.nowMS() then
                    local val = {}
                    val[dbbuilding.keys.state] = IDConst.BuildingState.normal
                    val[dbbuilding.keys.starttime] = b:get_endtime()
                    b:refreshData(val) -- 这样处理的目的是保证不会多次触发通知客户端
                end
            elseif
                b:get_attrid() == IDConst.BuildingID.foodFactory or
                    b:get_attrid() == IDConst.BuildingID.goldMine or
                    b:get_attrid() == IDConst.BuildingID.oilWell
             then
                -- 是资源生产
                if b:get_state() == IDConst.BuildingState.normal then
                    local proTime = dateEx.nowMS() - (b:get_starttime() or 0)
                    proTime = numEx.getIntPart(proTime / 60000)
                    -- 转成分钟
                    if proTime > 0 then
                        local constcfg = cfgUtl.getConstCfg()
                        -- 判断时长是否超过最大生产时长(目前配置的最大只可生产8小时产量)
                        if proTime > constcfg.MaxTimeLen4ResYields then
                            local startTime = dateEx.nowMS() - (constcfg.MaxTimeLen4ResYields * 60000)
                            b:set_starttime(startTime)
                        end
                    end
                end
            end
            b:release()
        end
    end
    return city
end

---@public 消耗资源。注意：负数时就是增加资源
---@param cidx number 城市idx
---@param food number 粮
---@param gold number 金
---@param oil number 油
---@return boolean 是否扣除成功
logic4city.consumeRes = function(cidx, food, gold, oil)
    local cityserver = skynet.newservice("cmd4city")
    skynet.call(cityserver, "lua", "init", cidx)
    skynet.call(cityserver, "lua", "consumeRes", food, gold, oil)

    skynet.call(cityserver, "lua", "release")
    skynet.kill(cityserver)
end

return logic4city
