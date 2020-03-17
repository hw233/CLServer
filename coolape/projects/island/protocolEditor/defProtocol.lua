--[[
-- 定义接口协议
--]]
defProtocol = {}
defProtocol.name = "NetProtoIsland" -- 协议名字
defProtocol.isSendClientInt2bio = true -- 发送给客户端时是否把int转成bio
defProtocol.isGenLuaClientFile = true -- 生成lua客户端接口文件
defProtocol.isGenJsClientFile = false -- 生成js客户端接口文件
defProtocol.compatibleJsonp = false -- 是否考虑兼容json
defProtocol.isCheckSession = false -- 生成检测session超时的代码
defProtocol.donotCheckSessionCMDs = {} -- 不做session超时检测的接口
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
defProtocol.structs.vector3 = {
    "坐标(注意使用时需要/1000",
    {
        x = {0, "int"},
        y = {0, "int"},
        z = {0, "int"}
    }
}
defProtocol.structs.player = {
    "用户信息",
    {
        idx = {0, "唯一标识 int"},
        name = {"", "名字"},
        status = {0, "状态 1：正常 int"},
        attacking = {true, "正在攻击玩家的岛屿"},
        beingattacked = {true, "正在被玩家攻击"},
        point = {0, "功勋 long"},
        exp = {0, "经验值 long"},
        lev = {0, "等级 long"},
        diam = {0, "钻石 long"},
        diam4reward = {0, "钻石 long"},
        cityidx = {0, "城池id int"},
        unionidx = {0, "联盟id int"}
    }
}
defProtocol.structs.playerSimple = {
    "用户精简信息",
    {
        idx = {0, "唯一标识 int"},
        name = {"", "名字"},
        status = {0, "状态 1：正常 int"},
        point = {0, "功勋 long"},
        exp = {0, "经验值 long"},
        lev = {0, "等级 long"},
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
        protectEndTime = {0, "免战结束时间"},
        lev = {0, "等级 int"},
        buildings = {{buildingIdx = defProtocol.structs.building}, "建筑信息 key=idx, map"},
        tiles = {{tileIdx = defProtocol.structs.tile}, "地块信息 key=idx, map"}
    }
}
defProtocol.structs.unitInfor = {
    "单元(舰船、萌宠等)",
    {
        id = {0, "配置的id int"},
        type = {0, "类型id(UnitType：role = 2, -- (ship, pet)；tech = 3,；skill = 4) int"},
        bidx = {0, "所属建筑idx int"},
        fidx = {0, "所属舰队idx int"},
        num = {0, "数量 int"},
        lev = {0, "等级(大部分情况下lev可能是0，而是由科技决定，但是联盟里的兵等级是有值的) int"}
    }
}

defProtocol.structs.battleUnitInfor = {
    "战斗中的战斗单元详细",
    {
        id = {0, "配置的id int"},
        type = {0, "类型id(UnitType：role = 2, -- (ship, pet)；tech = 3,；skill = 4) int"},
        deployNum = {0, "投放数量"},
        deadNum = {0, "死亡数量"}
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
        pageIdx = {0, "所在屏的index"},
        type = {0, "地块类型 3：玩家，4：npc"},
        attrid = {0, "配置id"},
        cidx = {0, "主城idx"},
        fidx = {0, "舰队idx"},
        name = {"", "名称"},
        lev = {0, "等级"},
        state = {0, "状态  1:正常; int"},
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
        ships = {{defProtocol.structs.unitInfor, defProtocol.structs.unitInfor}, "舰船数据"}
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
defProtocol.structs.fleetinfor = {
    "舰队数据",
    {
        idx = {0, "唯一标识舰队idx"},
        cidx = {0, "城市idx"},
        name = {"", "名称"},
        pname = {"", "玩家名"},
        curpos = {0, "当前所在世界grid的index"},
        fromposv3 = {defProtocol.structs.vector3, "坐标"},
        frompos = {0, "出征的开始所在世界grid的index"},
        topos = {0, "出征的目地所在世界grid的index"},
        task = {0, "执行任务类型 idel = 1, -- 待命状态;voyage = 2, -- 出征;back = 3, -- 返航;attack = 4 -- 攻击"},
        status = {
            0,
            "状态 none = 1, -- 无;moving = 2, -- 航行中;docked = 3, -- 停泊在港口;stay = 4, -- 停留在海面;fighting = 5 -- 正在战斗中"
        },
        arrivetime = {0, "到达时间"},
        deadtime = {0, "沉没的时间"},
        units = {{defProtocol.structs.unitInfor, defProtocol.structs.unitInfor}, "战斗单元列表"}
    }
}
defProtocol.structs.battleresult = {
    "战斗结果",
    {
        attacker = {defProtocol.structs.playerSimple, "进攻方"},
        defender = {defProtocol.structs.playerSimple, "防守方"},
        fidx = {0, "舰队idx"},
        star = {0, "星级, 0表示失败，1-3星才算胜利"},
        exp = {0, "获得的经验"},
        lootRes = {defProtocol.structs.resInfor, "掠夺的资源"},
        attackerUsedUnits = {{defProtocol.structs.battleUnitInfor, defProtocol.structs.battleUnitInfor}, "进攻方投入的战斗单元"},
        targetUsedUnits = {{defProtocol.structs.battleUnitInfor, defProtocol.structs.battleUnitInfor}, "防守方损失的战斗单元"}
    }
}
defProtocol.structs.deployUnitInfor = {
    "战斗单元投放信息",
    {
        unitInfor = {defProtocol.structs.unitInfor, "战斗单元"},
        frames = {0, "投放时的帧数（相较于第一次投放时的帧数增量）"},
        pos = {defProtocol.structs.vector3, "投放坐标（是int，真实值x1000）"},
        fakeRandom = {0, "随机因子"},
        fakeRandom2 = {0, "随机因子"},
        fakeRandom3 = {0, "随机因子"}
    }
}

defProtocol.structs.mail = {
    "邮件",
    {
        idx = {0, "唯一标识"},
        parent = {0, "父邮件idx（大于0时表示是回复的邮件）"},
        type = {0, "类型，1：系统，2：战报；3：私信，4:联盟，5：客服"},
        state = {0, "状态，0：未读，1：已读&未领奖，2：已读&已领奖"},
        fromPidx = {0, "发件人"},
        fromName = {"", "发件人名称"},
        fromIcon = {0, "发件人头像id"},
        toPidx = {0, "收件人"},
        toName = {"", "收件人名称"},
        toIcon = {0, "收件人头像id"},
        title = {"", "标题"},
        titleParams = {"", "标题参数(json的map)"},
        content = {"", "内容"},
        contentParams = {"", "内容参数(json的map)"},
        date = {0, "时间"},
        historyList = {{1, 2}, "历史记录(邮件的idx列表)"},
        rewardIdx = {0, "奖励idx"},
        comIdx = {0, "通用ID,可以关联到比如战报等"},
        backup = {"", "备用"}
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
        input = {"uidx", "channel", "language", "deviceID", "isEditMode"}, -- 入参
        inputDesc = {"用户id", "渠道号", "语言", "机器码", "编辑模式"}, -- 入参说明
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
        output = {structs.retInfor, defProtocol.structs.mapCell, "isRemove"}, -- 出参
        outputDesc = {"返回信息", "地块", "是否是删除"}, -- 出参说明
        logic = "USWorld"
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
    moveCity = {
        desc = "搬迁", -- 接口说明
        input = {"cidx", "pos"}, -- 入参
        inputDesc = {"城市idx", "新位置 int"}, -- 入参说明
        output = {structs.retInfor}, -- 出参
        outputDesc = {"返回信息"}, -- 出参说明
        logic = "USWorld"
    },
    getMapDataByPageIdx = {
        desc = "取得一屏的在地图数据", -- 接口说明
        input = {"pageIdx"}, -- 入参
        inputDesc = {"一屏所在的网格index"}, -- 入参说明
        output = {
            structs.retInfor,
            defProtocol.structs.mapPage,
            {defProtocol.structs.fleetinfor, defProtocol.structs.fleetinfor}
        }, -- 出参
        outputDesc = {"返回信息", "在地图一屏数据 map", "舰队列表"}, -- 出参说明
        logic = "USWorld"
    },
    setPlayerCurrLook4WorldPage = {
        desc = "设置用户当前正在查看大地图的哪一页，便于后续推送数据", -- 接口说明
        input = {"pageIdx"}, -- 入参
        inputDesc = {"一屏所在的网格index"}, -- 入参说明
        output = {structs.retInfor}, -- 出参
        outputDesc = {"返回信息"}, -- 出参说明
        logic = "USWorld"
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
    saveFleet = {
        desc = "新建、更新舰队", -- 接口说明
        input = {"cidx", "idx", "name", {defProtocol.structs.unitInfor, defProtocol.structs.unitInfor}}, -- 入参
        inputDesc = {"城市", "舰队idx（新建时可为空）", "舰队名（最长7个字）", "战斗单元列表"}, -- 入参说明
        output = {structs.retInfor, defProtocol.structs.fleetinfor}, -- 出参
        outputDesc = {"返回信息", "舰队信息"}, -- 出参说明
        logic = "USWorld"
    },
    getFleet = {
        desc = "取得舰队信息", -- 接口说明
        input = {"idx"}, -- 入参
        inputDesc = {"舰队idx"}, -- 入参说明
        output = {structs.retInfor, defProtocol.structs.fleetinfor}, -- 出参
        outputDesc = {"返回信息", "舰队信息"}, -- 出参说明
        logic = "USWorld"
    },
    sendFleet = {
        desc = "推送舰队信息", -- 接口说明
        input = {}, -- 入参
        inputDesc = {}, -- 入参说明
        output = {structs.retInfor, defProtocol.structs.fleetinfor, "isRemove"}, -- 出参
        outputDesc = {"返回信息", "舰队信息", "是否移除"}, -- 出参说明
        logic = ""
    },
    getAllFleets = {
        desc = "取得所有舰队信息", -- 接口说明
        input = {"cidx"}, -- 入参
        inputDesc = {"城市的idx"}, -- 入参说明
        output = {structs.retInfor, {defProtocol.structs.fleetinfor, defProtocol.structs.fleetinfor}}, -- 出参
        outputDesc = {"返回信息", "舰队列表"}, -- 出参说明
        logic = "USWorld"
    },
    fleetDepart = {
        desc = "舰队出征", -- 接口说明
        input = {"idx", "toPos"}, -- 入参
        inputDesc = {"舰队idx", "目标位置"}, -- 入参说明
        output = {structs.retInfor, defProtocol.structs.fleetinfor}, -- 出参
        outputDesc = {"返回信息", "舰队信息"}, -- 出参说明
        logic = "USWorld"
    },
    fleetBack = {
        desc = "舰队返航", -- 接口说明
        input = {"idx"}, -- 入参
        inputDesc = {"舰队idx"}, -- 入参说明
        output = {structs.retInfor, defProtocol.structs.fleetinfor}, -- 出参
        outputDesc = {"返回信息", "舰队信息"}, -- 出参说明
        logic = "USWorld"
    },
    fleetAttackIsland = {
        desc = "舰队攻击岛屿", -- 接口说明
        input = {"fidx", "targetPos"}, -- 入参
        inputDesc = {"攻击方舰队idx", "攻击目标的世界地图坐标idx int"}, -- 入参说明
        output = {
            structs.retInfor,
            structs.fleetinfor
        }, -- 出参
        outputDesc = {
            "返回信息",
            "进攻方舰队数据"
        }, -- 出参说明
        logic = "USWorld"
    },
    fleetAttackFleet = {
        desc = "舰队攻击舰队", -- 接口说明
        input = {"fidx", "targetPos"}, -- 入参
        inputDesc = {"攻击方舰队idx", "攻击目标的世界地图坐标idx int"}, -- 入参说明
        output = {
            structs.retInfor,
            structs.mapCell,
            structs.fleetinfor,
            structs.fleetinfor
        }, -- 出参
        outputDesc = {
            "返回信息",
            "被攻击方地块",
            "被攻击方舰队数据",
            "进攻方舰队数据"
        }, -- 出参说明
        logic = "USWorld"
    },
    sendPrepareAttackIsland = {
        desc = "准备攻击岛", -- 接口说明
        input = {}, -- 入参
        inputDesc = {}, -- 入参说明
        output = {
            structs.retInfor,
            structs.player,
            structs.city,
            structs.player,
            structs.city,
            structs.fleetinfor
        }, -- 出参
        outputDesc = {
            "返回信息",
            "被攻击方玩家信息",
            "被攻击方主城信息",
            "攻击方玩家信息",
            "攻击方主城信息",
            "进攻方舰队数据"
        }, -- 出参说明
        logic = "USWorld"
    },
    sendStartAttackIsland = {
        desc = "开始攻击岛", -- 接口说明
        input = {}, -- 入参
        inputDesc = {}, -- 入参说明
        output = {
            structs.retInfor,
            structs.player,
            structs.city,
            {structs.dockyardShips, structs.dockyardShips},
            structs.player,
            structs.fleetinfor,
            "endTimeLimit"
        }, -- 出参
        outputDesc = {
            "返回信息",
            "被攻击方玩家信息",
            "被攻击方主城信息",
            "被攻击方舰船数据",
            "攻击方玩家信息",
            "进攻方舰队数据",
            "战斗限制时间"
        }, -- 出参说明
        logic = "USWorld"
    },
    sendEndAttackIsland = {
        desc = "结束攻击岛", -- 接口说明
        input = {}, -- 入参
        inputDesc = {}, -- 入参说明
        output = {
            structs.retInfor,
            structs.battleresult
        }, -- 出参
        outputDesc = {
            "返回信息",
            "战斗结果"
        }, -- 出参说明
        logic = "USWorld"
    },
    quitIslandBattle = {
        desc = "主动离开攻击岛", -- 接口说明
        input = {"fidx"}, -- 入参
        inputDesc = {"攻击方舰队idx"}, -- 入参说明
        output = {
            structs.retInfor
        }, -- 出参
        outputDesc = {
            "返回信息"
        }, -- 出参说明
        logic = "USWorld"
    },
    onBattleDeployUnit = {
        desc = "战场投放战斗单元", -- 接口说明
        input = {
            "battleFidx",
            structs.unitInfor,
            "frames",
            structs.vector3,
            "fakeRandom",
            "fakeRandom2",
            "fakeRandom3",
            "isOffense"
        }, -- 入参
        inputDesc = {
            "舰队idx",
            "战斗单元信息",
            "投放时的帧数（相较于第一次投入时的帧数增量）",
            "投放坐标（是int，真实值x1000）",
            "随机因子",
            "随机因子2",
            "随机因子3",
            "是进攻方"
        }, -- 入参说明
        output = {
            structs.retInfor
        }, -- 出参
        outputDesc = {
            "返回信息"
        }, -- 出参说明
        logic = "USWorld"
    },
    sendBattleDeployUnit = {
        desc = "推送战斗单元投放", -- 接口说明
        input = {}, -- 入参
        inputDesc = {}, -- 入参说明
        output = {
            structs.retInfor,
            structs.deployUnitInfor
        }, -- 出参
        outputDesc = {
            "返回信息",
            "战斗单元投放信息"
        }, -- 出参说明
        logic = "USWorld"
    },
    onBattleBuildingDie = {
        desc = "当建筑死亡", -- 接口说明
        input = {"battleFidx", "bidx"}, -- 入参
        inputDesc = {"舰队idx", "建筑idx"}, -- 入参说明
        output = {
            structs.retInfor
        }, -- 出参
        outputDesc = {
            "返回信息"
        }, -- 出参说明
        logic = "USWorld"
    },
    onBattleUnitDie = {
        desc = "当战斗单元死亡", -- 接口说明
        input = {"battleFidx", structs.unitInfor}, -- 入参
        inputDesc = {"舰队idx", "战斗单元信息"}, -- 入参说明
        output = {
            structs.retInfor
        }, -- 出参
        outputDesc = {
            "返回信息"
        }, -- 出参说明
        logic = "USWorld"
    },
    onBattleLootRes = {
        desc = "当掠夺到资源时", -- 接口说明
        input = {"battleFidx", "buildingIdx", "resType", "val"}, -- 入参
        inputDesc = {"舰队idx", "建筑idx", "资源类型", "资源值(当是工厂是，值为分钟数)"}, -- 入参说明
        output = {
            structs.retInfor
        }, -- 出参
        outputDesc = {
            "返回信息"
        }, -- 出参说明
        logic = "USWorld"
    },
    getMails = {
        desc = "取得邮件列表", -- 接口说明
        input = {}, -- 入参
        inputDesc = {}, -- 入参说明
        output = {
            structs.retInfor,
            {structs.mail, structs.mail}
        }, -- 出参
        outputDesc = {
            "返回信息",
            "邮件列表"
        }, -- 出参说明
        logic = "cmd4mail"
    },
    onMailChg = {
        desc = "推送邮件", -- 接口说明
        input = {}, -- 入参
        inputDesc = {}, -- 入参说明
        output = {
            structs.retInfor,
            {structs.mail, structs.mail}
        }, -- 出参
        outputDesc = {
            "返回信息",
            "邮件列表"
        }, -- 出参说明
        logic = "cmd4mail"
    },
    sendMail = {
        desc = "发送邮件", -- 接口说明
        input = {"toPidx", "title", "content", "type"}, -- 入参
        inputDesc = {"收件人idx", "标题", "内容", "邮件类型"}, -- 入参说明
        output = {
            structs.retInfor,
            structs.mail
        }, -- 出参
        outputDesc = {
            "返回信息",
            "邮件"
        }, -- 出参说明
        logic = "cmd4mail"
    },
    readMail = {
        desc = "读邮件", -- 接口说明
        input = {"idx"}, -- 入参
        inputDesc = {"邮件idx"}, -- 入参说明
        output = {
            structs.retInfor,
            structs.mail
        }, -- 出参
        outputDesc = {
            "返回信息",
            "邮件"
        }, -- 出参说明
        logic = "cmd4mail"
    },
    receiveRewardMail = {
        desc = "领取邮件的奖励", -- 接口说明
        input = {"idx"}, -- 入参
        inputDesc = {"邮件idx"}, -- 入参说明
        output = {
            structs.retInfor,
            structs.mail
        }, -- 出参
        outputDesc = {
            "返回信息",
            "邮件"
        }, -- 出参说明
        logic = "cmd4mail"
    },
    deleteMail = {
        desc = "删除邮件", -- 接口说明
        input = {"idx", "deleteAll"}, -- 入参
        inputDesc = {"邮件idx", "删除所有 bool"}, -- 入参说明
        output = {
            structs.retInfor
        }, -- 出参
        outputDesc = {
            "返回信息"
        }, -- 出参说明
        logic = "cmd4mail"
    },
    replyMail = {
        desc = "回复邮件", -- 接口说明
        input = {"idx", "content"}, -- 入参
        inputDesc = {"邮件idx", "内容"}, -- 入参说明
        output = {
            structs.retInfor,
            structs.mail
        }, -- 出参
        outputDesc = {
            "返回信息",
            "邮件"
        }, -- 出参说明
        logic = "cmd4mail"
    },
    getReportResult = {
        desc = "取得战报的结果", -- 接口说明
        input = {"idx"}, -- 入参
        inputDesc = {"战报idx"}, -- 入参说明
        output = {
            structs.retInfor,
            structs.battleresult
        }, -- 出参
        outputDesc = {
            "返回信息",
            "战斗结果"
        }, -- 出参说明
        logic = "cmd4mail"
    },
    getReportDetail = {
        desc = "取得战报详细信息", -- 接口说明
        input = {"idx"}, -- 入参
        inputDesc = {"战报idx"}, -- 入参说明
        output = {
            structs.retInfor,
            structs.player,
            structs.city,
            {structs.dockyardShips, structs.dockyardShips},
            structs.player,
            structs.fleetinfor,
            {structs.deployUnitInfor, structs.deployUnitInfor},
            "endFrames",
            structs.battleresult
        }, -- 出参
        outputDesc = {
            "返回信息",
            "被攻击方玩家信息",
            "被攻击方主城信息",
            "被攻击方舰船数据",
            "攻击方玩家信息",
            "进攻方舰队数据",
            "投放战斗单元队列",
            "结束战斗的帧数（相较于第一次投入时的帧数增量）",
            "战斗结果"
        }, -- 出参说明
        logic = "cmd4mail"
    }
}

return defProtocol
