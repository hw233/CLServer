    ---@class NetProtoIsland 网络协议
    local NetProtoIsland = {}
    local table = table
    local CMD = {}
    local skynet = require "skynet"

    require "skynet.manager"    -- import skynet.register
    require("BioUtl")

    NetProtoIsland.dispatch = {}
    --==============================
    -- public toMap
    NetProtoIsland._toMap = function(stuctobj, m)
        local ret = {}
        if m == nil then return ret end
        for k,v in pairs(m) do
            ret[k] = stuctobj.toMap(v)
        end
        return ret
    end
    -- public toList
    NetProtoIsland._toList = function(stuctobj, m)
        local ret = {}
        if m == nil then return ret end
        for i,v in ipairs(m) do
            table.insert(ret, stuctobj.toMap(v))
        end
        return ret
    end
    -- public parse
    NetProtoIsland._parseMap = function(stuctobj, m)
        local ret = {}
        if m == nil then return ret end
        for k,v in pairs(m) do
            ret[k] = stuctobj.parse(v)
        end
        return ret
    end
    -- public parse
    NetProtoIsland._parseList = function(stuctobj, m)
        local ret = {}
        if m == nil then return ret end
        for i,v in ipairs(m) do
            table.insert(ret, stuctobj.parse(v))
        end
        return ret
    end
  --==================================
  --==================================
    ---@class NetProtoIsland.ST_retInfor 返回信息
    ---@field public msg string 返回消息
    ---@field public code number 返回值
    NetProtoIsland.ST_retInfor = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[10] = m.msg  -- 返回消息 string
            r[11] =  BioUtl.number2bio(m.code)  -- 返回值 int
            return r
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.msg = m[10] --  string
            r.code = m[11] --  int
            return r
        end,
    }
    ---@class NetProtoIsland.ST_battleDetail 攻击岛战的详细战报信息
    ---@field public fleet NetProtoIsland.ST_fleetinfor 进攻方舰队数据
    ---@field public deployQueue table 投放战斗单元队列
    ---@field public targetUnits table 被攻击方舰船数据
    ---@field public target NetProtoIsland.ST_player 被攻击方玩家信息
    ---@field public endFrames number 结束战斗的帧数（相较于第一次投入时的帧数增量）
    ---@field public attacker NetProtoIsland.ST_player 攻击方玩家信息
    ---@field public targetCity NetProtoIsland.ST_city 被攻击方主城信息
    NetProtoIsland.ST_battleDetail = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[245] = NetProtoIsland.ST_fleetinfor.toMap(m.fleet) -- 进攻方舰队数据
            r[246] = NetProtoIsland._toList(NetProtoIsland.ST_deployUnitInfor, m.deployQueue)  -- 投放战斗单元队列
            r[247] = NetProtoIsland._toList(NetProtoIsland.ST_unitsInBuilding, m.targetUnits)  -- 被攻击方舰船数据
            r[248] = NetProtoIsland.ST_player.toMap(m.target) -- 被攻击方玩家信息
            r[205] =  BioUtl.number2bio(m.endFrames)  -- 结束战斗的帧数（相较于第一次投入时的帧数增量） int
            r[198] = NetProtoIsland.ST_player.toMap(m.attacker) -- 攻击方玩家信息
            r[249] = NetProtoIsland.ST_city.toMap(m.targetCity) -- 被攻击方主城信息
            return r
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.fleet = NetProtoIsland.ST_fleetinfor.parse(m[245]) --  table
            r.deployQueue = NetProtoIsland._parseList(NetProtoIsland.ST_deployUnitInfor, m[246])  -- 投放战斗单元队列
            r.targetUnits = NetProtoIsland._parseList(NetProtoIsland.ST_unitsInBuilding, m[247])  -- 被攻击方舰船数据
            r.target = NetProtoIsland.ST_player.parse(m[248]) --  table
            r.endFrames = m[205] --  int
            r.attacker = NetProtoIsland.ST_player.parse(m[198]) --  table
            r.targetCity = NetProtoIsland.ST_city.parse(m[249]) --  table
            return r
        end,
    }
    ---@class NetProtoIsland.ST_fleetinfor 舰队数据
    ---@field public idx number 唯一标识舰队idx
    ---@field public curpos number 当前所在世界grid的index
    ---@field public status number 状态 none = 1, -- 无;moving = 2, -- 航行中;docked = 3, -- 停泊在港口;stay = 4, -- 停留在海面;fighting = 5 -- 正在战斗中
    ---@field public deadtime number 沉没的时间
    ---@field public pname string 玩家名
    ---@field public units table 战斗单元列表
    ---@field public frompos number 出征的开始所在世界grid的index
    ---@field public arrivetime number 到达时间
    ---@field public cidx number 城市idx
    ---@field public name string 舰队名称
    ---@field public topos number 出征的目地所在世界grid的index
    ---@field public fromposv3 NetProtoIsland.ST_vector3 坐标
    ---@field public task number 执行任务类型 idel = 1, -- 待命状态;voyage = 2, -- 出征;back = 3, -- 返航;attack = 4 -- 攻击
    ---@field public pidx number 玩家idx
    NetProtoIsland.ST_fleetinfor = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[16] =  BioUtl.number2bio(m.idx)  -- 唯一标识舰队idx int
            r[113] =  BioUtl.number2bio(m.curpos)  -- 当前所在世界grid的index int
            r[37] =  BioUtl.number2bio(m.status)  -- 状态 none = 1, -- 无;moving = 2, -- 航行中;docked = 3, -- 停泊在港口;stay = 4, -- 停留在海面;fighting = 5 -- 正在战斗中 int
            r[104] =  BioUtl.number2bio(m.deadtime)  -- 沉没的时间 int
            r[127] = m.pname  -- 玩家名 string
            r[103] = NetProtoIsland._toList(NetProtoIsland.ST_unitInfor, m.units)  -- 战斗单元列表
            r[114] =  BioUtl.number2bio(m.frompos)  -- 出征的开始所在世界grid的index int
            r[118] =  BioUtl.number2bio(m.arrivetime)  -- 到达时间 int
            r[18] =  BioUtl.number2bio(m.cidx)  -- 城市idx int
            r[35] = m.name  -- 舰队名称 string
            r[115] =  BioUtl.number2bio(m.topos)  -- 出征的目地所在世界grid的index int
            r[122] = NetProtoIsland.ST_vector3.toMap(m.fromposv3) -- 坐标
            r[119] =  BioUtl.number2bio(m.task)  -- 执行任务类型 idel = 1, -- 待命状态;voyage = 2, -- 出征;back = 3, -- 返航;attack = 4 -- 攻击 int
            r[38] =  BioUtl.number2bio(m.pidx)  -- 玩家idx int
            return r
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[16] --  int
            r.curpos = m[113] --  int
            r.status = m[37] --  int
            r.deadtime = m[104] --  int
            r.pname = m[127] --  string
            r.units = NetProtoIsland._parseList(NetProtoIsland.ST_unitInfor, m[103])  -- 战斗单元列表
            r.frompos = m[114] --  int
            r.arrivetime = m[118] --  int
            r.cidx = m[18] --  int
            r.name = m[35] --  string
            r.topos = m[115] --  int
            r.fromposv3 = NetProtoIsland.ST_vector3.parse(m[122]) --  table
            r.task = m[119] --  int
            r.pidx = m[38] --  int
            return r
        end,
    }
    ---@class NetProtoIsland.ST_building 建筑信息对象
    ---@field public idx number 唯一标识 int
    ---@field public val4 number 值4。如:产量，仓库的存储量等 int
    ---@field public val3 number 值3。如:产量，仓库的存储量等 int
    ---@field public val2 number 值2。如:产量，仓库的存储量等 int
    ---@field public endtime number 完成升级、恢复、采集等的时间点 long
    ---@field public lev number 等级 int
    ---@field public val number 值。如:产量，仓库的存储量等 int
    ---@field public cidx number 主城idx int
    ---@field public val5 number 值5。如:产量，仓库的存储量等 int
    ---@field public attrid number 属性配置id int
    ---@field public starttime number 开始升级、恢复、采集等的时间点 long
    ---@field public state number 状态. 0：正常；1：升级中；9：恢复中
    ---@field public pos number 位置，即在城的gird中的index int
    NetProtoIsland.ST_building = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[16] =  BioUtl.number2bio(m.idx)  -- 唯一标识 int int
            r[20] =  BioUtl.number2bio(m.val4)  -- 值4。如:产量，仓库的存储量等 int int
            r[21] =  BioUtl.number2bio(m.val3)  -- 值3。如:产量，仓库的存储量等 int int
            r[22] =  BioUtl.number2bio(m.val2)  -- 值2。如:产量，仓库的存储量等 int int
            r[23] =  BioUtl.number2bio(m.endtime)  -- 完成升级、恢复、采集等的时间点 long int
            r[24] =  BioUtl.number2bio(m.lev)  -- 等级 int int
            r[25] =  BioUtl.number2bio(m.val)  -- 值。如:产量，仓库的存储量等 int int
            r[18] =  BioUtl.number2bio(m.cidx)  -- 主城idx int int
            r[26] =  BioUtl.number2bio(m.val5)  -- 值5。如:产量，仓库的存储量等 int int
            r[17] =  BioUtl.number2bio(m.attrid)  -- 属性配置id int int
            r[27] =  BioUtl.number2bio(m.starttime)  -- 开始升级、恢复、采集等的时间点 long int
            r[28] =  BioUtl.number2bio(m.state)  -- 状态. 0：正常；1：升级中；9：恢复中 int
            r[19] =  BioUtl.number2bio(m.pos)  -- 位置，即在城的gird中的index int int
            return r
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[16] --  int
            r.val4 = m[20] --  int
            r.val3 = m[21] --  int
            r.val2 = m[22] --  int
            r.endtime = m[23] --  int
            r.lev = m[24] --  int
            r.val = m[25] --  int
            r.cidx = m[18] --  int
            r.val5 = m[26] --  int
            r.attrid = m[17] --  int
            r.starttime = m[27] --  int
            r.state = m[28] --  int
            r.pos = m[19] --  int
            return r
        end,
    }
    ---@class NetProtoIsland.ST_mapCell 大地图地块数据
    ---@field public idx number 网格index
    ---@field public pageIdx number 所在屏的index
    ---@field public val2 number 值2
    ---@field public val3 number 值3
    ---@field public lev number 等级
    ---@field public type number 地块类型 3：玩家，4：npc
    ---@field public cidx number 主城idx
    ---@field public val1 number 值1
    ---@field public attrid number 配置id
    ---@field public state number 状态  1:正常; int
    ---@field public name string 名称
    ---@field public fidx number 舰队idx
    NetProtoIsland.ST_mapCell = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[16] =  BioUtl.number2bio(m.idx)  -- 网格index int
            r[13] =  BioUtl.number2bio(m.pageIdx)  -- 所在屏的index int
            r[22] =  BioUtl.number2bio(m.val2)  -- 值2 int
            r[21] =  BioUtl.number2bio(m.val3)  -- 值3 int
            r[24] =  BioUtl.number2bio(m.lev)  -- 等级 int
            r[30] =  BioUtl.number2bio(m.type)  -- 地块类型 3：玩家，4：npc int
            r[18] =  BioUtl.number2bio(m.cidx)  -- 主城idx int
            r[29] =  BioUtl.number2bio(m.val1)  -- 值1 int
            r[17] =  BioUtl.number2bio(m.attrid)  -- 配置id int
            r[28] =  BioUtl.number2bio(m.state)  -- 状态  1:正常; int int
            r[35] = m.name  -- 名称 string
            r[101] =  BioUtl.number2bio(m.fidx)  -- 舰队idx int
            return r
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[16] --  int
            r.pageIdx = m[13] --  int
            r.val2 = m[22] --  int
            r.val3 = m[21] --  int
            r.lev = m[24] --  int
            r.type = m[30] --  int
            r.cidx = m[18] --  int
            r.val1 = m[29] --  int
            r.attrid = m[17] --  int
            r.state = m[28] --  int
            r.name = m[35] --  string
            r.fidx = m[101] --  int
            return r
        end,
    }
    ---@class NetProtoIsland.ST_resInfor 资源信息
    ---@field public oil number 油
    ---@field public gold number 金
    ---@field public food number 粮
    NetProtoIsland.ST_resInfor = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[31] =  BioUtl.number2bio(m.oil)  -- 油 int
            r[32] =  BioUtl.number2bio(m.gold)  -- 金 int
            r[33] =  BioUtl.number2bio(m.food)  -- 粮 int
            return r
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.oil = m[31] --  int
            r.gold = m[32] --  int
            r.food = m[33] --  int
            return r
        end,
    }
    ---@class NetProtoIsland.ST_city 主城
    ---@field public idx number 唯一标识 int
    ---@field public protectEndTime number 免战结束时间
    ---@field public tiles table 地块信息 key=idx, map
    ---@field public techs table 科技列表
    ---@field public lev number 等级 int
    ---@field public name string 名称
    ---@field public buildings table 建筑信息 key=idx, map
    ---@field public status number 状态 1:正常; int
    ---@field public pos number 城所在世界grid的index int
    ---@field public pidx number 玩家idx int
    NetProtoIsland.ST_city = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[16] =  BioUtl.number2bio(m.idx)  -- 唯一标识 int int
            r[144] =  BioUtl.number2bio(m.protectEndTime)  -- 免战结束时间 int
            r[34] = NetProtoIsland._toMap(NetProtoIsland.ST_tile, m.tiles)  -- 地块信息 key=idx, map
            r[256] = NetProtoIsland._toList(NetProtoIsland.ST_techInfor, m.techs)  -- 科技列表
            r[24] =  BioUtl.number2bio(m.lev)  -- 等级 int int
            r[35] = m.name  -- 名称 string
            r[36] = NetProtoIsland._toMap(NetProtoIsland.ST_building, m.buildings)  -- 建筑信息 key=idx, map
            r[37] =  BioUtl.number2bio(m.status)  -- 状态 1:正常; int int
            r[19] =  BioUtl.number2bio(m.pos)  -- 城所在世界grid的index int int
            r[38] =  BioUtl.number2bio(m.pidx)  -- 玩家idx int int
            return r
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[16] --  int
            r.protectEndTime = m[144] --  int
            r.tiles = NetProtoIsland._parseMap(NetProtoIsland.ST_tile, m[34])  -- 地块信息 key=idx, map
            r.techs = NetProtoIsland._parseList(NetProtoIsland.ST_techInfor, m[256])  -- 科技列表
            r.lev = m[24] --  int
            r.name = m[35] --  string
            r.buildings = NetProtoIsland._parseMap(NetProtoIsland.ST_building, m[36])  -- 建筑信息 key=idx, map
            r.status = m[37] --  int
            r.pos = m[19] --  int
            r.pidx = m[38] --  int
            return r
        end,
    }
    ---@class NetProtoIsland.ST_unitFormation 战斗单元阵形
    ---@field public idx number 单元的idx
    ---@field public type number 战斗单元类型
    ---@field public id number 战斗单元id(配置表的id)
    ---@field public lev number 战斗单元等级
    ---@field public pos number 位置：网格的index
    NetProtoIsland.ST_unitFormation = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[16] =  BioUtl.number2bio(m.idx)  -- 单元的idx int
            r[30] =  BioUtl.number2bio(m.type)  -- 战斗单元类型 int
            r[99] =  BioUtl.number2bio(m.id)  -- 战斗单元id(配置表的id) int
            r[24] =  BioUtl.number2bio(m.lev)  -- 战斗单元等级 int
            r[19] =  BioUtl.number2bio(m.pos)  -- 位置：网格的index int
            return r
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[16] --  int
            r.type = m[30] --  int
            r.id = m[99] --  int
            r.lev = m[24] --  int
            r.pos = m[19] --  int
            return r
        end,
    }
    ---@class NetProtoIsland.ST_chatInfor 聊天消息
    ---@field public idx number 唯一标识
    ---@field public type number 类型, IDConst.ChatType
    ---@field public time number 发送时间
    ---@field public toPidx number 收信人(其它信息通过接口取得)
    ---@field public content string 内容
    ---@field public fromPidx number 发送人(其它信息通过接口取得)
    NetProtoIsland.ST_chatInfor = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[16] =  BioUtl.number2bio(m.idx)  -- 唯一标识 int
            r[30] =  BioUtl.number2bio(m.type)  -- 类型, IDConst.ChatType int
            r[218] =  BioUtl.number2bio(m.time)  -- 发送时间 int
            r[178] =  BioUtl.number2bio(m.toPidx)  -- 收信人(其它信息通过接口取得) int
            r[180] = m.content  -- 内容 string
            r[181] =  BioUtl.number2bio(m.fromPidx)  -- 发送人(其它信息通过接口取得) int
            return r
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[16] --  int
            r.type = m[30] --  int
            r.time = m[218] --  int
            r.toPidx = m[178] --  int
            r.content = m[180] --  string
            r.fromPidx = m[181] --  int
            return r
        end,
    }
    ---@class NetProtoIsland.ST_item 奖励包
    ---@field public idx number 唯一标识
    ---@field public type number 类型,IDConst.ItemType
    ---@field public num number 数量
    ---@field public id number 对应的id
    NetProtoIsland.ST_item = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[16] =  BioUtl.number2bio(m.idx)  -- 唯一标识 int
            r[30] =  BioUtl.number2bio(m.type)  -- 类型,IDConst.ItemType int
            r[67] =  BioUtl.number2bio(m.num)  -- 数量 int
            r[99] =  BioUtl.number2bio(m.id)  -- 对应的id int
            return r
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[16] --  int
            r.type = m[30] --  int
            r.num = m[67] --  int
            r.id = m[99] --  int
            return r
        end,
    }
    ---@class NetProtoIsland.ST_vector3 坐标(注意使用时需要/1000
    ---@field public y number int
    ---@field public x number int
    ---@field public z number int
    NetProtoIsland.ST_vector3 = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[123] =  BioUtl.number2bio(m.y)  -- int int
            r[124] =  BioUtl.number2bio(m.x)  -- int int
            r[125] =  BioUtl.number2bio(m.z)  -- int int
            return r
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.y = m[123] --  int
            r.x = m[124] --  int
            r.z = m[125] --  int
            return r
        end,
    }
    ---@class NetProtoIsland.ST_fleetFormation 舰队阵形数据
    ---@field public idx number 唯一标识舰队idx
    ---@field public name string 名称
    ---@field public formations table 战斗单元阵形
    ---@field public pname string 玩家名
    ---@field public pidx number 玩家idx
    NetProtoIsland.ST_fleetFormation = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[16] =  BioUtl.number2bio(m.idx)  -- 唯一标识舰队idx int
            r[35] = m.name  -- 名称 string
            r[229] = NetProtoIsland._toList(NetProtoIsland.ST_unitFormation, m.formations)  -- 战斗单元阵形
            r[127] = m.pname  -- 玩家名 string
            r[38] =  BioUtl.number2bio(m.pidx)  -- 玩家idx int
            return r
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[16] --  int
            r.name = m[35] --  string
            r.formations = NetProtoIsland._parseList(NetProtoIsland.ST_unitFormation, m[229])  -- 战斗单元阵形
            r.pname = m[127] --  string
            r.pidx = m[38] --  int
            return r
        end,
    }
    ---@class NetProtoIsland.ST_mapPage 一屏大地图数据
    ---@field public cells table 地图数据 key=网络index, map
    ---@field public pageIdx number 一屏所在的网格index 
    NetProtoIsland.ST_mapPage = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[12] = NetProtoIsland._toList(NetProtoIsland.ST_mapCell, m.cells)  -- 地图数据 key=网络index, map
            r[13] =  BioUtl.number2bio(m.pageIdx)  -- 一屏所在的网格index  int
            return r
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.cells = NetProtoIsland._parseList(NetProtoIsland.ST_mapCell, m[12])  -- 地图数据 key=网络index, map
            r.pageIdx = m[13] --  int
            return r
        end,
    }
    ---@class NetProtoIsland.ST_unitInfor 单元(舰船、萌宠等)
    ---@field public lev number 等级(大部分情况下lev可能是0，而是由科技决定，但是联盟里的兵等级是有值的) int
    ---@field public type number 类型id(UnitType：role = 2, -- (ship, pet)；tech = 3,；skill = 4) int
    ---@field public id number 配置的id int
    ---@field public bidx number 所属建筑idx int
    ---@field public num number 数量 int
    ---@field public fidx number 所属舰队idx int
    NetProtoIsland.ST_unitInfor = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[24] =  BioUtl.number2bio(m.lev)  -- 等级(大部分情况下lev可能是0，而是由科技决定，但是联盟里的兵等级是有值的) int int
            r[30] =  BioUtl.number2bio(m.type)  -- 类型id(UnitType：role = 2, -- (ship, pet)；tech = 3,；skill = 4) int int
            r[99] =  BioUtl.number2bio(m.id)  -- 配置的id int int
            r[100] =  BioUtl.number2bio(m.bidx)  -- 所属建筑idx int int
            r[67] =  BioUtl.number2bio(m.num)  -- 数量 int int
            r[101] =  BioUtl.number2bio(m.fidx)  -- 所属舰队idx int int
            return r
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.lev = m[24] --  int
            r.type = m[30] --  int
            r.id = m[99] --  int
            r.bidx = m[100] --  int
            r.num = m[67] --  int
            r.fidx = m[101] --  int
            return r
        end,
    }
    ---@class NetProtoIsland.ST_tile 建筑信息对象
    ---@field public idx number 唯一标识 int
    ---@field public attrid number 属性配置id int
    ---@field public cidx number 主城idx int
    ---@field public pos number 位置，即在城的gird中的index int
    NetProtoIsland.ST_tile = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[16] =  BioUtl.number2bio(m.idx)  -- 唯一标识 int int
            r[17] =  BioUtl.number2bio(m.attrid)  -- 属性配置id int int
            r[18] =  BioUtl.number2bio(m.cidx)  -- 主城idx int int
            r[19] =  BioUtl.number2bio(m.pos)  -- 位置，即在城的gird中的index int int
            return r
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[16] --  int
            r.attrid = m[17] --  int
            r.cidx = m[18] --  int
            r.pos = m[19] --  int
            return r
        end,
    }
    ---@class NetProtoIsland.ST_unitsInBuilding 建筑里的战斗单元
    ---@field public units table 舰船数据
    ---@field public buildingIdx number 建筑的idx
    NetProtoIsland.ST_unitsInBuilding = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[103] = NetProtoIsland._toList(NetProtoIsland.ST_unitInfor, m.units)  -- 舰船数据
            r[15] =  BioUtl.number2bio(m.buildingIdx)  -- 建筑的idx int
            return r
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.units = NetProtoIsland._parseList(NetProtoIsland.ST_unitInfor, m[103])  -- 舰船数据
            r.buildingIdx = m[15] --  int
            return r
        end,
    }
    ---@class NetProtoIsland.ST_battleUnitInfor 战斗中的战斗单元详细
    ---@field public lev number 等级
    ---@field public type number 类型id(UnitType：role = 2, -- (ship, pet)；tech = 3,；skill = 4) int
    ---@field public id number 配置的id int
    ---@field public deployNum number 投放数量/原始数量
    ---@field public deadNum number 死亡数量
    NetProtoIsland.ST_battleUnitInfor = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[24] =  BioUtl.number2bio(m.lev)  -- 等级 int
            r[30] =  BioUtl.number2bio(m.type)  -- 类型id(UnitType：role = 2, -- (ship, pet)；tech = 3,；skill = 4) int int
            r[99] =  BioUtl.number2bio(m.id)  -- 配置的id int int
            r[168] =  BioUtl.number2bio(m.deployNum)  -- 投放数量/原始数量 int
            r[169] =  BioUtl.number2bio(m.deadNum)  -- 死亡数量 int
            return r
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.lev = m[24] --  int
            r.type = m[30] --  int
            r.id = m[99] --  int
            r.deployNum = m[168] --  int
            r.deadNum = m[169] --  int
            return r
        end,
    }
    ---@class NetProtoIsland.ST_techInfor 科技信息
    ---@field public idx number 唯一标识
    ---@field public lev number 等级
    ---@field public id number 配置id
    NetProtoIsland.ST_techInfor = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[16] =  BioUtl.number2bio(m.idx)  -- 唯一标识 int
            r[24] =  BioUtl.number2bio(m.lev)  -- 等级 int
            r[99] =  BioUtl.number2bio(m.id)  -- 配置id int
            return r
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[16] --  int
            r.lev = m[24] --  int
            r.id = m[99] --  int
            return r
        end,
    }
    ---@class NetProtoIsland.ST_battleresult 战斗结果
    ---@field public attackerUsedUnits table 进攻方投入的战斗单元
    ---@field public honor number 获得的功勋
    ---@field public attacker NetProtoIsland.ST_playerSimple 进攻方
    ---@field public fidx number 舰队idx
    ---@field public lootRes NetProtoIsland.ST_resInfor 掠夺的资源
    ---@field public targetUsedUnits table 防守方损失的战斗单元
    ---@field public star number 星级, 0表示失败，1-3星才算胜利
    ---@field public defender NetProtoIsland.ST_playerSimple 防守方
    ---@field public type number 战斗类型
    NetProtoIsland.ST_battleresult = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[166] = NetProtoIsland._toList(NetProtoIsland.ST_battleUnitInfor, m.attackerUsedUnits)  -- 进攻方投入的战斗单元
            r[210] =  BioUtl.number2bio(m.honor)  -- 获得的功勋 int
            r[198] = NetProtoIsland.ST_playerSimple.toMap(m.attacker) -- 进攻方
            r[101] =  BioUtl.number2bio(m.fidx)  -- 舰队idx int
            r[131] = NetProtoIsland.ST_resInfor.toMap(m.lootRes) -- 掠夺的资源
            r[167] = NetProtoIsland._toList(NetProtoIsland.ST_battleUnitInfor, m.targetUsedUnits)  -- 防守方损失的战斗单元
            r[135] =  BioUtl.number2bio(m.star)  -- 星级, 0表示失败，1-3星才算胜利 int
            r[197] = NetProtoIsland.ST_playerSimple.toMap(m.defender) -- 防守方
            r[30] =  BioUtl.number2bio(m.type)  -- 战斗类型 int
            return r
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.attackerUsedUnits = NetProtoIsland._parseList(NetProtoIsland.ST_battleUnitInfor, m[166])  -- 进攻方投入的战斗单元
            r.honor = m[210] --  int
            r.attacker = NetProtoIsland.ST_playerSimple.parse(m[198]) --  table
            r.fidx = m[101] --  int
            r.lootRes = NetProtoIsland.ST_resInfor.parse(m[131]) --  table
            r.targetUsedUnits = NetProtoIsland._parseList(NetProtoIsland.ST_battleUnitInfor, m[167])  -- 防守方损失的战斗单元
            r.star = m[135] --  int
            r.defender = NetProtoIsland.ST_playerSimple.parse(m[197]) --  table
            r.type = m[30] --  int
            return r
        end,
    }
    ---@class NetProtoIsland.ST_rewardInfor 奖励包
    ---@field public idx number 唯一标识
    ---@field public type number 类型,IDConst.ItemType
    ---@field public id number 对应的id
    ---@field public num number 数量
    ---@field public rwidx number 奖励包idx
    NetProtoIsland.ST_rewardInfor = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[16] =  BioUtl.number2bio(m.idx)  -- 唯一标识 int
            r[30] =  BioUtl.number2bio(m.type)  -- 类型,IDConst.ItemType int
            r[99] =  BioUtl.number2bio(m.id)  -- 对应的id int
            r[67] =  BioUtl.number2bio(m.num)  -- 数量 int
            r[206] =  BioUtl.number2bio(m.rwidx)  -- 奖励包idx int
            return r
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[16] --  int
            r.type = m[30] --  int
            r.id = m[99] --  int
            r.num = m[67] --  int
            r.rwidx = m[206] --  int
            return r
        end,
    }
    ---@class NetProtoIsland.ST_player 用户信息
    ---@field public idx number 唯一标识 int
    ---@field public exp number 经验值 long
    ---@field public honor number 功勋 long
    ---@field public cityidx number 城池id int
    ---@field public pvptimesTody number 今天进攻玩家的次数 int
    ---@field public unionidx number 联盟id int
    ---@field public lev number 等级 long
    ---@field public attacking useData 正在攻击玩家的岛屿
    ---@field public name string 名字
    ---@field public diam4reward number 钻石 long
    ---@field public diam number 钻石 long
    ---@field public status number 状态 1：正常 int
    ---@field public icon number 头像
    ---@field public beingattacked useData 正在被玩家攻击
    NetProtoIsland.ST_player = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[16] =  BioUtl.number2bio(m.idx)  -- 唯一标识 int int
            r[132] =  BioUtl.number2bio(m.exp)  -- 经验值 long int
            r[210] =  BioUtl.number2bio(m.honor)  -- 功勋 long int
            r[40] =  BioUtl.number2bio(m.cityidx)  -- 城池id int int
            r[228] =  BioUtl.number2bio(m.pvptimesTody)  -- 今天进攻玩家的次数 int int
            r[41] =  BioUtl.number2bio(m.unionidx)  -- 联盟id int int
            r[24] =  BioUtl.number2bio(m.lev)  -- 等级 long int
            r[146] = m.attacking  -- 正在攻击玩家的岛屿 boolean
            r[35] = m.name  -- 名字 string
            r[136] =  BioUtl.number2bio(m.diam4reward)  -- 钻石 long int
            r[39] =  BioUtl.number2bio(m.diam)  -- 钻石 long int
            r[37] =  BioUtl.number2bio(m.status)  -- 状态 1：正常 int int
            r[217] =  BioUtl.number2bio(m.icon)  -- 头像 int
            r[147] = m.beingattacked  -- 正在被玩家攻击 boolean
            return r
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[16] --  int
            r.exp = m[132] --  int
            r.honor = m[210] --  int
            r.cityidx = m[40] --  int
            r.pvptimesTody = m[228] --  int
            r.unionidx = m[41] --  int
            r.lev = m[24] --  int
            r.attacking = m[146] --  boolean
            r.name = m[35] --  string
            r.diam4reward = m[136] --  int
            r.diam = m[39] --  int
            r.status = m[37] --  int
            r.icon = m[217] --  int
            r.beingattacked = m[147] --  boolean
            return r
        end,
    }
    ---@class NetProtoIsland.ST_unitAction 战斗单元的行为
    ---@field public idx number 单元的idx
    ---@field public timeMs number 行为发生时的时间毫秒(从战斗开始后)
    ---@field public action number 行为类型1：攻击，2：移动，3：扣血，4：死亡
    ---@field public targetVal number 当是攻击时是目标对象的idx；当时扣血时，是血量
    NetProtoIsland.ST_unitAction = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[16] =  BioUtl.number2bio(m.idx)  -- 单元的idx int
            r[239] =  BioUtl.number2bio(m.timeMs)  -- 行为发生时的时间毫秒(从战斗开始后) int
            r[230] =  BioUtl.number2bio(m.action)  -- 行为类型1：攻击，2：移动，3：扣血，4：死亡 int
            r[231] =  BioUtl.number2bio(m.targetVal)  -- 当是攻击时是目标对象的idx；当时扣血时，是血量 int
            return r
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[16] --  int
            r.timeMs = m[239] --  int
            r.action = m[230] --  int
            r.targetVal = m[231] --  int
            return r
        end,
    }
    ---@class NetProtoIsland.ST_deployUnitInfor 战斗单元投放信息
    ---@field public unitInfor NetProtoIsland.ST_unitInfor 战斗单元
    ---@field public fakeRandom number 随机因子
    ---@field public fakeRandom2 number 随机因子
    ---@field public fakeRandom3 number 随机因子
    ---@field public frames number 投放时的帧数（相较于第一次投放时的帧数增量）
    ---@field public pos NetProtoIsland.ST_vector3 投放坐标（是int，真实值x1000）
    NetProtoIsland.ST_deployUnitInfor = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[151] = NetProtoIsland.ST_unitInfor.toMap(m.unitInfor) -- 战斗单元
            r[161] =  BioUtl.number2bio(m.fakeRandom)  -- 随机因子 int
            r[162] =  BioUtl.number2bio(m.fakeRandom2)  -- 随机因子 int
            r[163] =  BioUtl.number2bio(m.fakeRandom3)  -- 随机因子 int
            r[156] =  BioUtl.number2bio(m.frames)  -- 投放时的帧数（相较于第一次投放时的帧数增量） int
            r[19] = NetProtoIsland.ST_vector3.toMap(m.pos) -- 投放坐标（是int，真实值x1000）
            return r
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.unitInfor = NetProtoIsland.ST_unitInfor.parse(m[151]) --  table
            r.fakeRandom = m[161] --  int
            r.fakeRandom2 = m[162] --  int
            r.fakeRandom3 = m[163] --  int
            r.frames = m[156] --  int
            r.pos = NetProtoIsland.ST_vector3.parse(m[19]) --  table
            return r
        end,
    }
    ---@class NetProtoIsland.ST_mail 邮件
    ---@field public fromName string 发件人名称
    ---@field public titleParams string 标题参数(json的map)
    ---@field public parent number 父邮件idx（大于0时表示是回复的邮件）
    ---@field public toName string 收件人名称
    ---@field public type number 类型，1：系统，2：战报；3：私信，4:联盟，5：客服
    ---@field public fromPidx number 发件人
    ---@field public idx number 唯一标识
    ---@field public fromIcon number 发件人头像id
    ---@field public backup string 备用
    ---@field public toIcon number 收件人头像id
    ---@field public comIdx number 通用ID,可以关联到比如战报等
    ---@field public state number 状态，0：未读，1：已读&未领奖，2：已读&已领奖
    ---@field public contentParams string 内容参数(json的map)
    ---@field public title string 标题
    ---@field public rewardIdx number 奖励idx
    ---@field public toPidx number 收件人
    ---@field public historyList table 历史记录(邮件的idx列表)
    ---@field public content string 内容
    ---@field public date number 时间
    NetProtoIsland.ST_mail = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[170] = m.fromName  -- 发件人名称 string
            r[185] = m.titleParams  -- 标题参数(json的map) string
            r[202] =  BioUtl.number2bio(m.parent)  -- 父邮件idx（大于0时表示是回复的邮件） int
            r[174] = m.toName  -- 收件人名称 string
            r[30] =  BioUtl.number2bio(m.type)  -- 类型，1：系统，2：战报；3：私信，4:联盟，5：客服 int
            r[181] =  BioUtl.number2bio(m.fromPidx)  -- 发件人 int
            r[16] =  BioUtl.number2bio(m.idx)  -- 唯一标识 int
            r[179] =  BioUtl.number2bio(m.fromIcon)  -- 发件人头像id int
            r[172] = m.backup  -- 备用 string
            r[173] =  BioUtl.number2bio(m.toIcon)  -- 收件人头像id int
            r[175] =  BioUtl.number2bio(m.comIdx)  -- 通用ID,可以关联到比如战报等 int
            r[28] =  BioUtl.number2bio(m.state)  -- 状态，0：未读，1：已读&未领奖，2：已读&已领奖 int
            r[184] = m.contentParams  -- 内容参数(json的map) string
            r[176] = m.title  -- 标题 string
            r[177] =  BioUtl.number2bio(m.rewardIdx)  -- 奖励idx int
            r[178] =  BioUtl.number2bio(m.toPidx)  -- 收件人 int
            r[203] = m.historyList  -- 历史记录(邮件的idx列表)
            r[180] = m.content  -- 内容 string
            r[171] =  BioUtl.number2bio(m.date)  -- 时间 int
            return r
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.fromName = m[170] --  string
            r.titleParams = m[185] --  string
            r.parent = m[202] --  int
            r.toName = m[174] --  string
            r.type = m[30] --  int
            r.fromPidx = m[181] --  int
            r.idx = m[16] --  int
            r.fromIcon = m[179] --  int
            r.backup = m[172] --  string
            r.toIcon = m[173] --  int
            r.comIdx = m[175] --  int
            r.state = m[28] --  int
            r.contentParams = m[184] --  string
            r.title = m[176] --  string
            r.rewardIdx = m[177] --  int
            r.toPidx = m[178] --  int
            r.historyList = m[203] --  table
            r.content = m[180] --  string
            r.date = m[171] --  int
            return r
        end,
    }
    ---@class NetProtoIsland.ST_netCfg 网络协议解析配置
    ---@field public encryptType number 加密类别，1：只加密客户端，2：只加密服务器，3：前后端都加密，0及其它情况：不加密
    ---@field public checkTimeStamp useData 检测时间戳
    ---@field public secretKey string 密钥
    NetProtoIsland.ST_netCfg = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[83] =  BioUtl.number2bio(m.encryptType)  -- 加密类别，1：只加密客户端，2：只加密服务器，3：前后端都加密，0及其它情况：不加密 int
            r[85] = m.checkTimeStamp  -- 检测时间戳 boolean
            r[84] = m.secretKey  -- 密钥 string
            return r
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.encryptType = m[83] --  int
            r.checkTimeStamp = m[85] --  boolean
            r.secretKey = m[84] --  string
            return r
        end,
    }
    ---@class NetProtoIsland.ST_playerSimple 用户精简信息
    ---@field public idx number 唯一标识 int
    ---@field public point number 功勋 long
    ---@field public honor number 功勋 int
    ---@field public cityidx number 城池id int
    ---@field public lev number 等级 long
    ---@field public name string 名字
    ---@field public unionidx number 联盟id int
    ---@field public exp number 经验值 long
    ---@field public icon number 头像
    ---@field public status number 状态 1：正常 int
    NetProtoIsland.ST_playerSimple = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[16] =  BioUtl.number2bio(m.idx)  -- 唯一标识 int int
            r[204] =  BioUtl.number2bio(m.point)  -- 功勋 long int
            r[210] =  BioUtl.number2bio(m.honor)  -- 功勋 int int
            r[40] =  BioUtl.number2bio(m.cityidx)  -- 城池id int int
            r[24] =  BioUtl.number2bio(m.lev)  -- 等级 long int
            r[35] = m.name  -- 名字 string
            r[41] =  BioUtl.number2bio(m.unionidx)  -- 联盟id int int
            r[132] =  BioUtl.number2bio(m.exp)  -- 经验值 long int
            r[217] =  BioUtl.number2bio(m.icon)  -- 头像 int
            r[37] =  BioUtl.number2bio(m.status)  -- 状态 1：正常 int int
            return r
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[16] --  int
            r.point = m[204] --  int
            r.honor = m[210] --  int
            r.cityidx = m[40] --  int
            r.lev = m[24] --  int
            r.name = m[35] --  string
            r.unionidx = m[41] --  int
            r.exp = m[132] --  int
            r.icon = m[217] --  int
            r.status = m[37] --  int
            return r
        end,
    }
    ---@class NetProtoIsland.ST_battleFleetDetail 舰队战的详细战报信息
    ---@field public defensePlayer NetProtoIsland.ST_playerSimple 防守方玩家
    ---@field public actionQueue table 行为列表
    ---@field public defenseFleet NetProtoIsland.ST_fleetFormation 防守方舰队阵型
    ---@field public attackFleet NetProtoIsland.ST_fleetFormation 进攻方舰队阵型
    ---@field public attackPlayer NetProtoIsland.ST_playerSimple 进攻方玩家
    NetProtoIsland.ST_battleFleetDetail = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[232] = NetProtoIsland.ST_playerSimple.toMap(m.defensePlayer) -- 防守方玩家
            r[233] = NetProtoIsland._toList(NetProtoIsland.ST_unitAction, m.actionQueue)  -- 行为列表
            r[234] = NetProtoIsland.ST_fleetFormation.toMap(m.defenseFleet) -- 防守方舰队阵型
            r[235] = NetProtoIsland.ST_fleetFormation.toMap(m.attackFleet) -- 进攻方舰队阵型
            r[236] = NetProtoIsland.ST_playerSimple.toMap(m.attackPlayer) -- 进攻方玩家
            return r
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.defensePlayer = NetProtoIsland.ST_playerSimple.parse(m[232]) --  table
            r.actionQueue = NetProtoIsland._parseList(NetProtoIsland.ST_unitAction, m[233])  -- 行为列表
            r.defenseFleet = NetProtoIsland.ST_fleetFormation.parse(m[234]) --  table
            r.attackFleet = NetProtoIsland.ST_fleetFormation.parse(m[235]) --  table
            r.attackPlayer = NetProtoIsland.ST_playerSimple.parse(m[236]) --  table
            return r
        end,
    }
    --==============================
    ---@class NetProtoIsland.RC_Base
    ---@field public cmd number
    ---@field public __session__ string

    NetProtoIsland.recive = {
    -- 道具变化通知
    ---@class NetProtoIsland.RC_onItemChg : NetProtoIsland.RC_Base
    onItemChg = function(map)
        local ret = {}
        ret.cmd = "onItemChg"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        return ret
    end,
    -- 当掠夺到资源时
    ---@class NetProtoIsland.RC_onBattleLootRes : NetProtoIsland.RC_Base
    ---@field public battleFidx  舰队idx
    ---@field public buildingIdx  建筑idx
    ---@field public resType  资源类型
    ---@field public val  资源值(当是工厂是，值为分钟数)
    onBattleLootRes = function(map)
        local ret = {}
        ret.cmd = "onBattleLootRes"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.battleFidx = map[149] -- 舰队idx
        ret.buildingIdx = map[15] -- 建筑idx
        ret.resType = map[78] -- 资源类型
        ret.val = map[25] -- 资源值(当是工厂是，值为分钟数)
        return ret
    end,
    -- 舰队出征
    ---@class NetProtoIsland.RC_fleetDepart : NetProtoIsland.RC_Base
    ---@field public idx  舰队idx
    ---@field public toPos  目标位置
    fleetDepart = function(map)
        local ret = {}
        ret.cmd = "fleetDepart"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.idx = map[16] -- 舰队idx
        ret.toPos = map[109] -- 目标位置
        return ret
    end,
    -- 发送邮件
    ---@class NetProtoIsland.RC_sendMail : NetProtoIsland.RC_Base
    ---@field public toPidx  收件人idx
    ---@field public title  标题
    ---@field public content  内容
    ---@field public type  邮件类型
    sendMail = function(map)
        local ret = {}
        ret.cmd = "sendMail"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.toPidx = map[178] -- 收件人idx
        ret.title = map[176] -- 标题
        ret.content = map[180] -- 内容
        ret.type = map[30] -- 邮件类型
        return ret
    end,
    -- 推送战斗单元投放
    ---@class NetProtoIsland.RC_sendBattleDeployUnit : NetProtoIsland.RC_Base
    sendBattleDeployUnit = function(map)
        local ret = {}
        ret.cmd = "sendBattleDeployUnit"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        return ret
    end,
    -- 收集资源
    ---@class NetProtoIsland.RC_collectRes : NetProtoIsland.RC_Base
    ---@field public idx  资源建筑的idx int
    collectRes = function(map)
        local ret = {}
        ret.cmd = "collectRes"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.idx = map[16] -- 资源建筑的idx int
        return ret
    end,
    -- 移除地块
    ---@class NetProtoIsland.RC_rmTile : NetProtoIsland.RC_Base
    ---@field public idx  地块idx int
    rmTile = function(map)
        local ret = {}
        ret.cmd = "rmTile"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.idx = map[16] -- 地块idx int
        return ret
    end,
    -- 当地块发生变化时推送
    ---@class NetProtoIsland.RC_onMapCellChg : NetProtoIsland.RC_Base
    onMapCellChg = function(map)
        local ret = {}
        ret.cmd = "onMapCellChg"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        return ret
    end,
    -- 移动建筑
    ---@class NetProtoIsland.RC_moveBuilding : NetProtoIsland.RC_Base
    ---@field public idx  建筑idx int
    ---@field public pos  位置 int
    moveBuilding = function(map)
        local ret = {}
        ret.cmd = "moveBuilding"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.idx = map[16] -- 建筑idx int
        ret.pos = map[19] -- 位置 int
        return ret
    end,
    -- 当战斗单元死亡
    ---@class NetProtoIsland.RC_onBattleUnitDie : NetProtoIsland.RC_Base
    ---@field public battleFidx  舰队idx
    ---@field public unitInfor NetProtoIsland.ST_unitInfor 战斗单元信息
    onBattleUnitDie = function(map)
        local ret = {}
        ret.cmd = "onBattleUnitDie"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.battleFidx = map[149] -- 舰队idx
        ret.unitInfor = NetProtoIsland.ST_unitInfor.parse(map[151]) -- 战斗单元信息
        return ret
    end,
    -- 立即升级建筑
    ---@class NetProtoIsland.RC_upLevBuildingImm : NetProtoIsland.RC_Base
    ---@field public idx  建筑idx int
    upLevBuildingImm = function(map)
        local ret = {}
        ret.cmd = "upLevBuildingImm"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.idx = map[16] -- 建筑idx int
        return ret
    end,
    -- 舰队攻击舰队
    ---@class NetProtoIsland.RC_fleetAttackFleet : NetProtoIsland.RC_Base
    ---@field public fidx  攻击方舰队idx
    ---@field public targetPos  攻击目标的世界地图坐标idx int
    fleetAttackFleet = function(map)
        local ret = {}
        ret.cmd = "fleetAttackFleet"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.fidx = map[101] -- 攻击方舰队idx
        ret.targetPos = map[121] -- 攻击目标的世界地图坐标idx int
        return ret
    end,
    -- 移动地块
    ---@class NetProtoIsland.RC_moveTile : NetProtoIsland.RC_Base
    ---@field public idx  地块idx int
    ---@field public pos  位置 int
    moveTile = function(map)
        local ret = {}
        ret.cmd = "moveTile"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.idx = map[16] -- 地块idx int
        ret.pos = map[19] -- 位置 int
        return ret
    end,
    -- 取得道具信息
    ---@class NetProtoIsland.RC_getItem : NetProtoIsland.RC_Base
    ---@field public idx  道具唯一标志
    getItem = function(map)
        local ret = {}
        ret.cmd = "getItem"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.idx = map[16] -- 道具唯一标志
        return ret
    end,
    -- 战场投放战斗单元
    ---@class NetProtoIsland.RC_onBattleDeployUnit : NetProtoIsland.RC_Base
    ---@field public battleFidx  舰队idx
    ---@field public unitInfor NetProtoIsland.ST_unitInfor 战斗单元信息
    ---@field public frames  投放时的帧数（相较于第一次投入时的帧数增量）
    ---@field public vector3 NetProtoIsland.ST_vector3 投放坐标（是int，真实值x1000）
    ---@field public fakeRandom  随机因子
    ---@field public fakeRandom2  随机因子2
    ---@field public fakeRandom3  随机因子3
    ---@field public isOffense  是进攻方
    onBattleDeployUnit = function(map)
        local ret = {}
        ret.cmd = "onBattleDeployUnit"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.battleFidx = map[149] -- 舰队idx
        ret.unitInfor = NetProtoIsland.ST_unitInfor.parse(map[151]) -- 战斗单元信息
        ret.frames = map[156] -- 投放时的帧数（相较于第一次投入时的帧数增量）
        ret.vector3 = NetProtoIsland.ST_vector3.parse(map[157]) -- 投放坐标（是int，真实值x1000）
        ret.fakeRandom = map[161] -- 随机因子
        ret.fakeRandom2 = map[162] -- 随机因子2
        ret.fakeRandom3 = map[163] -- 随机因子3
        ret.isOffense = map[154] -- 是进攻方
        return ret
    end,
    -- 升级建筑
    ---@class NetProtoIsland.RC_upLevBuilding : NetProtoIsland.RC_Base
    ---@field public idx  建筑idx int
    upLevBuilding = function(map)
        local ret = {}
        ret.cmd = "upLevBuilding"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.idx = map[16] -- 建筑idx int
        return ret
    end,
    -- 移除建筑
    ---@class NetProtoIsland.RC_rmBuilding : NetProtoIsland.RC_Base
    ---@field public idx  地块idx int
    rmBuilding = function(map)
        local ret = {}
        ret.cmd = "rmBuilding"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.idx = map[16] -- 地块idx int
        return ret
    end,
    -- 新建、更新舰队
    ---@class NetProtoIsland.RC_saveFleet : NetProtoIsland.RC_Base
    ---@field public cidx  城市
    ---@field public idx  舰队idx（新建时可为空）
    ---@field public name  舰队名（最长7个字）
    ---@field public unitInfors NetProtoIsland.ST_unitInfor Array List 战斗单元列表
    saveFleet = function(map)
        local ret = {}
        ret.cmd = "saveFleet"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.cidx = map[18] -- 城市
        ret.idx = map[16] -- 舰队idx（新建时可为空）
        ret.name = map[35] -- 舰队名（最长7个字）
        ret.unitInfors = NetProtoIsland._parseList(NetProtoIsland.ST_unitInfor, map[106]) -- 战斗单元列表
        return ret
    end,
    -- 登陆
    ---@class NetProtoIsland.RC_login : NetProtoIsland.RC_Base
    ---@field public uidx  用户id
    ---@field public channel  渠道号
    ---@field public language  语言
    ---@field public deviceID  机器码
    ---@field public isEditMode  编辑模式
    login = function(map)
        local ret = {}
        ret.cmd = "login"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.uidx = map[49] -- 用户id
        ret.channel = map[50] -- 渠道号
        ret.language = map[188] -- 语言
        ret.deviceID = map[51] -- 机器码
        ret.isEditMode = map[52] -- 编辑模式
        return ret
    end,
    -- 取得道具列表
    ---@class NetProtoIsland.RC_getItemList : NetProtoIsland.RC_Base
    getItemList = function(map)
        local ret = {}
        ret.cmd = "getItemList"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        return ret
    end,
    -- 推送邮件
    ---@class NetProtoIsland.RC_onMailChg : NetProtoIsland.RC_Base
    onMailChg = function(map)
        local ret = {}
        ret.cmd = "onMailChg"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        return ret
    end,
    -- 网络协议配置
    ---@class NetProtoIsland.RC_sendNetCfg : NetProtoIsland.RC_Base
    sendNetCfg = function(map)
        local ret = {}
        ret.cmd = "sendNetCfg"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        return ret
    end,
    -- 设置用户当前正在查看大地图的哪一页，便于后续推送数据
    ---@class NetProtoIsland.RC_setPlayerCurrLook4WorldPage : NetProtoIsland.RC_Base
    ---@field public pageIdx  一屏所在的网格index
    setPlayerCurrLook4WorldPage = function(map)
        local ret = {}
        ret.cmd = "setPlayerCurrLook4WorldPage"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.pageIdx = map[13] -- 一屏所在的网格index
        return ret
    end,
    -- 取得科技列表
    ---@class NetProtoIsland.RC_getTechs : NetProtoIsland.RC_Base
    getTechs = function(map)
        local ret = {}
        ret.cmd = "getTechs"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        return ret
    end,
    -- 资源变化时推送
    ---@class NetProtoIsland.RC_onResChg : NetProtoIsland.RC_Base
    onResChg = function(map)
        local ret = {}
        ret.cmd = "onResChg"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        return ret
    end,
    -- 搬迁
    ---@class NetProtoIsland.RC_moveCity : NetProtoIsland.RC_Base
    ---@field public cidx  城市idx
    ---@field public pos  新位置 int
    moveCity = function(map)
        local ret = {}
        ret.cmd = "moveCity"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.cidx = map[18] -- 城市idx
        ret.pos = map[19] -- 新位置 int
        return ret
    end,
    -- 发送聊天
    ---@class NetProtoIsland.RC_sendChat : NetProtoIsland.RC_Base
    ---@field public content  内容
    ---@field public type  类型
    ---@field public toPidx  目标玩家
    sendChat = function(map)
        local ret = {}
        ret.cmd = "sendChat"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.content = map[180] -- 内容
        ret.type = map[30] -- 类型
        ret.toPidx = map[178] -- 目标玩家
        return ret
    end,
    -- 新建地块
    ---@class NetProtoIsland.RC_newTile : NetProtoIsland.RC_Base
    ---@field public pos  位置 int
    newTile = function(map)
        local ret = {}
        ret.cmd = "newTile"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.pos = map[19] -- 位置 int
        return ret
    end,
    -- 取得一屏的在地图数据
    ---@class NetProtoIsland.RC_getMapDataByPageIdx : NetProtoIsland.RC_Base
    ---@field public pageIdx  一屏所在的网格index
    getMapDataByPageIdx = function(map)
        local ret = {}
        ret.cmd = "getMapDataByPageIdx"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.pageIdx = map[13] -- 一屏所在的网格index
        return ret
    end,
    -- 玩家信息变化时推送
    ---@class NetProtoIsland.RC_onPlayerChg : NetProtoIsland.RC_Base
    onPlayerChg = function(map)
        local ret = {}
        ret.cmd = "onPlayerChg"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        return ret
    end,
    -- 删除邮件
    ---@class NetProtoIsland.RC_deleteMail : NetProtoIsland.RC_Base
    ---@field public idx  邮件idx
    ---@field public deleteAll  删除所有 bool
    deleteMail = function(map)
        local ret = {}
        ret.cmd = "deleteMail"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.idx = map[16] -- 邮件idx
        ret.deleteAll = map[195] -- 删除所有 bool
        return ret
    end,
    -- 领取邮件的奖励
    ---@class NetProtoIsland.RC_receiveRewardMail : NetProtoIsland.RC_Base
    ---@field public idx  邮件idx
    receiveRewardMail = function(map)
        local ret = {}
        ret.cmd = "receiveRewardMail"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.idx = map[16] -- 邮件idx
        return ret
    end,
    -- 回复邮件
    ---@class NetProtoIsland.RC_replyMail : NetProtoIsland.RC_Base
    ---@field public idx  邮件idx
    ---@field public content  内容
    replyMail = function(map)
        local ret = {}
        ret.cmd = "replyMail"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.idx = map[16] -- 邮件idx
        ret.content = map[180] -- 内容
        return ret
    end,
    -- 舰队攻击岛屿
    ---@class NetProtoIsland.RC_fleetAttackIsland : NetProtoIsland.RC_Base
    ---@field public fidx  攻击方舰队idx
    ---@field public targetPos  攻击目标的世界地图坐标idx int
    fleetAttackIsland = function(map)
        local ret = {}
        ret.cmd = "fleetAttackIsland"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.fidx = map[101] -- 攻击方舰队idx
        ret.targetPos = map[121] -- 攻击目标的世界地图坐标idx int
        return ret
    end,
    -- 结束攻击岛
    ---@class NetProtoIsland.RC_sendEndAttackIsland : NetProtoIsland.RC_Base
    sendEndAttackIsland = function(map)
        local ret = {}
        ret.cmd = "sendEndAttackIsland"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        return ret
    end,
    -- 新建建筑
    ---@class NetProtoIsland.RC_newBuilding : NetProtoIsland.RC_Base
    ---@field public attrid  建筑配置id int
    ---@field public pos  位置 int
    newBuilding = function(map)
        local ret = {}
        ret.cmd = "newBuilding"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.attrid = map[17] -- 建筑配置id int
        ret.pos = map[19] -- 位置 int
        return ret
    end,
    -- 取得邮件列表
    ---@class NetProtoIsland.RC_getMails : NetProtoIsland.RC_Base
    getMails = function(map)
        local ret = {}
        ret.cmd = "getMails"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        return ret
    end,
    -- 取得舰队信息
    ---@class NetProtoIsland.RC_getFleet : NetProtoIsland.RC_Base
    ---@field public idx  舰队idx
    getFleet = function(map)
        local ret = {}
        ret.cmd = "getFleet"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.idx = map[16] -- 舰队idx
        return ret
    end,
    -- 取得建筑
    ---@class NetProtoIsland.RC_getBuilding : NetProtoIsland.RC_Base
    ---@field public idx  建筑idx int
    getBuilding = function(map)
        local ret = {}
        ret.cmd = "getBuilding"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.idx = map[16] -- 建筑idx int
        return ret
    end,
    -- 舰队返航
    ---@class NetProtoIsland.RC_fleetBack : NetProtoIsland.RC_Base
    ---@field public idx  舰队idx
    fleetBack = function(map)
        local ret = {}
        ret.cmd = "fleetBack"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.idx = map[16] -- 舰队idx
        return ret
    end,
    -- 登出
    ---@class NetProtoIsland.RC_logout : NetProtoIsland.RC_Base
    logout = function(map)
        local ret = {}
        ret.cmd = "logout"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        return ret
    end,
    -- 取得所有舰队信息
    ---@class NetProtoIsland.RC_getAllFleets : NetProtoIsland.RC_Base
    ---@field public cidx  城市的idx
    getAllFleets = function(map)
        local ret = {}
        ret.cmd = "getAllFleets"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.cidx = map[18] -- 城市的idx
        return ret
    end,
    -- 读邮件
    ---@class NetProtoIsland.RC_readMail : NetProtoIsland.RC_Base
    ---@field public idx  邮件idx
    readMail = function(map)
        local ret = {}
        ret.cmd = "readMail"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.idx = map[16] -- 邮件idx
        return ret
    end,
    -- 建筑升级完成
    ---@class NetProtoIsland.RC_onFinishBuildingUpgrade : NetProtoIsland.RC_Base
    onFinishBuildingUpgrade = function(map)
        local ret = {}
        ret.cmd = "onFinishBuildingUpgrade"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        return ret
    end,
    -- 心跳
    ---@class NetProtoIsland.RC_heart : NetProtoIsland.RC_Base
    heart = function(map)
        local ret = {}
        ret.cmd = "heart"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        return ret
    end,
    -- 主动离开攻击岛
    ---@class NetProtoIsland.RC_quitIslandBattle : NetProtoIsland.RC_Base
    ---@field public fidx  攻击方舰队idx
    quitIslandBattle = function(map)
        local ret = {}
        ret.cmd = "quitIslandBattle"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.fidx = map[101] -- 攻击方舰队idx
        return ret
    end,
    -- 开始攻击岛
    ---@class NetProtoIsland.RC_sendStartAttackIsland : NetProtoIsland.RC_Base
    sendStartAttackIsland = function(map)
        local ret = {}
        ret.cmd = "sendStartAttackIsland"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        return ret
    end,
    -- 推送舰队信息
    ---@class NetProtoIsland.RC_sendFleet : NetProtoIsland.RC_Base
    sendFleet = function(map)
        local ret = {}
        ret.cmd = "sendFleet"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        return ret
    end,
    -- 领取奖励包的物品
    ---@class NetProtoIsland.RC_receiveReward : NetProtoIsland.RC_Base
    ---@field public rwidx  奖励包idx
    receiveReward = function(map)
        local ret = {}
        ret.cmd = "receiveReward"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.rwidx = map[206] -- 奖励包idx
        return ret
    end,
    -- 取得奖励包信息
    ---@class NetProtoIsland.RC_getRewardInfor : NetProtoIsland.RC_Base
    ---@field public rwidx  奖励包idx
    getRewardInfor = function(map)
        local ret = {}
        ret.cmd = "getRewardInfor"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.rwidx = map[206] -- 奖励包idx
        return ret
    end,
    -- 立即升级科技
    ---@class NetProtoIsland.RC_upLevTechImm : NetProtoIsland.RC_Base
    ---@field public id  科技的配置id
    upLevTechImm = function(map)
        local ret = {}
        ret.cmd = "upLevTechImm"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.id = map[99] -- 科技的配置id
        return ret
    end,
    -- 升级科技
    ---@class NetProtoIsland.RC_upLevTech : NetProtoIsland.RC_Base
    ---@field public id  科技的配置id
    upLevTech = function(map)
        local ret = {}
        ret.cmd = "upLevTech"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.id = map[99] -- 科技的配置id
        return ret
    end,
    -- 准备攻击岛
    ---@class NetProtoIsland.RC_sendPrepareAttackIsland : NetProtoIsland.RC_Base
    sendPrepareAttackIsland = function(map)
        local ret = {}
        ret.cmd = "sendPrepareAttackIsland"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        return ret
    end,
    -- 取得玩家简要信息
    ---@class NetProtoIsland.RC_getPlayerSimple : NetProtoIsland.RC_Base
    ---@field public pidx  玩家的idx
    getPlayerSimple = function(map)
        local ret = {}
        ret.cmd = "getPlayerSimple"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.pidx = map[38] -- 玩家的idx
        return ret
    end,
    -- 当聊天有变化时的推送
    ---@class NetProtoIsland.RC_onChatChg : NetProtoIsland.RC_Base
    onChatChg = function(map)
        local ret = {}
        ret.cmd = "onChatChg"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        return ret
    end,
    -- 自己的城变化时推送
    ---@class NetProtoIsland.RC_onMyselfCityChg : NetProtoIsland.RC_Base
    onMyselfCityChg = function(map)
        local ret = {}
        ret.cmd = "onMyselfCityChg"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        return ret
    end,
    -- 召唤魔法技能
    ---@class NetProtoIsland.RC_summonMagic : NetProtoIsland.RC_Base
    ---@field public id  魔法的配置id
    summonMagic = function(map)
        local ret = {}
        ret.cmd = "summonMagic"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.id = map[99] -- 魔法的配置id
        return ret
    end,
    -- 科技变化
    ---@class NetProtoIsland.RC_onTechChg : NetProtoIsland.RC_Base
    onTechChg = function(map)
        local ret = {}
        ret.cmd = "onTechChg"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        return ret
    end,
    -- 取是玩家的聊天信息
    ---@class NetProtoIsland.RC_getChats : NetProtoIsland.RC_Base
    getChats = function(map)
        local ret = {}
        ret.cmd = "getChats"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        return ret
    end,
    -- 道具变化通知
    ---@class NetProtoIsland.RC_useItem : NetProtoIsland.RC_Base
    ---@field public idx  道具idx
    ---@field public num  数量
    useItem = function(map)
        local ret = {}
        ret.cmd = "useItem"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.idx = map[16] -- 道具idx
        ret.num = map[67] -- 数量
        return ret
    end,
    -- 召唤魔法技能加速
    ---@class NetProtoIsland.RC_summonMagicSpeedUp : NetProtoIsland.RC_Base
    ---@field public id  魔法的配置id
    summonMagicSpeedUp = function(map)
        local ret = {}
        ret.cmd = "summonMagicSpeedUp"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.id = map[99] -- 魔法的配置id
        return ret
    end,
    -- 建筑变化时推送
    ---@class NetProtoIsland.RC_onBuildingChg : NetProtoIsland.RC_Base
    onBuildingChg = function(map)
        local ret = {}
        ret.cmd = "onBuildingChg"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        return ret
    end,
    -- 取得战报的结果
    ---@class NetProtoIsland.RC_getReportResult : NetProtoIsland.RC_Base
    ---@field public idx  战报idx
    getReportResult = function(map)
        local ret = {}
        ret.cmd = "getReportResult"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.idx = map[16] -- 战报idx
        return ret
    end,
    -- 当建筑死亡
    ---@class NetProtoIsland.RC_onBattleBuildingDie : NetProtoIsland.RC_Base
    ---@field public battleFidx  舰队idx
    ---@field public bidx  建筑idx
    onBattleBuildingDie = function(map)
        local ret = {}
        ret.cmd = "onBattleBuildingDie"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.battleFidx = map[149] -- 舰队idx
        ret.bidx = map[100] -- 建筑idx
        return ret
    end,
    -- 当完成建造部分舰艇的通知
    ---@class NetProtoIsland.RC_onFinishBuildOneShip : NetProtoIsland.RC_Base
    ---@field public buildingIdx  造船厂的idx int
    onFinishBuildOneShip = function(map)
        local ret = {}
        ret.cmd = "onFinishBuildOneShip"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.buildingIdx = map[15] -- 造船厂的idx int
        return ret
    end,
    -- 取得保存到建筑上的战斗单元
    ---@class NetProtoIsland.RC_getUnitsInBuilding : NetProtoIsland.RC_Base
    ---@field public buildingIdx  造船厂的idx int
    getUnitsInBuilding = function(map)
        local ret = {}
        ret.cmd = "getUnitsInBuilding"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.buildingIdx = map[15] -- 造船厂的idx int
        return ret
    end,
    -- 造船
    ---@class NetProtoIsland.RC_buildShip : NetProtoIsland.RC_Base
    ---@field public buildingIdx  造船厂的idx int
    ---@field public shipAttrID  舰船配置id int
    ---@field public num  数量 int
    buildShip = function(map)
        local ret = {}
        ret.cmd = "buildShip"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.buildingIdx = map[15] -- 造船厂的idx int
        ret.shipAttrID = map[58] -- 舰船配置id int
        ret.num = map[67] -- 数量 int
        return ret
    end,
    -- 取得战报详细信息(攻击岛屿)
    ---@class NetProtoIsland.RC_getReportDetail : NetProtoIsland.RC_Base
    ---@field public idx  战报idx
    getReportDetail = function(map)
        local ret = {}
        ret.cmd = "getReportDetail"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.idx = map[16] -- 战报idx
        return ret
    end,
    }
    --==============================
    NetProtoIsland.send = {
    onItemChg = function(mapOrig, retInfor, item) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 211
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[212] = NetProtoIsland.ST_item.toMap(item) -- 道具信息
        return ret
    end,
    onBattleLootRes = function(mapOrig, retInfor) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 148
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        return ret
    end,
    fleetDepart = function(mapOrig, retInfor, fleetinfor) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 108
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[107] = NetProtoIsland.ST_fleetinfor.toMap(fleetinfor) -- 舰队信息
        return ret
    end,
    sendMail = function(mapOrig, retInfor, mail) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 186
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[191] = NetProtoIsland.ST_mail.toMap(mail) -- 邮件
        return ret
    end,
    sendBattleDeployUnit = function(mapOrig, retInfor, deployUnitInfor) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 164
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[165] = NetProtoIsland.ST_deployUnitInfor.toMap(deployUnitInfor) -- 战斗单元投放信息
        return ret
    end,
    collectRes = function(mapOrig, retInfor, resType, resVal, building) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 77
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        if type(resType) == "number" then
            ret[78] = BioUtl.number2bio(resType) -- 收集的资源类型 int
        else
            ret[78] = resType -- 收集的资源类型 int
        end
        if type(resVal) == "number" then
            ret[79] = BioUtl.number2bio(resVal) -- 收集到的资源量 int
        else
            ret[79] = resVal -- 收集到的资源量 int
        end
        ret[45] = NetProtoIsland.ST_building.toMap(building) -- 建筑信息
        return ret
    end,
    rmTile = function(mapOrig, retInfor, idx) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 61
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        if type(idx) == "number" then
            ret[16] = BioUtl.number2bio(idx) -- 被移除地块的idx int
        else
            ret[16] = idx -- 被移除地块的idx int
        end
        return ret
    end,
    onMapCellChg = function(mapOrig, retInfor, mapCell, isRemove) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 86
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[87] = NetProtoIsland.ST_mapCell.toMap(mapCell) -- 地块
        if type(isRemove) == "number" then
            ret[98] = BioUtl.number2bio(isRemove) -- 是否是删除
        else
            ret[98] = isRemove -- 是否是删除
        end
        return ret
    end,
    moveBuilding = function(mapOrig, retInfor, building) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 64
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[45] = NetProtoIsland.ST_building.toMap(building) -- 建筑信息
        return ret
    end,
    onBattleUnitDie = function(mapOrig, retInfor) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 150
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        return ret
    end,
    upLevBuildingImm = function(mapOrig, retInfor, building) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 68
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[45] = NetProtoIsland.ST_building.toMap(building) -- 建筑信息
        return ret
    end,
    fleetAttackFleet = function(mapOrig, retInfor) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 130
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        return ret
    end,
    moveTile = function(mapOrig, retInfor, tile) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 76
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[70] = NetProtoIsland.ST_tile.toMap(tile) -- 地块信息
        return ret
    end,
    getItem = function(mapOrig, retInfor, item) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 214
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[212] = NetProtoIsland.ST_item.toMap(item) -- 道具信息
        return ret
    end,
    onBattleDeployUnit = function(mapOrig, retInfor) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 155
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        return ret
    end,
    upLevBuilding = function(mapOrig, retInfor, building) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 44
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[45] = NetProtoIsland.ST_building.toMap(building) -- 建筑信息
        return ret
    end,
    rmBuilding = function(mapOrig, retInfor, idx) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 46
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        if type(idx) == "number" then
            ret[16] = BioUtl.number2bio(idx) -- 被移除建筑的idx int
        else
            ret[16] = idx -- 被移除建筑的idx int
        end
        return ret
    end,
    saveFleet = function(mapOrig, retInfor, fleetinfor) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 105
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[107] = NetProtoIsland.ST_fleetinfor.toMap(fleetinfor) -- 舰队信息
        return ret
    end,
    login = function(mapOrig, retInfor, player, city, systime, session) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 48
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[53] = NetProtoIsland.ST_player.toMap(player) -- 玩家信息
        ret[54] = NetProtoIsland.ST_city.toMap(city) -- 主城信息
        if type(systime) == "number" then
            ret[55] = BioUtl.number2bio(systime) -- 系统时间 long
        else
            ret[55] = systime -- 系统时间 long
        end
        if type(session) == "number" then
            ret[56] = BioUtl.number2bio(session) -- 会话id
        else
            ret[56] = session -- 会话id
        end
        return ret
    end,
    getItemList = function(mapOrig, retInfor, items) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 215
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[216] = NetProtoIsland._toList(NetProtoIsland.ST_item, items)  -- 道具列表
        return ret
    end,
    onMailChg = function(mapOrig, retInfor, mails) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 193
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[187] = NetProtoIsland._toList(NetProtoIsland.ST_mail, mails)  -- 邮件列表
        return ret
    end,
    sendNetCfg = function(mapOrig, retInfor, netCfg, systime) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 81
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[82] = NetProtoIsland.ST_netCfg.toMap(netCfg) -- 网络协议解析配置
        if type(systime) == "number" then
            ret[55] = BioUtl.number2bio(systime) -- 系统时间 long
        else
            ret[55] = systime -- 系统时间 long
        end
        return ret
    end,
    setPlayerCurrLook4WorldPage = function(mapOrig, retInfor) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 116
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        return ret
    end,
    getTechs = function(mapOrig, retInfor, techInfors) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 253
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[254] = NetProtoIsland._toList(NetProtoIsland.ST_techInfor, techInfors)  -- 科技列表
        return ret
    end,
    onResChg = function(mapOrig, retInfor, resInfor) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 62
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[63] = NetProtoIsland.ST_resInfor.toMap(resInfor) -- 资源信息
        return ret
    end,
    moveCity = function(mapOrig, retInfor) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 88
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        return ret
    end,
    sendChat = function(mapOrig, retInfor) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 221
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        return ret
    end,
    newTile = function(mapOrig, retInfor, tile) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 69
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[70] = NetProtoIsland.ST_tile.toMap(tile) -- 地块信息对象
        return ret
    end,
    getMapDataByPageIdx = function(mapOrig, retInfor, mapPage, fleetinfors) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 74
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[75] = NetProtoIsland.ST_mapPage.toMap(mapPage) -- 在地图一屏数据 map
        ret[112] = NetProtoIsland._toList(NetProtoIsland.ST_fleetinfor, fleetinfors)  -- 舰队列表
        return ret
    end,
    onPlayerChg = function(mapOrig, retInfor, player) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 72
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[53] = NetProtoIsland.ST_player.toMap(player) -- 玩家信息
        return ret
    end,
    deleteMail = function(mapOrig, retInfor) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 194
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        return ret
    end,
    receiveRewardMail = function(mapOrig, retInfor, mail) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 196
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[191] = NetProtoIsland.ST_mail.toMap(mail) -- 邮件
        return ret
    end,
    replyMail = function(mapOrig, retInfor, mail) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 190
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[191] = NetProtoIsland.ST_mail.toMap(mail) -- 邮件
        return ret
    end,
    fleetAttackIsland = function(mapOrig, retInfor, fleetinfor) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 129
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[107] = NetProtoIsland.ST_fleetinfor.toMap(fleetinfor) -- 进攻方舰队数据
        return ret
    end,
    sendEndAttackIsland = function(mapOrig, retInfor, battleresult) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 137
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[138] = NetProtoIsland.ST_battleresult.toMap(battleresult) -- 战斗结果
        return ret
    end,
    newBuilding = function(mapOrig, retInfor, building) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 47
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[45] = NetProtoIsland.ST_building.toMap(building) -- 建筑信息对象
        return ret
    end,
    getMails = function(mapOrig, retInfor, mails) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 189
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[187] = NetProtoIsland._toList(NetProtoIsland.ST_mail, mails)  -- 邮件列表
        return ret
    end,
    getFleet = function(mapOrig, retInfor, fleetinfor) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 110
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[107] = NetProtoIsland.ST_fleetinfor.toMap(fleetinfor) -- 舰队信息
        return ret
    end,
    getBuilding = function(mapOrig, retInfor, building) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 60
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[45] = NetProtoIsland.ST_building.toMap(building) -- 建筑信息对象
        return ret
    end,
    fleetBack = function(mapOrig, retInfor, fleetinfor) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 126
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[107] = NetProtoIsland.ST_fleetinfor.toMap(fleetinfor) -- 舰队信息
        return ret
    end,
    logout = function(mapOrig, retInfor) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 65
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        return ret
    end,
    getAllFleets = function(mapOrig, retInfor, fleetinfors) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 111
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[112] = NetProtoIsland._toList(NetProtoIsland.ST_fleetinfor, fleetinfors)  -- 舰队列表
        return ret
    end,
    readMail = function(mapOrig, retInfor, mail) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 192
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[191] = NetProtoIsland.ST_mail.toMap(mail) -- 邮件
        return ret
    end,
    onFinishBuildingUpgrade = function(mapOrig, retInfor, building) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 80
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[45] = NetProtoIsland.ST_building.toMap(building) -- 建筑信息
        return ret
    end,
    heart = function(mapOrig) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 73
        ret[3] = mapOrig and mapOrig.callback or nil
        return ret
    end,
    quitIslandBattle = function(mapOrig, retInfor) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 143
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        return ret
    end,
    sendStartAttackIsland = function(mapOrig, retInfor, player, city, unitsInBuildings, player2, fleetinfor, endTimeLimit) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 139
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[53] = NetProtoIsland.ST_player.toMap(player) -- 被攻击方玩家信息
        ret[54] = NetProtoIsland.ST_city.toMap(city) -- 被攻击方主城信息
        ret[258] = NetProtoIsland._toList(NetProtoIsland.ST_unitsInBuilding, unitsInBuildings)  -- 被攻击方舰船数据
        ret[141] = NetProtoIsland.ST_player.toMap(player2) -- 攻击方玩家信息
        ret[107] = NetProtoIsland.ST_fleetinfor.toMap(fleetinfor) -- 进攻方舰队数据
        if type(endTimeLimit) == "number" then
            ret[145] = BioUtl.number2bio(endTimeLimit) -- 战斗限制时间
        else
            ret[145] = endTimeLimit -- 战斗限制时间
        end
        return ret
    end,
    sendFleet = function(mapOrig, retInfor, fleetinfor, isRemove) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 117
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[107] = NetProtoIsland.ST_fleetinfor.toMap(fleetinfor) -- 舰队信息
        if type(isRemove) == "number" then
            ret[98] = BioUtl.number2bio(isRemove) -- 是否移除
        else
            ret[98] = isRemove -- 是否移除
        end
        return ret
    end,
    receiveReward = function(mapOrig, retInfor, rewardInfors) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 207
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[208] = NetProtoIsland._toList(NetProtoIsland.ST_rewardInfor, rewardInfors)  -- 奖励包信息
        return ret
    end,
    getRewardInfor = function(mapOrig, retInfor, rewardInfors) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 209
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[208] = NetProtoIsland._toList(NetProtoIsland.ST_rewardInfor, rewardInfors)  -- 奖励包信息
        return ret
    end,
    upLevTechImm = function(mapOrig, retInfor, techInfor) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 255
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[251] = NetProtoIsland.ST_techInfor.toMap(techInfor) -- 科技信息
        return ret
    end,
    upLevTech = function(mapOrig, retInfor, techInfor) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 250
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[251] = NetProtoIsland.ST_techInfor.toMap(techInfor) -- 科技信息
        return ret
    end,
    sendPrepareAttackIsland = function(mapOrig, retInfor, player, city, player2, city2, fleetinfor) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 140
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[53] = NetProtoIsland.ST_player.toMap(player) -- 被攻击方玩家信息
        ret[54] = NetProtoIsland.ST_city.toMap(city) -- 被攻击方主城信息
        ret[141] = NetProtoIsland.ST_player.toMap(player2) -- 攻击方玩家信息
        ret[142] = NetProtoIsland.ST_city.toMap(city2) -- 攻击方主城信息
        ret[107] = NetProtoIsland.ST_fleetinfor.toMap(fleetinfor) -- 进攻方舰队数据
        return ret
    end,
    getPlayerSimple = function(mapOrig, retInfor, playerSimple) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 227
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[226] = NetProtoIsland.ST_playerSimple.toMap(playerSimple) -- 玩家简要信息
        return ret
    end,
    onChatChg = function(mapOrig, retInfor, chatInfors) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 219
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[220] = NetProtoIsland._toList(NetProtoIsland.ST_chatInfor, chatInfors)  -- 聊天信息列表
        return ret
    end,
    onMyselfCityChg = function(mapOrig, retInfor, city) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 89
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[54] = NetProtoIsland.ST_city.toMap(city) -- 主城信息
        return ret
    end,
    summonMagic = function(mapOrig, retInfor) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 257
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        return ret
    end,
    onTechChg = function(mapOrig, retInfor, techInfor) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 252
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[251] = NetProtoIsland.ST_techInfor.toMap(techInfor) -- 科技信息
        return ret
    end,
    getChats = function(mapOrig, retInfor, chatInfors, chatInfors2, chatInfors3) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 222
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[220] = NetProtoIsland._toList(NetProtoIsland.ST_chatInfor, chatInfors)  -- 公聊信息列表
        ret[223] = NetProtoIsland._toList(NetProtoIsland.ST_chatInfor, chatInfors2)  -- 私聊信息列表
        ret[224] = NetProtoIsland._toList(NetProtoIsland.ST_chatInfor, chatInfors3)  -- 联盟聊天信息列表
        return ret
    end,
    useItem = function(mapOrig, retInfor, item) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 213
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[212] = NetProtoIsland.ST_item.toMap(item) -- 道具信息
        return ret
    end,
    summonMagicSpeedUp = function(mapOrig, retInfor) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 260
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        return ret
    end,
    onBuildingChg = function(mapOrig, retInfor, building) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 71
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[45] = NetProtoIsland.ST_building.toMap(building) -- 建筑信息
        return ret
    end,
    getReportResult = function(mapOrig, retInfor, battleresult) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 199
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[138] = NetProtoIsland.ST_battleresult.toMap(battleresult) -- 战斗结果
        return ret
    end,
    onBattleBuildingDie = function(mapOrig, retInfor) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 152
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        return ret
    end,
    onFinishBuildOneShip = function(mapOrig, retInfor, buildingIdx, shipAttrID, shipNum) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 57
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        if type(buildingIdx) == "number" then
            ret[15] = BioUtl.number2bio(buildingIdx) -- 造船厂的idx int
        else
            ret[15] = buildingIdx -- 造船厂的idx int
        end
        if type(shipAttrID) == "number" then
            ret[58] = BioUtl.number2bio(shipAttrID) -- 舰船的配置id
        else
            ret[58] = shipAttrID -- 舰船的配置id
        end
        if type(shipNum) == "number" then
            ret[59] = BioUtl.number2bio(shipNum) -- 舰船的数量
        else
            ret[59] = shipNum -- 舰船的数量
        end
        return ret
    end,
    getUnitsInBuilding = function(mapOrig, retInfor, unitsInBuilding) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 42
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[259] = NetProtoIsland.ST_unitsInBuilding.toMap(unitsInBuilding) -- 造船厂的idx int
        return ret
    end,
    buildShip = function(mapOrig, retInfor, building) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 66
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        ret[45] = NetProtoIsland.ST_building.toMap(building) -- 造船厂信息
        return ret
    end,
    getReportDetail = function(mapOrig, retInfor, idx, battleType, battleDetail, battleFleetDetail, battleresult) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 200
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor) -- 返回信息
        if type(idx) == "number" then
            ret[16] = BioUtl.number2bio(idx) -- 战报idx
        else
            ret[16] = idx -- 战报idx
        end
        if type(battleType) == "number" then
            ret[244] = BioUtl.number2bio(battleType) -- 战斗类型
        else
            ret[244] = battleType -- 战斗类型
        end
        ret[243] = NetProtoIsland.ST_battleDetail.toMap(battleDetail) -- 攻岛战斗详细数据（根据类型不同，可能为空）
        ret[238] = NetProtoIsland.ST_battleFleetDetail.toMap(battleFleetDetail) -- 舰队战详细数据（根据类型不同，可能为空）
        ret[138] = NetProtoIsland.ST_battleresult.toMap(battleresult) -- 战斗结果
        return ret
    end,
    }
    --==============================
    NetProtoIsland.dispatch[211]={onReceive = NetProtoIsland.recive.onItemChg, send = NetProtoIsland.send.onItemChg, logicName = "cmd4items"}
    NetProtoIsland.dispatch[148]={onReceive = NetProtoIsland.recive.onBattleLootRes, send = NetProtoIsland.send.onBattleLootRes, logicName = "USWorld"}
    NetProtoIsland.dispatch[108]={onReceive = NetProtoIsland.recive.fleetDepart, send = NetProtoIsland.send.fleetDepart, logicName = "USWorld"}
    NetProtoIsland.dispatch[186]={onReceive = NetProtoIsland.recive.sendMail, send = NetProtoIsland.send.sendMail, logicName = "cmd4mail"}
    NetProtoIsland.dispatch[164]={onReceive = NetProtoIsland.recive.sendBattleDeployUnit, send = NetProtoIsland.send.sendBattleDeployUnit, logicName = "USWorld"}
    NetProtoIsland.dispatch[77]={onReceive = NetProtoIsland.recive.collectRes, send = NetProtoIsland.send.collectRes, logicName = "cmd4city"}
    NetProtoIsland.dispatch[61]={onReceive = NetProtoIsland.recive.rmTile, send = NetProtoIsland.send.rmTile, logicName = "cmd4city"}
    NetProtoIsland.dispatch[86]={onReceive = NetProtoIsland.recive.onMapCellChg, send = NetProtoIsland.send.onMapCellChg, logicName = "USWorld"}
    NetProtoIsland.dispatch[64]={onReceive = NetProtoIsland.recive.moveBuilding, send = NetProtoIsland.send.moveBuilding, logicName = "cmd4city"}
    NetProtoIsland.dispatch[150]={onReceive = NetProtoIsland.recive.onBattleUnitDie, send = NetProtoIsland.send.onBattleUnitDie, logicName = "USWorld"}
    NetProtoIsland.dispatch[68]={onReceive = NetProtoIsland.recive.upLevBuildingImm, send = NetProtoIsland.send.upLevBuildingImm, logicName = "cmd4city"}
    NetProtoIsland.dispatch[130]={onReceive = NetProtoIsland.recive.fleetAttackFleet, send = NetProtoIsland.send.fleetAttackFleet, logicName = "USWorld"}
    NetProtoIsland.dispatch[76]={onReceive = NetProtoIsland.recive.moveTile, send = NetProtoIsland.send.moveTile, logicName = "cmd4city"}
    NetProtoIsland.dispatch[214]={onReceive = NetProtoIsland.recive.getItem, send = NetProtoIsland.send.getItem, logicName = "cmd4items"}
    NetProtoIsland.dispatch[155]={onReceive = NetProtoIsland.recive.onBattleDeployUnit, send = NetProtoIsland.send.onBattleDeployUnit, logicName = "USWorld"}
    NetProtoIsland.dispatch[44]={onReceive = NetProtoIsland.recive.upLevBuilding, send = NetProtoIsland.send.upLevBuilding, logicName = "cmd4city"}
    NetProtoIsland.dispatch[46]={onReceive = NetProtoIsland.recive.rmBuilding, send = NetProtoIsland.send.rmBuilding, logicName = "cmd4city"}
    NetProtoIsland.dispatch[105]={onReceive = NetProtoIsland.recive.saveFleet, send = NetProtoIsland.send.saveFleet, logicName = "USWorld"}
    NetProtoIsland.dispatch[48]={onReceive = NetProtoIsland.recive.login, send = NetProtoIsland.send.login, logicName = "cmd4player"}
    NetProtoIsland.dispatch[215]={onReceive = NetProtoIsland.recive.getItemList, send = NetProtoIsland.send.getItemList, logicName = "cmd4items"}
    NetProtoIsland.dispatch[193]={onReceive = NetProtoIsland.recive.onMailChg, send = NetProtoIsland.send.onMailChg, logicName = "cmd4mail"}
    NetProtoIsland.dispatch[81]={onReceive = NetProtoIsland.recive.sendNetCfg, send = NetProtoIsland.send.sendNetCfg, logicName = ""}
    NetProtoIsland.dispatch[116]={onReceive = NetProtoIsland.recive.setPlayerCurrLook4WorldPage, send = NetProtoIsland.send.setPlayerCurrLook4WorldPage, logicName = "USWorld"}
    NetProtoIsland.dispatch[253]={onReceive = NetProtoIsland.recive.getTechs, send = NetProtoIsland.send.getTechs, logicName = "cmd4city"}
    NetProtoIsland.dispatch[62]={onReceive = NetProtoIsland.recive.onResChg, send = NetProtoIsland.send.onResChg, logicName = "cmd4city"}
    NetProtoIsland.dispatch[88]={onReceive = NetProtoIsland.recive.moveCity, send = NetProtoIsland.send.moveCity, logicName = "USWorld"}
    NetProtoIsland.dispatch[221]={onReceive = NetProtoIsland.recive.sendChat, send = NetProtoIsland.send.sendChat, logicName = "USChat"}
    NetProtoIsland.dispatch[69]={onReceive = NetProtoIsland.recive.newTile, send = NetProtoIsland.send.newTile, logicName = "cmd4city"}
    NetProtoIsland.dispatch[74]={onReceive = NetProtoIsland.recive.getMapDataByPageIdx, send = NetProtoIsland.send.getMapDataByPageIdx, logicName = "USWorld"}
    NetProtoIsland.dispatch[72]={onReceive = NetProtoIsland.recive.onPlayerChg, send = NetProtoIsland.send.onPlayerChg, logicName = "cmd4player"}
    NetProtoIsland.dispatch[194]={onReceive = NetProtoIsland.recive.deleteMail, send = NetProtoIsland.send.deleteMail, logicName = "cmd4mail"}
    NetProtoIsland.dispatch[196]={onReceive = NetProtoIsland.recive.receiveRewardMail, send = NetProtoIsland.send.receiveRewardMail, logicName = "cmd4mail"}
    NetProtoIsland.dispatch[190]={onReceive = NetProtoIsland.recive.replyMail, send = NetProtoIsland.send.replyMail, logicName = "cmd4mail"}
    NetProtoIsland.dispatch[129]={onReceive = NetProtoIsland.recive.fleetAttackIsland, send = NetProtoIsland.send.fleetAttackIsland, logicName = "USWorld"}
    NetProtoIsland.dispatch[137]={onReceive = NetProtoIsland.recive.sendEndAttackIsland, send = NetProtoIsland.send.sendEndAttackIsland, logicName = "USWorld"}
    NetProtoIsland.dispatch[47]={onReceive = NetProtoIsland.recive.newBuilding, send = NetProtoIsland.send.newBuilding, logicName = "cmd4city"}
    NetProtoIsland.dispatch[189]={onReceive = NetProtoIsland.recive.getMails, send = NetProtoIsland.send.getMails, logicName = "cmd4mail"}
    NetProtoIsland.dispatch[110]={onReceive = NetProtoIsland.recive.getFleet, send = NetProtoIsland.send.getFleet, logicName = "USWorld"}
    NetProtoIsland.dispatch[60]={onReceive = NetProtoIsland.recive.getBuilding, send = NetProtoIsland.send.getBuilding, logicName = "cmd4city"}
    NetProtoIsland.dispatch[126]={onReceive = NetProtoIsland.recive.fleetBack, send = NetProtoIsland.send.fleetBack, logicName = "USWorld"}
    NetProtoIsland.dispatch[65]={onReceive = NetProtoIsland.recive.logout, send = NetProtoIsland.send.logout, logicName = "cmd4player"}
    NetProtoIsland.dispatch[111]={onReceive = NetProtoIsland.recive.getAllFleets, send = NetProtoIsland.send.getAllFleets, logicName = "USWorld"}
    NetProtoIsland.dispatch[192]={onReceive = NetProtoIsland.recive.readMail, send = NetProtoIsland.send.readMail, logicName = "cmd4mail"}
    NetProtoIsland.dispatch[80]={onReceive = NetProtoIsland.recive.onFinishBuildingUpgrade, send = NetProtoIsland.send.onFinishBuildingUpgrade, logicName = "cmd4city"}
    NetProtoIsland.dispatch[73]={onReceive = NetProtoIsland.recive.heart, send = NetProtoIsland.send.heart, logicName = "cmd4com"}
    NetProtoIsland.dispatch[143]={onReceive = NetProtoIsland.recive.quitIslandBattle, send = NetProtoIsland.send.quitIslandBattle, logicName = "USWorld"}
    NetProtoIsland.dispatch[139]={onReceive = NetProtoIsland.recive.sendStartAttackIsland, send = NetProtoIsland.send.sendStartAttackIsland, logicName = "USWorld"}
    NetProtoIsland.dispatch[117]={onReceive = NetProtoIsland.recive.sendFleet, send = NetProtoIsland.send.sendFleet, logicName = ""}
    NetProtoIsland.dispatch[207]={onReceive = NetProtoIsland.recive.receiveReward, send = NetProtoIsland.send.receiveReward, logicName = "cmd4rewardpkg"}
    NetProtoIsland.dispatch[209]={onReceive = NetProtoIsland.recive.getRewardInfor, send = NetProtoIsland.send.getRewardInfor, logicName = "cmd4rewardpkg"}
    NetProtoIsland.dispatch[255]={onReceive = NetProtoIsland.recive.upLevTechImm, send = NetProtoIsland.send.upLevTechImm, logicName = "cmd4city"}
    NetProtoIsland.dispatch[250]={onReceive = NetProtoIsland.recive.upLevTech, send = NetProtoIsland.send.upLevTech, logicName = "cmd4city"}
    NetProtoIsland.dispatch[140]={onReceive = NetProtoIsland.recive.sendPrepareAttackIsland, send = NetProtoIsland.send.sendPrepareAttackIsland, logicName = "USWorld"}
    NetProtoIsland.dispatch[227]={onReceive = NetProtoIsland.recive.getPlayerSimple, send = NetProtoIsland.send.getPlayerSimple, logicName = "cmd4player"}
    NetProtoIsland.dispatch[219]={onReceive = NetProtoIsland.recive.onChatChg, send = NetProtoIsland.send.onChatChg, logicName = "USChat"}
    NetProtoIsland.dispatch[89]={onReceive = NetProtoIsland.recive.onMyselfCityChg, send = NetProtoIsland.send.onMyselfCityChg, logicName = "cmd4city"}
    NetProtoIsland.dispatch[257]={onReceive = NetProtoIsland.recive.summonMagic, send = NetProtoIsland.send.summonMagic, logicName = "cmd4city"}
    NetProtoIsland.dispatch[252]={onReceive = NetProtoIsland.recive.onTechChg, send = NetProtoIsland.send.onTechChg, logicName = "cmd4city"}
    NetProtoIsland.dispatch[222]={onReceive = NetProtoIsland.recive.getChats, send = NetProtoIsland.send.getChats, logicName = "USChat"}
    NetProtoIsland.dispatch[213]={onReceive = NetProtoIsland.recive.useItem, send = NetProtoIsland.send.useItem, logicName = "cmd4items"}
    NetProtoIsland.dispatch[260]={onReceive = NetProtoIsland.recive.summonMagicSpeedUp, send = NetProtoIsland.send.summonMagicSpeedUp, logicName = "cmd4city"}
    NetProtoIsland.dispatch[71]={onReceive = NetProtoIsland.recive.onBuildingChg, send = NetProtoIsland.send.onBuildingChg, logicName = "cmd4city"}
    NetProtoIsland.dispatch[199]={onReceive = NetProtoIsland.recive.getReportResult, send = NetProtoIsland.send.getReportResult, logicName = "cmd4mail"}
    NetProtoIsland.dispatch[152]={onReceive = NetProtoIsland.recive.onBattleBuildingDie, send = NetProtoIsland.send.onBattleBuildingDie, logicName = "USWorld"}
    NetProtoIsland.dispatch[57]={onReceive = NetProtoIsland.recive.onFinishBuildOneShip, send = NetProtoIsland.send.onFinishBuildOneShip, logicName = "cmd4city"}
    NetProtoIsland.dispatch[42]={onReceive = NetProtoIsland.recive.getUnitsInBuilding, send = NetProtoIsland.send.getUnitsInBuilding, logicName = "cmd4city"}
    NetProtoIsland.dispatch[66]={onReceive = NetProtoIsland.recive.buildShip, send = NetProtoIsland.send.buildShip, logicName = "cmd4city"}
    NetProtoIsland.dispatch[200]={onReceive = NetProtoIsland.recive.getReportDetail, send = NetProtoIsland.send.getReportDetail, logicName = "cmd4mail"}
    --==============================
    NetProtoIsland.cmds = {
        onItemChg = "onItemChg", -- 道具变化通知,
        onBattleLootRes = "onBattleLootRes", -- 当掠夺到资源时,
        fleetDepart = "fleetDepart", -- 舰队出征,
        sendMail = "sendMail", -- 发送邮件,
        sendBattleDeployUnit = "sendBattleDeployUnit", -- 推送战斗单元投放,
        collectRes = "collectRes", -- 收集资源,
        rmTile = "rmTile", -- 移除地块,
        onMapCellChg = "onMapCellChg", -- 当地块发生变化时推送,
        moveBuilding = "moveBuilding", -- 移动建筑,
        onBattleUnitDie = "onBattleUnitDie", -- 当战斗单元死亡,
        upLevBuildingImm = "upLevBuildingImm", -- 立即升级建筑,
        fleetAttackFleet = "fleetAttackFleet", -- 舰队攻击舰队,
        moveTile = "moveTile", -- 移动地块,
        getItem = "getItem", -- 取得道具信息,
        onBattleDeployUnit = "onBattleDeployUnit", -- 战场投放战斗单元,
        upLevBuilding = "upLevBuilding", -- 升级建筑,
        rmBuilding = "rmBuilding", -- 移除建筑,
        saveFleet = "saveFleet", -- 新建、更新舰队,
        login = "login", -- 登陆,
        getItemList = "getItemList", -- 取得道具列表,
        onMailChg = "onMailChg", -- 推送邮件,
        sendNetCfg = "sendNetCfg", -- 网络协议配置,
        setPlayerCurrLook4WorldPage = "setPlayerCurrLook4WorldPage", -- 设置用户当前正在查看大地图的哪一页，便于后续推送数据,
        getTechs = "getTechs", -- 取得科技列表,
        onResChg = "onResChg", -- 资源变化时推送,
        moveCity = "moveCity", -- 搬迁,
        sendChat = "sendChat", -- 发送聊天,
        newTile = "newTile", -- 新建地块,
        getMapDataByPageIdx = "getMapDataByPageIdx", -- 取得一屏的在地图数据,
        onPlayerChg = "onPlayerChg", -- 玩家信息变化时推送,
        deleteMail = "deleteMail", -- 删除邮件,
        receiveRewardMail = "receiveRewardMail", -- 领取邮件的奖励,
        replyMail = "replyMail", -- 回复邮件,
        fleetAttackIsland = "fleetAttackIsland", -- 舰队攻击岛屿,
        sendEndAttackIsland = "sendEndAttackIsland", -- 结束攻击岛,
        newBuilding = "newBuilding", -- 新建建筑,
        getMails = "getMails", -- 取得邮件列表,
        getFleet = "getFleet", -- 取得舰队信息,
        getBuilding = "getBuilding", -- 取得建筑,
        fleetBack = "fleetBack", -- 舰队返航,
        logout = "logout", -- 登出,
        getAllFleets = "getAllFleets", -- 取得所有舰队信息,
        readMail = "readMail", -- 读邮件,
        onFinishBuildingUpgrade = "onFinishBuildingUpgrade", -- 建筑升级完成,
        heart = "heart", -- 心跳,
        quitIslandBattle = "quitIslandBattle", -- 主动离开攻击岛,
        sendStartAttackIsland = "sendStartAttackIsland", -- 开始攻击岛,
        sendFleet = "sendFleet", -- 推送舰队信息,
        receiveReward = "receiveReward", -- 领取奖励包的物品,
        getRewardInfor = "getRewardInfor", -- 取得奖励包信息,
        upLevTechImm = "upLevTechImm", -- 立即升级科技,
        upLevTech = "upLevTech", -- 升级科技,
        sendPrepareAttackIsland = "sendPrepareAttackIsland", -- 准备攻击岛,
        getPlayerSimple = "getPlayerSimple", -- 取得玩家简要信息,
        onChatChg = "onChatChg", -- 当聊天有变化时的推送,
        onMyselfCityChg = "onMyselfCityChg", -- 自己的城变化时推送,
        summonMagic = "summonMagic", -- 召唤魔法技能,
        onTechChg = "onTechChg", -- 科技变化,
        getChats = "getChats", -- 取是玩家的聊天信息,
        useItem = "useItem", -- 道具变化通知,
        summonMagicSpeedUp = "summonMagicSpeedUp", -- 召唤魔法技能加速,
        onBuildingChg = "onBuildingChg", -- 建筑变化时推送,
        getReportResult = "getReportResult", -- 取得战报的结果,
        onBattleBuildingDie = "onBattleBuildingDie", -- 当建筑死亡,
        onFinishBuildOneShip = "onFinishBuildOneShip", -- 当完成建造部分舰艇的通知,
        getUnitsInBuilding = "getUnitsInBuilding", -- 取得保存到建筑上的战斗单元,
        buildShip = "buildShip", -- 造船,
        getReportDetail = "getReportDetail", -- 取得战报详细信息(攻击岛屿)
    }

    --==============================
    function CMD.dispatcher(agent, map, client_fd)
        if map == nil then
            skynet.error("[dispatcher] map == nil")
            return nil
        end
        local cmd = map[0] or map["0"]
        if cmd == nil then
            skynet.error("get cmd is nil")
            return nil
        end
        cmd = tonumber(cmd)
        local dis = NetProtoIsland.dispatch[cmd]
        if dis == nil then
            skynet.error("get protocol cfg is nil")
            return nil
        end
        local m = dis.onReceive(map)
        -- 执行逻辑处理
        local logicProc = skynet.call(agent, "lua", "getLogic", dis.logicName)
        if logicProc == nil then
            skynet.error("get logicServe is nil. serverName=[" .. dis.loginAccount .."]")
            return nil
        else
            return skynet.call(logicProc, "lua", m.cmd, m, client_fd, agent)
        end
    end
    --==============================
    skynet.start(function()
        skynet.dispatch("lua", function(_, _, command, command2, ...)
            if command == "send" then
                local f = NetProtoIsland.send[command2]
                skynet.ret(skynet.pack(f(...)))
            else
                local f = CMD[command]
                skynet.ret(skynet.pack(f(command2, ...)))
            end
        end)
    
        skynet.register "NetProtoIsland"
    end)

