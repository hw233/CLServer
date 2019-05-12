--[[
-- 定义接口协议
--]]
defProtocol = {}
defProtocol.name = "NetProtoIsland" -- 协议名字
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
defProtocol.structs.building = {
    "建筑信息对象",
    {
        idx = {0, "唯一标识 int"},
        cidx = {0, "主城idx int"},
        pos = {0, "位置，即在城的gird中的index int"},
        attrid = {0, "属性配置id int"},
        lev = {0, "等级 int"},
        state = {0, "状态. 0：正常；1：升级中；9：恢复中"},
        starttime = {0, "开始升级、恢复、采集等的时间点 long"},
        endtime = {0, "完成升级、恢复、采集等的时间点 long"},
        val = {0, "值。如:产量，仓库的存储量等 int"},
        val2 = {0, "值2。如:产量，仓库的存储量等 int"},
        val3 = {0, "值3。如:产量，仓库的存储量等 int"},
        val4 = {0, "值4。如:产量，仓库的存储量等 int"},
        val5 = {0, "值5。如:产量，仓库的存储量等 int"}
    }
}
defProtocol.structs.tile = {
    "建筑信息对象",
    {
        idx = {0, "唯一标识 int"},
        cidx = {0, "主城idx int"},
        attrid = {0, "属性配置id int"},
        pos = {0, "位置，即在城的gird中的index int"}
    }
}
defProtocol.structs.city = {
    "主城",
    {
        idx = {0, "唯一标识 int"},
        name = {"", "名称"},
        pidx = {0, "玩家idx int"},
        pos = {0, "城所在世界grid的index int"},
        status = {0, "状态 1:正常; int"},
        lev = {0, "等级 int"},
        buildings = {{buildingIdx = defProtocol.structs.building}, "建筑信息 key=idx, map"},
        tiles = {{tileIdx = defProtocol.structs.tile}, "地块信息 key=idx, map"}
    }
}
defProtocol.structs.resInfor = {
    "资源信息",
    {
        food = {0, "粮"},
        gold = {0, "金"},
        oil = {0, "油"}
    }
}

defProtocol.structs.mapCell = {
    "大地图地块数据",
    {
        idx = {0, "网格index"},
        type = {0, "地块类型 1：玩家，2：npc"},
        cidx = {0, "主城idx"},
        pageIdx = {0, "所在屏的index"},
        val1 = {0, "值1"},
        val2 = {0, "值2"},
        val3 = {0, "值3"}
    }
}

defProtocol.structs.mapPage = {
    "一屏大地图数据",
    {
        pageIdx = {0, "一屏所在的网格index "},
        cells = {{defProtocol.structs.mapCell, defProtocol.structs.mapCell}, "地图数据 key=网络index, map"}
    }
}
defProtocol.structs.dockyardShips = {
    "造船厂的舰船信息",
    {
        buildingIdx = {0, "造船厂的idx"},
        shipsMap = {{skipAttrid = 0}, "key=舰船的配置id, val=舰船数量 map"}
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
        output = {structs.retInfor, structs.player, structs.city, "systime", "session"}, -- 出参
        outputDesc = {"返回信息", "玩家信息", "主城信息", "系统时间 long", "会话id"}, -- 出参说明
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
    getBuilding = {
        desc = "取得建筑", -- 接口说明
        input = {"idx"}, -- 入参
        inputDesc = {"建筑idx int"}, -- 入参说明
        output = {structs.retInfor, defProtocol.structs.building}, -- 出参
        outputDesc = {"返回信息", "建筑信息对象"}, -- 出参说明
        logic = "cmd4city"
    },
    newBuilding = {
        desc = "新建建筑", -- 接口说明
        input = {"attrid", "pos"}, -- 入参
        inputDesc = {"建筑配置id int", "位置 int"}, -- 入参说明
        output = {structs.retInfor, defProtocol.structs.building}, -- 出参
        outputDesc = {"返回信息", "建筑信息对象"}, -- 出参说明
        logic = "cmd4city"
    },
    newTile = {
        desc = "新建地块", -- 接口说明
        input = {"pos"}, -- 入参
        inputDesc = {"位置 int"}, -- 入参说明
        output = {structs.retInfor, defProtocol.structs.tile}, -- 出参
        outputDesc = {"返回信息", "地块信息对象"}, -- 出参说明
        logic = "cmd4city"
    },
    rmTile = {
        desc = "移除地块", -- 接口说明
        input = {"idx"}, -- 入参
        inputDesc = {"地块idx int"}, -- 入参说明
        output = {structs.retInfor, "idx"}, -- 出参
        outputDesc = {"返回信息", "被移除地块的idx int"}, -- 出参说明
        logic = "cmd4city"
    },
    rmBuilding = {
        desc = "移除建筑", -- 接口说明
        input = {"idx"}, -- 入参
        inputDesc = {"地块idx int"}, -- 入参说明
        output = {structs.retInfor, "idx"}, -- 出参
        outputDesc = {"返回信息", "被移除建筑的idx int"}, -- 出参说明
        logic = "cmd4city"
    },
    moveTile = {
        desc = "移动地块", -- 接口说明
        input = {"idx", "pos"}, -- 入参
        inputDesc = {"地块idx int", "位置 int"}, -- 入参说明
        output = {structs.retInfor, defProtocol.structs.tile}, -- 出参
        outputDesc = {"返回信息", "地块信息"}, -- 出参说明
        logic = "cmd4city"
    },
    moveBuilding = {
        desc = "移动建筑", -- 接口说明
        input = {"idx", "pos"}, -- 入参
        inputDesc = {"建筑idx int", "位置 int"}, -- 入参说明
        output = {structs.retInfor, defProtocol.structs.building}, -- 出参
        outputDesc = {"返回信息", "建筑信息"}, -- 出参说明
        logic = "cmd4city"
    },
    moveCity = {
        desc = "搬迁", -- 接口说明
        input = {"pos"}, -- 入参
        inputDesc = {"位置 int"}, -- 入参说明
        output = {structs.retInfor}, -- 出参
        outputDesc = {"返回信息"}, -- 出参说明
        logic = "cmd4city"
    },
    upLevBuilding = {
        desc = "升级建筑", -- 接口说明
        input = {"idx"}, -- 入参
        inputDesc = {"建筑idx int"}, -- 入参说明
        output = {structs.retInfor, defProtocol.structs.building}, -- 出参
        outputDesc = {"返回信息", "建筑信息"}, -- 出参说明
        logic = "cmd4city"
    },
    upLevBuildingImm = {
        desc = "立即升级建筑", -- 接口说明
        input = {"idx"}, -- 入参
        inputDesc = {"建筑idx int"}, -- 入参说明
        output = {structs.retInfor, defProtocol.structs.building}, -- 出参
        outputDesc = {"返回信息", "建筑信息"}, -- 出参说明
        logic = "cmd4city"
    },
    onMyselfCityChg = {
        desc = "自己的城变化时推送", -- 接口说明
        input = {}, -- 入参
        inputDesc = {}, -- 入参说明
        output = {structs.retInfor, defProtocol.structs.city}, -- 出参
        outputDesc = {"返回信息", "主城信息"}, -- 出参说明
        logic = "cmd4city"
    },
    onResChg = {
        desc = "资源变化时推送", -- 接口说明
        input = {}, -- 入参
        inputDesc = {}, -- 入参说明
        output = {structs.retInfor, defProtocol.structs.resInfor}, -- 出参
        outputDesc = {"返回信息", "资源信息"}, -- 出参说明
        logic = "cmd4city"
    },
    onBuildingChg = {
        desc = "建筑变化时推送", -- 接口说明
        input = {}, -- 入参
        inputDesc = {}, -- 入参说明
        output = {structs.retInfor, defProtocol.structs.building}, -- 出参
        outputDesc = {"返回信息", "建筑信息"}, -- 出参说明
        logic = "cmd4city"
    },
    onPlayerChg = {
        desc = "玩家信息变化时推送", -- 接口说明
        input = {}, -- 入参
        inputDesc = {}, -- 入参说明
        output = {structs.retInfor, defProtocol.structs.player}, -- 出参
        outputDesc = {"返回信息", "玩家信息"}, -- 出参说明
        logic = "cmd4player"
    },
    onMapCellChg = {
        desc = "当地块发生变化时推送", -- 接口说明
        input = {}, -- 入参
        inputDesc = {}, -- 入参说明
        output = {structs.retInfor, defProtocol.structs.mapCell}, -- 出参
        outputDesc = {"返回信息", "地块"}, -- 出参说明
        logic = "LDSWorld"
    },
    onFinishBuildingUpgrade = {
        desc = "建筑升级完成", -- 接口说明
        input = {}, -- 入参
        inputDesc = {}, -- 入参说明
        output = {structs.retInfor, defProtocol.structs.building}, -- 出参
        outputDesc = {"返回信息", "建筑信息"}, -- 出参说明
        logic = "cmd4city"
    },
    collectRes = {
        desc = "收集资源", -- 接口说明
        input = {"idx"}, -- 入参
        inputDesc = {"资源建筑的idx int"}, -- 入参说明
        output = {structs.retInfor, "resType", "resVal", defProtocol.structs.building}, -- 出参
        outputDesc = {"返回信息", "收集的资源类型 int", "收集到的资源量 int", "建筑信息"}, -- 出参说明
        logic = "cmd4city"
    },
    getMapDataByPageIdx = {
        desc = "取得一屏的在地图数据", -- 接口说明
        input = {"pageIdx"}, -- 入参
        inputDesc = {"一屏所在的网格index"}, -- 入参说明
        output = {structs.retInfor, defProtocol.structs.mapPage}, -- 出参
        outputDesc = {"返回信息", "在地图一屏数据 map"}, -- 出参说明
        logic = "LDSWorld"
    },
    buildShip = {
        desc = "造船", -- 接口说明
        input = {"buildingIdx", "shipAttrID", "num"}, -- 入参
        inputDesc = {"造船厂的idx int", "舰船配置id int", "数量 int"}, -- 入参说明
        output = {structs.retInfor, defProtocol.structs.building}, -- 出参
        outputDesc = {"返回信息", "造船厂信息"}, -- 出参说明
        logic = "cmd4city"
    },
    getShipsByBuildingIdx = {
        desc = "取得造船厂所有舰艇列表", -- 接口说明
        input = {"buildingIdx"}, -- 入参
        inputDesc = {"造船厂的idx int"}, -- 入参说明
        output = {structs.retInfor, defProtocol.structs.dockyardShips}, -- 出参
        outputDesc = {"返回信息", "造船厂的idx int", "造船厂里存放的舰船信息"}, -- 出参说明
        logic = "cmd4city"
    },
    onFinishBuildOneShip = {
        desc = "当完成建造部分舰艇的通知", -- 接口说明
        input = {"buildingIdx"}, -- 入参
        inputDesc = {"造船厂的idx int"}, -- 入参说明
        output = {structs.retInfor, "buildingIdx", "shipAttrID", "shipNum"}, -- 出参
        outputDesc = {"返回信息", "造船厂的idx int", "舰船的配置id", "舰船的数量"}, -- 出参说明
        logic = "cmd4city"
    },
    attack = {
        desc = "攻击", -- 接口说明
        input = {"pos"}, -- 入参
        inputDesc = {"世界地图坐标idx int"}, -- 入参说明
        output = {structs.retInfor, structs.player, structs.city, {structs.dockyardShips,structs.dockyardShips}, {structs.dockyardShips,structs.dockyardShips}}, -- 出参
        outputDesc = {"返回信息", "被攻击玩家信息", "被攻击主城信息", "被攻击航船的数据", "进攻击方航船的数据"}, -- 出参说明
        logic = "cmd4battle"
    }
}

return defProtocol
