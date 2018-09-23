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


return Errcode
