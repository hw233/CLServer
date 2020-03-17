local skynet = require("skynet")
require("CLGlobal")
require("class")
require("CLLPool")
require("CLLQueue")
require("CLLStack")
json = require("json")
require("BioUtl")
MD5 = require("md5")
require("BitUtl")
require("DBUtl")
require("numEx")
require("timerEx")
require("CLUtl")
require("Grid")
require("dateEx")
require("fileEx")

--sys
require("Math")
-- 设置随机种子的时候调用一下random函数，随后就能正常获取随机数了
require("Vector2")
require("Vector3")
require("Vector4")

-- island
require("logic.IDConst")
require("public.cfgUtl")
require("public.myutl")

---@public logic有错误的日志，会把用户信息一并记录
loge =  function(agent, msg)
    skynet.call(agent, "lua", "log", msg)
end

