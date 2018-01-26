--[[
-- 定义接口协议
--]]
defProtocol = {}
defProtocol.name = "NetProtoMibao";      -- 协议名字
defProtocol.isSendClientInt2bio = true;     -- 发送给客户端时是否把int转成bio
--===================================================
--===================================================
--===================================================
defProtocol.structs = {}
defProtocol.structs.retInfor = {
    "返回信息",
    {
        code = { 1, "返回值" },
        msg = { "", "返回消息" },
    }
}
-- 密码信息
defProtocol.structs.psdInfor = {
    "密码信息",
    {
        platform = { "", "平台、网站等，作为key用" },
        desc = { "", "备注" },
        user = { "", "账号" },
        psd = { "", "密码" },
        time = { 0, "修改时间" }
    }
}
--===================================================
--===================================================
--===================================================
---@class defProtocol.structs
local structs = defProtocol.structs;
--===================================================
--===================================================
--===================================================
-- 接口定义
defProtocol.cmds = {
    syndata = {
        desc = "数据同步",
        input = { {structs.psdInfor,structs.psdInfor }},
        inputDesc = { "数据信息" },
        output = { structs.retInfor, "newData" },
        outputDesc = { "返回信息", "新数据" },
        logic = "cmd4mibao";
    },

}

return defProtocol
