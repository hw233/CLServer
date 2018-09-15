-- 错误代码
Errcode = {}

Errcode.ok = 1
Errcode.error = -1
Errcode.needregist = 2;  -- 未注册
Errcode.uidregisted = 3;  -- uid已经被注册
Errcode.outOfMaxLev = 4;  -- 已经是最高等级
Errcode.resNotEnough = 5;  -- 资源不足
Errcode.exceedHeadquarters = 6;  -- 不能超过主基地等级
Errcode.noIdelQueue = 7;    -- 没有空闲队列


return Errcode
