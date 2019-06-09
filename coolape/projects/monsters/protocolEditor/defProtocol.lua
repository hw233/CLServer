--[[
-- 定义接口协议
--]]
defProtocol = {}
defProtocol.name = "NetPtMonsters" -- 协议名字(好像最长只能是15个字符)
defProtocol.isSendClientInt2bio = true -- 发送给客户端时是否把int转成bio
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
        b = { {d = defProtocol.structs.AA}, "该字段是一个table类形，值是一个defProtocol.structs.AA数据结构" },
        c = { {defProtocol.structs.AA, defProtocol.structs.AA}, "该字段是个list，里面的值是defProtocol.structs.AA数据结构"},
    }
}

--]]
defProtocol.structs = {}
defProtocol.structs.retInfor = {
    "返回信息",
    {
        code = {1, "返回值"},
        msg = {"", "返回消息"}
    }
}

defProtocol.structs.player = {
    "用户信息",
    {
        idx = {0, "唯一标识 int"},
        name = {"", "名字"},
        status = {0, "状态 1：正常 int"},
        lev = {0, "等级 long"},
        diam = {0, "钻石 long"},
        cityidx = {0, "城池id int"},
        unionidx = {0, "联盟id int"}
    }
}

defProtocol.structs.netCfg = {
    "网络协议解析配置",
    {
        encryptType = {0, "加密类别，1：只加密客户端，2：只加密服务器，3：前后端都加密，0及其它情况：不加密"},
        secretKey = {"", "密钥"},
        checkTimeStamp = {true, "检测时间戳"}
    }
}
--===================================================
--===================================================
--===================================================
local structs = defProtocol.structs
--===================================================
--===================================================
--===================================================
-- 接口定义
defProtocol.cmds = {
    sendNetCfg = {
        desc = "网络协议配置", -- 接口说明
        input = {}, -- 入参
        inputDesc = {}, -- 入参说明
        output = {structs.retInfor, defProtocol.structs.netCfg, "systime"}, -- 出参
        outputDesc = {"返回信息", "网络协议解析配置", "系统时间 long"}, -- 出参说明
        logic = ""
    },
    heart = {
        desc = "心跳", -- 接口说明
        input = {}, -- 入参
        inputDesc = {}, -- 入参说明
        output = {}, -- 出参
        outputDesc = {}, -- 出参说明
        logic = "cmd4com",
        only4server = true
    },
    login = {
        desc = "登陆", -- 接口说明
        input = {"uidx", "channel", "deviceID", "isEditMode"}, -- 入参
        inputDesc = {"用户id", "渠道号", "机器码", "编辑模式"}, -- 入参说明
        output = {structs.retInfor, structs.player, "systime", "session"}, -- 出参
        outputDesc = {"返回信息", "玩家信息", "系统时间 long", "会话id"}, -- 出参说明
        logic = "cmd4player"
    },
    logout = {
        desc = "登出", -- 接口说明
        input = {}, -- 入参
        inputDesc = {}, -- 入参说明
        output = {structs.retInfor}, -- 出参
        outputDesc = {"返回信息"}, -- 出参说明
        logic = "cmd4player"
    },
    onPlayerChg = {
        desc = "玩家信息变化时推送", -- 接口说明
        input = {}, -- 入参
        inputDesc = {}, -- 入参说明
        output = {structs.retInfor, defProtocol.structs.player}, -- 出参
        outputDesc = {"返回信息", "玩家信息"}, -- 出参说明
        logic = "cmd4player"
    },
}

return defProtocol
