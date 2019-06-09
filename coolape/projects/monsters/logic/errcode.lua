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

return Errcode
