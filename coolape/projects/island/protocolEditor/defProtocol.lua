--[[
-- 定义接口协议
--]]
defProtocol = {}
defProtocol.name = "NetProtoIsland";      -- 协议名字
defProtocol.isSendClientInt2bio = true;     -- 发送给客户端时是否把int转成bio
--===================================================
--===================================================
--===================================================
--[[ 数据结构定义,格式如下

defProtocol.structs.数据结构名 = {
    "数据结构的说明",
    {
        字段1 = { 可以确定类型的初始值, "字段说明" },
        字段2 = { 可以确定类型的初始值, "字段说明" },
    }
}
例如：
defProtocol.structs.retInfor = {
    "返回信息",
    {
        code = { 1, "返回值" },
        msg = { "", "返回消息" },
    }
}

.注意每个字段对应一个list，list[1]=设置一个值，以确定该字段的类型,可以嵌套其它数据结构, list[2]=该字段的备注说明（可以没有）
例如：
defProtocol.structs.AA = {
    "例1",
    {
        a = { 1, "说明" },
    }
}

defProtocol.structs.BB = {
    "例2",
    {
        b = { {d = defProtocol.structs.AA}, "该字段是一个table形，值是一个defProtocol.structs.AA数据结构" },
        c = { {defProtocol.structs.AA, defProtocol.structs.AA}, "该字段是个list，里面的值是defProtocol.structs.AA数据结构"},
    }
}

--]]
---@class defProtocol.structs
defProtocol.structs = {}
defProtocol.structs.retInfor = {
    "返回信息",
    {
        code = { 1, "返回值" },
        msg = { "", "返回消息" },
    }
}

defProtocol.structs.player = {
    "用户信息",
    {
        idx = { 0, "唯一标识" },
        name = { "", "名字" },
    }
}
--===================================================
--===================================================
--===================================================
local structs = defProtocol.structs;
--===================================================
--===================================================
--===================================================
-- 接口定义
defProtocol.cmds = {
    release = {
        desc = "数据释放，客户端不用调用，服务器内部调用的指令"; -- 接口说明
        input = { }; -- 入参
        inputDesc = { }; -- 入参说明
        output = { }; -- 出参
        outputDesc = { }; -- 出参说明
        logic = "cmd4player",
        only4server = true,
    },
    stopserver = {
        desc = "停服，客户端不用调用，服务器内部调用的指令"; -- 接口说明
        input = { }; -- 入参
        inputDesc = { }; -- 入参说明
        output = { }; -- 出参
        outputDesc = { }; -- 出参说明
        logic = "cmd4player";
        only4server = true,
    },
    regist = {
        desc = "注册"; -- 接口说明
        input = { "uidx", "name", "icon", "channel", "deviceID" }; -- 入参
        inputDesc = { "用户id", "名字", "头像", "渠道号", "机器码" }; -- 入参说明
        output = { structs.retInfor, structs.player, "systime", "session" }; -- 出参
        outputDesc = { "返回信息", "玩家信息", "系统时间 long", "会话id" }; -- 出参说明
        logic = "cmd4player";
    },
    login = {
        desc = "登陆"; -- 接口说明
        input = { "uidx", "channel", "deviceID" }; -- 入参
        inputDesc = { "用户id", "渠道号", "机器码" }; -- 入参说明
        output = { structs.retInfor, structs.player, "systime", "session" }; -- 出参
        outputDesc = { "返回信息", "玩家信息", "系统时间 long", "会话id" }; -- 出参说明
        logic = "cmd4player";
    },
    logout = {
        desc = "登陆"; -- 接口说明
        input = { }; -- 入参
        inputDesc = { }; -- 入参说明
        output = { structs.retInfor }; -- 出参
        outputDesc = { "返回信息" }; -- 出参说明
        logic = "cmd4player";
    },
}

return defProtocol
