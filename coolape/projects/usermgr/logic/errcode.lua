-- 错误代码
Errcode = {}

Errcode.ok = 1
Errcode.error = -1
Errcode.needregist = 2;  -- 未注册
Errcode.uidregisted = 3;  -- uid已经被注册
Errcode.psderror = 4;  -- 密码错误
Errcode.toomanydevice = 5;  -- 设备超限
Errcode.sessiontimeout = -10000;  -- session超时

return Errcode
