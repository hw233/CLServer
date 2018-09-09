-- 错误代码
Errcode = {}

Errcode.ok = 1
Errcode.error = -1
Errcode.needregist = 2;  -- 未注册
Errcode.uidregisted = 3;  -- uid已经被注册
Errcode.outOfMaxLev = 4;  -- 已经是最高等级
Errcode.resNotEnough = 5;  -- 资源不足


return Errcode
