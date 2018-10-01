-- 错误代码
Errcode = {}

Errcode.ok = 1
Errcode.error = -1
Errcode.needregist = 2  -- 未注册
Errcode.uidregisted = 3  -- uid已经被注册
Errcode.psderror = 4  -- 密码错误
Errcode.toomanydevice = 5  -- 设备超限
Errcode.outOfMaxLev = 6  -- 已经是最高等级
Errcode.resNotEnough = 7  -- 资源不足
Errcode.exceedHeadquarters = 8  -- 不能超过主基地等级
Errcode.noIdelQueue = 9    -- 没有空闲队列
Errcode.maxNumber = 10    -- 数量已达上限
Errcode.cannotPlace = 11       -- 不可放下
Errcode.tileIsNil = 12 -- 取得地块为空
Errcode.buildingIsNil = 13 -- 取得建筑为空
Errcode.tileListIsNil = 14 -- 地块信息列表为空
Errcode.cityIsNil = 15 -- 主城为空
Errcode.buildingListIsNil = 16 -- 建筑信息列表为空
Errcode.buildingNotIdel = 17 -- 建筑的状态不是空闲状态
Errcode.playerIsNil = 18 -- 玩家数据取得为空
Errcode.diamNotEnough = 19  -- 钻石不足
Errcode.buildingIsBusy = 20 -- 建筑正忙，不可操作

return Errcode
