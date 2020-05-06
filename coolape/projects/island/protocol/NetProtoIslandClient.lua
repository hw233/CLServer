    ---@class NetProtoIsland 网络协议
    NetProtoIsland = {}
    local table = table
    require("bio.BioUtl")

    NetProtoIsland.__sessionID = 0 -- 会话ID
    NetProtoIsland.dispatch = {}
    local __callbackInfor = {} -- 回调信息
    local __callTimes = 1
    ---public 处理回调
    local doCallback = function(map, result)
        local callbackKey = map[3]
        if callbackKey then
            local cbinfor = __callbackInfor[callbackKey]
            if cbinfor then
                pcall(cbinfor[1], cbinfor[2], result)
            end
            __callbackInfor[callbackKey] = nil
        end
    end
    ---public 超时处理
    local timeOutCallback = function(param)
        doCallback(param, {retInfor={}})
    end
    ---public 设计回调信息
    local setCallback = function (callback, orgs, ret, timeOutSec)
       if callback then
           local callbackKey = os.time() + __callTimes
           __callTimes = __callTimes + 1
           __callbackInfor[callbackKey] = {callback, orgs}
           ret[3] = callbackKey
        end
        if timeOutSec and timeOutSec > 0 then
            InvokeEx.invokeByUpdate(timeOutCallback, ret, timeOutSec)
        end
    end
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
            r[11] = m.code  -- 返回值 int
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
            r[205] = m.endFrames  -- 结束战斗的帧数（相较于第一次投入时的帧数增量） int
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
            r[16] = m.idx  -- 唯一标识舰队idx int
            r[113] = m.curpos  -- 当前所在世界grid的index int
            r[37] = m.status  -- 状态 none = 1, -- 无;moving = 2, -- 航行中;docked = 3, -- 停泊在港口;stay = 4, -- 停留在海面;fighting = 5 -- 正在战斗中 int
            r[104] = m.deadtime  -- 沉没的时间 int
            r[127] = m.pname  -- 玩家名 string
            r[103] = NetProtoIsland._toList(NetProtoIsland.ST_unitInfor, m.units)  -- 战斗单元列表
            r[114] = m.frompos  -- 出征的开始所在世界grid的index int
            r[118] = m.arrivetime  -- 到达时间 int
            r[18] = m.cidx  -- 城市idx int
            r[35] = m.name  -- 舰队名称 string
            r[115] = m.topos  -- 出征的目地所在世界grid的index int
            r[122] = NetProtoIsland.ST_vector3.toMap(m.fromposv3) -- 坐标
            r[119] = m.task  -- 执行任务类型 idel = 1, -- 待命状态;voyage = 2, -- 出征;back = 3, -- 返航;attack = 4 -- 攻击 int
            r[38] = m.pidx  -- 玩家idx int
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
            r[16] = m.idx  -- 唯一标识 int int
            r[20] = m.val4  -- 值4。如:产量，仓库的存储量等 int int
            r[21] = m.val3  -- 值3。如:产量，仓库的存储量等 int int
            r[22] = m.val2  -- 值2。如:产量，仓库的存储量等 int int
            r[23] = m.endtime  -- 完成升级、恢复、采集等的时间点 long int
            r[24] = m.lev  -- 等级 int int
            r[25] = m.val  -- 值。如:产量，仓库的存储量等 int int
            r[18] = m.cidx  -- 主城idx int int
            r[26] = m.val5  -- 值5。如:产量，仓库的存储量等 int int
            r[17] = m.attrid  -- 属性配置id int int
            r[27] = m.starttime  -- 开始升级、恢复、采集等的时间点 long int
            r[28] = m.state  -- 状态. 0：正常；1：升级中；9：恢复中 int
            r[19] = m.pos  -- 位置，即在城的gird中的index int int
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
            r[16] = m.idx  -- 网格index int
            r[13] = m.pageIdx  -- 所在屏的index int
            r[22] = m.val2  -- 值2 int
            r[21] = m.val3  -- 值3 int
            r[24] = m.lev  -- 等级 int
            r[30] = m.type  -- 地块类型 3：玩家，4：npc int
            r[18] = m.cidx  -- 主城idx int
            r[29] = m.val1  -- 值1 int
            r[17] = m.attrid  -- 配置id int
            r[28] = m.state  -- 状态  1:正常; int int
            r[35] = m.name  -- 名称 string
            r[101] = m.fidx  -- 舰队idx int
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
            r[31] = m.oil  -- 油 int
            r[32] = m.gold  -- 金 int
            r[33] = m.food  -- 粮 int
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
            r[16] = m.idx  -- 唯一标识 int int
            r[144] = m.protectEndTime  -- 免战结束时间 int
            r[34] = NetProtoIsland._toMap(NetProtoIsland.ST_tile, m.tiles)  -- 地块信息 key=idx, map
            r[256] = NetProtoIsland._toList(NetProtoIsland.ST_techInfor, m.techs)  -- 科技列表
            r[24] = m.lev  -- 等级 int int
            r[35] = m.name  -- 名称 string
            r[36] = NetProtoIsland._toMap(NetProtoIsland.ST_building, m.buildings)  -- 建筑信息 key=idx, map
            r[37] = m.status  -- 状态 1:正常; int int
            r[19] = m.pos  -- 城所在世界grid的index int int
            r[38] = m.pidx  -- 玩家idx int int
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
            r[16] = m.idx  -- 单元的idx int
            r[30] = m.type  -- 战斗单元类型 int
            r[99] = m.id  -- 战斗单元id(配置表的id) int
            r[24] = m.lev  -- 战斗单元等级 int
            r[19] = m.pos  -- 位置：网格的index int
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
            r[16] = m.idx  -- 唯一标识 int
            r[30] = m.type  -- 类型, IDConst.ChatType int
            r[218] = m.time  -- 发送时间 int
            r[178] = m.toPidx  -- 收信人(其它信息通过接口取得) int
            r[180] = m.content  -- 内容 string
            r[181] = m.fromPidx  -- 发送人(其它信息通过接口取得) int
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
            r[16] = m.idx  -- 唯一标识 int
            r[30] = m.type  -- 类型,IDConst.ItemType int
            r[67] = m.num  -- 数量 int
            r[99] = m.id  -- 对应的id int
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
            r[123] = m.y  -- int int
            r[124] = m.x  -- int int
            r[125] = m.z  -- int int
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
            r[16] = m.idx  -- 唯一标识舰队idx int
            r[35] = m.name  -- 名称 string
            r[229] = NetProtoIsland._toList(NetProtoIsland.ST_unitFormation, m.formations)  -- 战斗单元阵形
            r[127] = m.pname  -- 玩家名 string
            r[38] = m.pidx  -- 玩家idx int
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
            r[13] = m.pageIdx  -- 一屏所在的网格index  int
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
            r[24] = m.lev  -- 等级(大部分情况下lev可能是0，而是由科技决定，但是联盟里的兵等级是有值的) int int
            r[30] = m.type  -- 类型id(UnitType：role = 2, -- (ship, pet)；tech = 3,；skill = 4) int int
            r[99] = m.id  -- 配置的id int int
            r[100] = m.bidx  -- 所属建筑idx int int
            r[67] = m.num  -- 数量 int int
            r[101] = m.fidx  -- 所属舰队idx int int
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
            r[16] = m.idx  -- 唯一标识 int int
            r[17] = m.attrid  -- 属性配置id int int
            r[18] = m.cidx  -- 主城idx int int
            r[19] = m.pos  -- 位置，即在城的gird中的index int int
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
            r[15] = m.buildingIdx  -- 建筑的idx int
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
            r[24] = m.lev  -- 等级 int
            r[30] = m.type  -- 类型id(UnitType：role = 2, -- (ship, pet)；tech = 3,；skill = 4) int int
            r[99] = m.id  -- 配置的id int int
            r[168] = m.deployNum  -- 投放数量/原始数量 int
            r[169] = m.deadNum  -- 死亡数量 int
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
            r[16] = m.idx  -- 唯一标识 int
            r[24] = m.lev  -- 等级 int
            r[99] = m.id  -- 配置id int
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
            r[210] = m.honor  -- 获得的功勋 int
            r[198] = NetProtoIsland.ST_playerSimple.toMap(m.attacker) -- 进攻方
            r[101] = m.fidx  -- 舰队idx int
            r[131] = NetProtoIsland.ST_resInfor.toMap(m.lootRes) -- 掠夺的资源
            r[167] = NetProtoIsland._toList(NetProtoIsland.ST_battleUnitInfor, m.targetUsedUnits)  -- 防守方损失的战斗单元
            r[135] = m.star  -- 星级, 0表示失败，1-3星才算胜利 int
            r[197] = NetProtoIsland.ST_playerSimple.toMap(m.defender) -- 防守方
            r[30] = m.type  -- 战斗类型 int
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
            r[16] = m.idx  -- 唯一标识 int
            r[30] = m.type  -- 类型,IDConst.ItemType int
            r[99] = m.id  -- 对应的id int
            r[67] = m.num  -- 数量 int
            r[206] = m.rwidx  -- 奖励包idx int
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
            r[16] = m.idx  -- 唯一标识 int int
            r[132] = m.exp  -- 经验值 long int
            r[210] = m.honor  -- 功勋 long int
            r[40] = m.cityidx  -- 城池id int int
            r[228] = m.pvptimesTody  -- 今天进攻玩家的次数 int int
            r[41] = m.unionidx  -- 联盟id int int
            r[24] = m.lev  -- 等级 long int
            r[146] = m.attacking  -- 正在攻击玩家的岛屿 boolean
            r[35] = m.name  -- 名字 string
            r[136] = m.diam4reward  -- 钻石 long int
            r[39] = m.diam  -- 钻石 long int
            r[37] = m.status  -- 状态 1：正常 int int
            r[217] = m.icon  -- 头像 int
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
            r[16] = m.idx  -- 单元的idx int
            r[239] = m.timeMs  -- 行为发生时的时间毫秒(从战斗开始后) int
            r[230] = m.action  -- 行为类型1：攻击，2：移动，3：扣血，4：死亡 int
            r[231] = m.targetVal  -- 当是攻击时是目标对象的idx；当时扣血时，是血量 int
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
            r[161] = m.fakeRandom  -- 随机因子 int
            r[162] = m.fakeRandom2  -- 随机因子 int
            r[163] = m.fakeRandom3  -- 随机因子 int
            r[156] = m.frames  -- 投放时的帧数（相较于第一次投放时的帧数增量） int
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
            r[202] = m.parent  -- 父邮件idx（大于0时表示是回复的邮件） int
            r[174] = m.toName  -- 收件人名称 string
            r[30] = m.type  -- 类型，1：系统，2：战报；3：私信，4:联盟，5：客服 int
            r[181] = m.fromPidx  -- 发件人 int
            r[16] = m.idx  -- 唯一标识 int
            r[179] = m.fromIcon  -- 发件人头像id int
            r[172] = m.backup  -- 备用 string
            r[173] = m.toIcon  -- 收件人头像id int
            r[175] = m.comIdx  -- 通用ID,可以关联到比如战报等 int
            r[28] = m.state  -- 状态，0：未读，1：已读&未领奖，2：已读&已领奖 int
            r[184] = m.contentParams  -- 内容参数(json的map) string
            r[176] = m.title  -- 标题 string
            r[177] = m.rewardIdx  -- 奖励idx int
            r[178] = m.toPidx  -- 收件人 int
            r[203] = m.historyList  -- 历史记录(邮件的idx列表)
            r[180] = m.content  -- 内容 string
            r[171] = m.date  -- 时间 int
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
            r[83] = m.encryptType  -- 加密类别，1：只加密客户端，2：只加密服务器，3：前后端都加密，0及其它情况：不加密 int
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
            r[16] = m.idx  -- 唯一标识 int int
            r[204] = m.point  -- 功勋 long int
            r[210] = m.honor  -- 功勋 int int
            r[40] = m.cityidx  -- 城池id int int
            r[24] = m.lev  -- 等级 long int
            r[35] = m.name  -- 名字 string
            r[41] = m.unionidx  -- 联盟id int int
            r[132] = m.exp  -- 经验值 long int
            r[217] = m.icon  -- 头像 int
            r[37] = m.status  -- 状态 1：正常 int int
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
    NetProtoIsland.send = {
    -- 道具变化通知
    onItemChg = function(__callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 211
        ret[1] = NetProtoIsland.__sessionID
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 当掠夺到资源时
    onBattleLootRes = function(battleFidx, buildingIdx, resType, val, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 148
        ret[1] = NetProtoIsland.__sessionID
        ret[149] = battleFidx -- 舰队idx
        ret[15] = buildingIdx -- 建筑idx
        ret[78] = resType -- 资源类型
        ret[25] = val -- 资源值(当是工厂是，值为分钟数)
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 舰队出征
    fleetDepart = function(idx, toPos, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 108
        ret[1] = NetProtoIsland.__sessionID
        ret[16] = idx -- 舰队idx
        ret[109] = toPos -- 目标位置
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 发送邮件
    sendMail = function(toPidx, title, content, type, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 186
        ret[1] = NetProtoIsland.__sessionID
        ret[178] = toPidx -- 收件人idx
        ret[176] = title -- 标题
        ret[180] = content -- 内容
        ret[30] = type -- 邮件类型
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 推送战斗单元投放
    sendBattleDeployUnit = function(__callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 164
        ret[1] = NetProtoIsland.__sessionID
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 收集资源
    collectRes = function(idx, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 77
        ret[1] = NetProtoIsland.__sessionID
        ret[16] = idx -- 资源建筑的idx int
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 移除地块
    rmTile = function(idx, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 61
        ret[1] = NetProtoIsland.__sessionID
        ret[16] = idx -- 地块idx int
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 当地块发生变化时推送
    onMapCellChg = function(__callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 86
        ret[1] = NetProtoIsland.__sessionID
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 移动建筑
    moveBuilding = function(idx, pos, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 64
        ret[1] = NetProtoIsland.__sessionID
        ret[16] = idx -- 建筑idx int
        ret[19] = pos -- 位置 int
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 当战斗单元死亡
    onBattleUnitDie = function(battleFidx, unitInfor, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 150
        ret[1] = NetProtoIsland.__sessionID
        ret[149] = battleFidx -- 舰队idx
        ret[151] = NetProtoIsland.ST_unitInfor.toMap(unitInfor) -- 战斗单元信息
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 立即升级建筑
    upLevBuildingImm = function(idx, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 68
        ret[1] = NetProtoIsland.__sessionID
        ret[16] = idx -- 建筑idx int
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 舰队攻击舰队
    fleetAttackFleet = function(fidx, targetPos, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 130
        ret[1] = NetProtoIsland.__sessionID
        ret[101] = fidx -- 攻击方舰队idx
        ret[121] = targetPos -- 攻击目标的世界地图坐标idx int
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 移动地块
    moveTile = function(idx, pos, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 76
        ret[1] = NetProtoIsland.__sessionID
        ret[16] = idx -- 地块idx int
        ret[19] = pos -- 位置 int
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 取得道具信息
    getItem = function(idx, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 214
        ret[1] = NetProtoIsland.__sessionID
        ret[16] = idx -- 道具唯一标志
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 战场投放战斗单元
    onBattleDeployUnit = function(battleFidx, unitInfor, frames, vector3, fakeRandom, fakeRandom2, fakeRandom3, isOffense, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 155
        ret[1] = NetProtoIsland.__sessionID
        ret[149] = battleFidx -- 舰队idx
        ret[151] = NetProtoIsland.ST_unitInfor.toMap(unitInfor) -- 战斗单元信息
        ret[156] = frames -- 投放时的帧数（相较于第一次投入时的帧数增量）
        ret[157] = NetProtoIsland.ST_vector3.toMap(vector3) -- 投放坐标（是int，真实值x1000）
        ret[161] = fakeRandom -- 随机因子
        ret[162] = fakeRandom2 -- 随机因子2
        ret[163] = fakeRandom3 -- 随机因子3
        ret[154] = isOffense -- 是进攻方
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 升级建筑
    upLevBuilding = function(idx, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 44
        ret[1] = NetProtoIsland.__sessionID
        ret[16] = idx -- 建筑idx int
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 移除建筑
    rmBuilding = function(idx, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 46
        ret[1] = NetProtoIsland.__sessionID
        ret[16] = idx -- 地块idx int
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 新建、更新舰队
    saveFleet = function(cidx, idx, name, unitInfors, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 105
        ret[1] = NetProtoIsland.__sessionID
        ret[18] = cidx -- 城市
        ret[16] = idx -- 舰队idx（新建时可为空）
        ret[35] = name -- 舰队名（最长7个字）
        ret[106] = NetProtoIsland._toList(NetProtoIsland.ST_unitInfor, unitInfors)  -- 战斗单元列表
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 登陆
    login = function(uidx, channel, language, deviceID, isEditMode, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 48
        ret[1] = NetProtoIsland.__sessionID
        ret[49] = uidx -- 用户id
        ret[50] = channel -- 渠道号
        ret[188] = language -- 语言
        ret[51] = deviceID -- 机器码
        ret[52] = isEditMode -- 编辑模式
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 取得道具列表
    getItemList = function(__callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 215
        ret[1] = NetProtoIsland.__sessionID
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 推送邮件
    onMailChg = function(__callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 193
        ret[1] = NetProtoIsland.__sessionID
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 网络协议配置
    sendNetCfg = function(__callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 81
        ret[1] = NetProtoIsland.__sessionID
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 设置用户当前正在查看大地图的哪一页，便于后续推送数据
    setPlayerCurrLook4WorldPage = function(pageIdx, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 116
        ret[1] = NetProtoIsland.__sessionID
        ret[13] = pageIdx -- 一屏所在的网格index
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 取得科技列表
    getTechs = function(__callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 253
        ret[1] = NetProtoIsland.__sessionID
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 资源变化时推送
    onResChg = function(__callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 62
        ret[1] = NetProtoIsland.__sessionID
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 搬迁
    moveCity = function(cidx, pos, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 88
        ret[1] = NetProtoIsland.__sessionID
        ret[18] = cidx -- 城市idx
        ret[19] = pos -- 新位置 int
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 发送聊天
    sendChat = function(content, type, toPidx, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 221
        ret[1] = NetProtoIsland.__sessionID
        ret[180] = content -- 内容
        ret[30] = type -- 类型
        ret[178] = toPidx -- 目标玩家
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 新建地块
    newTile = function(pos, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 69
        ret[1] = NetProtoIsland.__sessionID
        ret[19] = pos -- 位置 int
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 取得一屏的在地图数据
    getMapDataByPageIdx = function(pageIdx, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 74
        ret[1] = NetProtoIsland.__sessionID
        ret[13] = pageIdx -- 一屏所在的网格index
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 玩家信息变化时推送
    onPlayerChg = function(__callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 72
        ret[1] = NetProtoIsland.__sessionID
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 删除邮件
    deleteMail = function(idx, deleteAll, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 194
        ret[1] = NetProtoIsland.__sessionID
        ret[16] = idx -- 邮件idx
        ret[195] = deleteAll -- 删除所有 bool
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 领取邮件的奖励
    receiveRewardMail = function(idx, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 196
        ret[1] = NetProtoIsland.__sessionID
        ret[16] = idx -- 邮件idx
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 回复邮件
    replyMail = function(idx, content, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 190
        ret[1] = NetProtoIsland.__sessionID
        ret[16] = idx -- 邮件idx
        ret[180] = content -- 内容
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 舰队攻击岛屿
    fleetAttackIsland = function(fidx, targetPos, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 129
        ret[1] = NetProtoIsland.__sessionID
        ret[101] = fidx -- 攻击方舰队idx
        ret[121] = targetPos -- 攻击目标的世界地图坐标idx int
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 结束攻击岛
    sendEndAttackIsland = function(__callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 137
        ret[1] = NetProtoIsland.__sessionID
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 新建建筑
    newBuilding = function(attrid, pos, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 47
        ret[1] = NetProtoIsland.__sessionID
        ret[17] = attrid -- 建筑配置id int
        ret[19] = pos -- 位置 int
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 取得邮件列表
    getMails = function(__callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 189
        ret[1] = NetProtoIsland.__sessionID
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 取得舰队信息
    getFleet = function(idx, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 110
        ret[1] = NetProtoIsland.__sessionID
        ret[16] = idx -- 舰队idx
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 取得建筑
    getBuilding = function(idx, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 60
        ret[1] = NetProtoIsland.__sessionID
        ret[16] = idx -- 建筑idx int
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 舰队返航
    fleetBack = function(idx, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 126
        ret[1] = NetProtoIsland.__sessionID
        ret[16] = idx -- 舰队idx
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 登出
    logout = function(__callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 65
        ret[1] = NetProtoIsland.__sessionID
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 取得所有舰队信息
    getAllFleets = function(cidx, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 111
        ret[1] = NetProtoIsland.__sessionID
        ret[18] = cidx -- 城市的idx
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 读邮件
    readMail = function(idx, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 192
        ret[1] = NetProtoIsland.__sessionID
        ret[16] = idx -- 邮件idx
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 建筑升级完成
    onFinishBuildingUpgrade = function(__callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 80
        ret[1] = NetProtoIsland.__sessionID
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 心跳
    heart = function(__callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 73
        ret[1] = NetProtoIsland.__sessionID
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 主动离开攻击岛
    quitIslandBattle = function(fidx, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 143
        ret[1] = NetProtoIsland.__sessionID
        ret[101] = fidx -- 攻击方舰队idx
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 开始攻击岛
    sendStartAttackIsland = function(__callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 139
        ret[1] = NetProtoIsland.__sessionID
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 推送舰队信息
    sendFleet = function(__callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 117
        ret[1] = NetProtoIsland.__sessionID
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 领取奖励包的物品
    receiveReward = function(rwidx, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 207
        ret[1] = NetProtoIsland.__sessionID
        ret[206] = rwidx -- 奖励包idx
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 取得奖励包信息
    getRewardInfor = function(rwidx, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 209
        ret[1] = NetProtoIsland.__sessionID
        ret[206] = rwidx -- 奖励包idx
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 立即升级科技
    upLevTechImm = function(id, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 255
        ret[1] = NetProtoIsland.__sessionID
        ret[99] = id -- 科技的配置id
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 升级科技
    upLevTech = function(id, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 250
        ret[1] = NetProtoIsland.__sessionID
        ret[99] = id -- 科技的配置id
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 准备攻击岛
    sendPrepareAttackIsland = function(__callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 140
        ret[1] = NetProtoIsland.__sessionID
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 取得玩家简要信息
    getPlayerSimple = function(pidx, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 227
        ret[1] = NetProtoIsland.__sessionID
        ret[38] = pidx -- 玩家的idx
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 当聊天有变化时的推送
    onChatChg = function(__callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 219
        ret[1] = NetProtoIsland.__sessionID
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 自己的城变化时推送
    onMyselfCityChg = function(__callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 89
        ret[1] = NetProtoIsland.__sessionID
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 召唤魔法技能
    summonMagic = function(id, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 257
        ret[1] = NetProtoIsland.__sessionID
        ret[99] = id -- 魔法的配置id
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 科技变化
    onTechChg = function(__callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 252
        ret[1] = NetProtoIsland.__sessionID
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 取是玩家的聊天信息
    getChats = function(__callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 222
        ret[1] = NetProtoIsland.__sessionID
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 道具变化通知
    useItem = function(idx, num, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 213
        ret[1] = NetProtoIsland.__sessionID
        ret[16] = idx -- 道具idx
        ret[67] = num -- 数量
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 召唤魔法技能加速
    summonMagicSpeedUp = function(id, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 260
        ret[1] = NetProtoIsland.__sessionID
        ret[99] = id -- 魔法的配置id
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 建筑变化时推送
    onBuildingChg = function(__callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 71
        ret[1] = NetProtoIsland.__sessionID
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 取得战报的结果
    getReportResult = function(idx, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 199
        ret[1] = NetProtoIsland.__sessionID
        ret[16] = idx -- 战报idx
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 当建筑死亡
    onBattleBuildingDie = function(battleFidx, bidx, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 152
        ret[1] = NetProtoIsland.__sessionID
        ret[149] = battleFidx -- 舰队idx
        ret[100] = bidx -- 建筑idx
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 当完成建造部分舰艇的通知
    onFinishBuildOneShip = function(buildingIdx, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 57
        ret[1] = NetProtoIsland.__sessionID
        ret[15] = buildingIdx -- 造船厂的idx int
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 取得保存到建筑上的战斗单元
    getUnitsInBuilding = function(buildingIdx, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 42
        ret[1] = NetProtoIsland.__sessionID
        ret[15] = buildingIdx -- 造船厂的idx int
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 造船
    buildShip = function(buildingIdx, shipAttrID, num, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 66
        ret[1] = NetProtoIsland.__sessionID
        ret[15] = buildingIdx -- 造船厂的idx int
        ret[58] = shipAttrID -- 舰船配置id int
        ret[67] = num -- 数量 int
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    -- 取得战报详细信息(攻击岛屿)
    getReportDetail = function(idx, __callback, __orgs, __timeoutSec) -- __callback:接口回调, __orgs:回调参数, __timeoutSec:超时的秒数
        local ret = {}
        ret[0] = 200
        ret[1] = NetProtoIsland.__sessionID
        ret[16] = idx -- 战报idx
        setCallback(__callback, __orgs, ret, __timeoutSec)
        return ret
    end,
    }
    --==============================
    NetProtoIsland.recive = {
    ---@class NetProtoIsland.RC_onItemChg
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public item NetProtoIsland.ST_item 道具信息
    onItemChg = function(map)
        local ret = {}
        ret.cmd = "onItemChg"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.item = NetProtoIsland.ST_item.parse(map[212]) -- 道具信息
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_onBattleLootRes
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    onBattleLootRes = function(map)
        local ret = {}
        ret.cmd = "onBattleLootRes"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_fleetDepart
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public fleetinfor NetProtoIsland.ST_fleetinfor 舰队信息
    fleetDepart = function(map)
        local ret = {}
        ret.cmd = "fleetDepart"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.fleetinfor = NetProtoIsland.ST_fleetinfor.parse(map[107]) -- 舰队信息
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_sendMail
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public mail NetProtoIsland.ST_mail 邮件
    sendMail = function(map)
        local ret = {}
        ret.cmd = "sendMail"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.mail = NetProtoIsland.ST_mail.parse(map[191]) -- 邮件
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_sendBattleDeployUnit
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public deployUnitInfor NetProtoIsland.ST_deployUnitInfor 战斗单元投放信息
    sendBattleDeployUnit = function(map)
        local ret = {}
        ret.cmd = "sendBattleDeployUnit"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.deployUnitInfor = NetProtoIsland.ST_deployUnitInfor.parse(map[165]) -- 战斗单元投放信息
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_collectRes
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public resType  收集的资源类型 int
    ---@field public resVal  收集到的资源量 int
    ---@field public building NetProtoIsland.ST_building 建筑信息
    collectRes = function(map)
        local ret = {}
        ret.cmd = "collectRes"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.resType = map[78]-- 收集的资源类型 int
        ret.resVal = map[79]-- 收集到的资源量 int
        ret.building = NetProtoIsland.ST_building.parse(map[45]) -- 建筑信息
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_rmTile
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public idx  被移除地块的idx int
    rmTile = function(map)
        local ret = {}
        ret.cmd = "rmTile"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.idx = map[16]-- 被移除地块的idx int
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_onMapCellChg
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public mapCell NetProtoIsland.ST_mapCell 地块
    ---@field public isRemove  是否是删除
    onMapCellChg = function(map)
        local ret = {}
        ret.cmd = "onMapCellChg"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.mapCell = NetProtoIsland.ST_mapCell.parse(map[87]) -- 地块
        ret.isRemove = map[98]-- 是否是删除
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_moveBuilding
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public building NetProtoIsland.ST_building 建筑信息
    moveBuilding = function(map)
        local ret = {}
        ret.cmd = "moveBuilding"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.building = NetProtoIsland.ST_building.parse(map[45]) -- 建筑信息
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_onBattleUnitDie
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    onBattleUnitDie = function(map)
        local ret = {}
        ret.cmd = "onBattleUnitDie"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_upLevBuildingImm
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public building NetProtoIsland.ST_building 建筑信息
    upLevBuildingImm = function(map)
        local ret = {}
        ret.cmd = "upLevBuildingImm"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.building = NetProtoIsland.ST_building.parse(map[45]) -- 建筑信息
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_fleetAttackFleet
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    fleetAttackFleet = function(map)
        local ret = {}
        ret.cmd = "fleetAttackFleet"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_moveTile
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public tile NetProtoIsland.ST_tile 地块信息
    moveTile = function(map)
        local ret = {}
        ret.cmd = "moveTile"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.tile = NetProtoIsland.ST_tile.parse(map[70]) -- 地块信息
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_getItem
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public item NetProtoIsland.ST_item 道具信息
    getItem = function(map)
        local ret = {}
        ret.cmd = "getItem"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.item = NetProtoIsland.ST_item.parse(map[212]) -- 道具信息
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_onBattleDeployUnit
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    onBattleDeployUnit = function(map)
        local ret = {}
        ret.cmd = "onBattleDeployUnit"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_upLevBuilding
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public building NetProtoIsland.ST_building 建筑信息
    upLevBuilding = function(map)
        local ret = {}
        ret.cmd = "upLevBuilding"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.building = NetProtoIsland.ST_building.parse(map[45]) -- 建筑信息
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_rmBuilding
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public idx  被移除建筑的idx int
    rmBuilding = function(map)
        local ret = {}
        ret.cmd = "rmBuilding"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.idx = map[16]-- 被移除建筑的idx int
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_saveFleet
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public fleetinfor NetProtoIsland.ST_fleetinfor 舰队信息
    saveFleet = function(map)
        local ret = {}
        ret.cmd = "saveFleet"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.fleetinfor = NetProtoIsland.ST_fleetinfor.parse(map[107]) -- 舰队信息
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_login
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public player NetProtoIsland.ST_player 玩家信息
    ---@field public city NetProtoIsland.ST_city 主城信息
    ---@field public systime  系统时间 long
    ---@field public session  会话id
    login = function(map)
        local ret = {}
        ret.cmd = "login"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.player = NetProtoIsland.ST_player.parse(map[53]) -- 玩家信息
        ret.city = NetProtoIsland.ST_city.parse(map[54]) -- 主城信息
        ret.systime = map[55]-- 系统时间 long
        ret.session = map[56]-- 会话id
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_getItemList
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public items NetProtoIsland.ST_item Array List 道具列表
    getItemList = function(map)
        local ret = {}
        ret.cmd = "getItemList"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.items = NetProtoIsland._parseList(NetProtoIsland.ST_item, map[216]) -- 道具列表
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_onMailChg
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public mails NetProtoIsland.ST_mail Array List 邮件列表
    onMailChg = function(map)
        local ret = {}
        ret.cmd = "onMailChg"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.mails = NetProtoIsland._parseList(NetProtoIsland.ST_mail, map[187]) -- 邮件列表
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_sendNetCfg
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public netCfg NetProtoIsland.ST_netCfg 网络协议解析配置
    ---@field public systime  系统时间 long
    sendNetCfg = function(map)
        local ret = {}
        ret.cmd = "sendNetCfg"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.netCfg = NetProtoIsland.ST_netCfg.parse(map[82]) -- 网络协议解析配置
        ret.systime = map[55]-- 系统时间 long
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_setPlayerCurrLook4WorldPage
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    setPlayerCurrLook4WorldPage = function(map)
        local ret = {}
        ret.cmd = "setPlayerCurrLook4WorldPage"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_getTechs
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public techInfors NetProtoIsland.ST_techInfor Array List 科技列表
    getTechs = function(map)
        local ret = {}
        ret.cmd = "getTechs"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.techInfors = NetProtoIsland._parseList(NetProtoIsland.ST_techInfor, map[254]) -- 科技列表
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_onResChg
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public resInfor NetProtoIsland.ST_resInfor 资源信息
    onResChg = function(map)
        local ret = {}
        ret.cmd = "onResChg"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.resInfor = NetProtoIsland.ST_resInfor.parse(map[63]) -- 资源信息
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_moveCity
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    moveCity = function(map)
        local ret = {}
        ret.cmd = "moveCity"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_sendChat
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    sendChat = function(map)
        local ret = {}
        ret.cmd = "sendChat"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_newTile
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public tile NetProtoIsland.ST_tile 地块信息对象
    newTile = function(map)
        local ret = {}
        ret.cmd = "newTile"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.tile = NetProtoIsland.ST_tile.parse(map[70]) -- 地块信息对象
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_getMapDataByPageIdx
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public mapPage NetProtoIsland.ST_mapPage 在地图一屏数据 map
    ---@field public fleetinfors NetProtoIsland.ST_fleetinfor Array List 舰队列表
    getMapDataByPageIdx = function(map)
        local ret = {}
        ret.cmd = "getMapDataByPageIdx"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.mapPage = NetProtoIsland.ST_mapPage.parse(map[75]) -- 在地图一屏数据 map
        ret.fleetinfors = NetProtoIsland._parseList(NetProtoIsland.ST_fleetinfor, map[112]) -- 舰队列表
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_onPlayerChg
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public player NetProtoIsland.ST_player 玩家信息
    onPlayerChg = function(map)
        local ret = {}
        ret.cmd = "onPlayerChg"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.player = NetProtoIsland.ST_player.parse(map[53]) -- 玩家信息
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_deleteMail
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    deleteMail = function(map)
        local ret = {}
        ret.cmd = "deleteMail"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_receiveRewardMail
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public mail NetProtoIsland.ST_mail 邮件
    receiveRewardMail = function(map)
        local ret = {}
        ret.cmd = "receiveRewardMail"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.mail = NetProtoIsland.ST_mail.parse(map[191]) -- 邮件
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_replyMail
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public mail NetProtoIsland.ST_mail 邮件
    replyMail = function(map)
        local ret = {}
        ret.cmd = "replyMail"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.mail = NetProtoIsland.ST_mail.parse(map[191]) -- 邮件
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_fleetAttackIsland
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public fleetinfor NetProtoIsland.ST_fleetinfor 进攻方舰队数据
    fleetAttackIsland = function(map)
        local ret = {}
        ret.cmd = "fleetAttackIsland"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.fleetinfor = NetProtoIsland.ST_fleetinfor.parse(map[107]) -- 进攻方舰队数据
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_sendEndAttackIsland
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public battleresult NetProtoIsland.ST_battleresult 战斗结果
    sendEndAttackIsland = function(map)
        local ret = {}
        ret.cmd = "sendEndAttackIsland"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.battleresult = NetProtoIsland.ST_battleresult.parse(map[138]) -- 战斗结果
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_newBuilding
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public building NetProtoIsland.ST_building 建筑信息对象
    newBuilding = function(map)
        local ret = {}
        ret.cmd = "newBuilding"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.building = NetProtoIsland.ST_building.parse(map[45]) -- 建筑信息对象
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_getMails
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public mails NetProtoIsland.ST_mail Array List 邮件列表
    getMails = function(map)
        local ret = {}
        ret.cmd = "getMails"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.mails = NetProtoIsland._parseList(NetProtoIsland.ST_mail, map[187]) -- 邮件列表
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_getFleet
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public fleetinfor NetProtoIsland.ST_fleetinfor 舰队信息
    getFleet = function(map)
        local ret = {}
        ret.cmd = "getFleet"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.fleetinfor = NetProtoIsland.ST_fleetinfor.parse(map[107]) -- 舰队信息
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_getBuilding
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public building NetProtoIsland.ST_building 建筑信息对象
    getBuilding = function(map)
        local ret = {}
        ret.cmd = "getBuilding"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.building = NetProtoIsland.ST_building.parse(map[45]) -- 建筑信息对象
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_fleetBack
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public fleetinfor NetProtoIsland.ST_fleetinfor 舰队信息
    fleetBack = function(map)
        local ret = {}
        ret.cmd = "fleetBack"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.fleetinfor = NetProtoIsland.ST_fleetinfor.parse(map[107]) -- 舰队信息
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_logout
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    logout = function(map)
        local ret = {}
        ret.cmd = "logout"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_getAllFleets
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public fleetinfors NetProtoIsland.ST_fleetinfor Array List 舰队列表
    getAllFleets = function(map)
        local ret = {}
        ret.cmd = "getAllFleets"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.fleetinfors = NetProtoIsland._parseList(NetProtoIsland.ST_fleetinfor, map[112]) -- 舰队列表
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_readMail
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public mail NetProtoIsland.ST_mail 邮件
    readMail = function(map)
        local ret = {}
        ret.cmd = "readMail"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.mail = NetProtoIsland.ST_mail.parse(map[191]) -- 邮件
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_onFinishBuildingUpgrade
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public building NetProtoIsland.ST_building 建筑信息
    onFinishBuildingUpgrade = function(map)
        local ret = {}
        ret.cmd = "onFinishBuildingUpgrade"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.building = NetProtoIsland.ST_building.parse(map[45]) -- 建筑信息
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_heart
    heart = function(map)
        local ret = {}
        ret.cmd = "heart"
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_quitIslandBattle
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    quitIslandBattle = function(map)
        local ret = {}
        ret.cmd = "quitIslandBattle"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_sendStartAttackIsland
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public player NetProtoIsland.ST_player 被攻击方玩家信息
    ---@field public city NetProtoIsland.ST_city 被攻击方主城信息
    ---@field public unitsInBuildings NetProtoIsland.ST_unitsInBuilding Array List 被攻击方舰船数据
    ---@field public player2 NetProtoIsland.ST_player 攻击方玩家信息
    ---@field public fleetinfor NetProtoIsland.ST_fleetinfor 进攻方舰队数据
    ---@field public endTimeLimit  战斗限制时间
    sendStartAttackIsland = function(map)
        local ret = {}
        ret.cmd = "sendStartAttackIsland"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.player = NetProtoIsland.ST_player.parse(map[53]) -- 被攻击方玩家信息
        ret.city = NetProtoIsland.ST_city.parse(map[54]) -- 被攻击方主城信息
        ret.unitsInBuildings = NetProtoIsland._parseList(NetProtoIsland.ST_unitsInBuilding, map[258]) -- 被攻击方舰船数据
        ret.player2 = NetProtoIsland.ST_player.parse(map[141]) -- 攻击方玩家信息
        ret.fleetinfor = NetProtoIsland.ST_fleetinfor.parse(map[107]) -- 进攻方舰队数据
        ret.endTimeLimit = map[145]-- 战斗限制时间
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_sendFleet
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public fleetinfor NetProtoIsland.ST_fleetinfor 舰队信息
    ---@field public isRemove  是否移除
    sendFleet = function(map)
        local ret = {}
        ret.cmd = "sendFleet"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.fleetinfor = NetProtoIsland.ST_fleetinfor.parse(map[107]) -- 舰队信息
        ret.isRemove = map[98]-- 是否移除
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_receiveReward
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public rewardInfors NetProtoIsland.ST_rewardInfor Array List 奖励包信息
    receiveReward = function(map)
        local ret = {}
        ret.cmd = "receiveReward"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.rewardInfors = NetProtoIsland._parseList(NetProtoIsland.ST_rewardInfor, map[208]) -- 奖励包信息
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_getRewardInfor
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public rewardInfors NetProtoIsland.ST_rewardInfor Array List 奖励包信息
    getRewardInfor = function(map)
        local ret = {}
        ret.cmd = "getRewardInfor"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.rewardInfors = NetProtoIsland._parseList(NetProtoIsland.ST_rewardInfor, map[208]) -- 奖励包信息
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_upLevTechImm
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public techInfor NetProtoIsland.ST_techInfor 科技信息
    upLevTechImm = function(map)
        local ret = {}
        ret.cmd = "upLevTechImm"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.techInfor = NetProtoIsland.ST_techInfor.parse(map[251]) -- 科技信息
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_upLevTech
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public techInfor NetProtoIsland.ST_techInfor 科技信息
    upLevTech = function(map)
        local ret = {}
        ret.cmd = "upLevTech"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.techInfor = NetProtoIsland.ST_techInfor.parse(map[251]) -- 科技信息
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_sendPrepareAttackIsland
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public player NetProtoIsland.ST_player 被攻击方玩家信息
    ---@field public city NetProtoIsland.ST_city 被攻击方主城信息
    ---@field public player2 NetProtoIsland.ST_player 攻击方玩家信息
    ---@field public city2 NetProtoIsland.ST_city 攻击方主城信息
    ---@field public fleetinfor NetProtoIsland.ST_fleetinfor 进攻方舰队数据
    sendPrepareAttackIsland = function(map)
        local ret = {}
        ret.cmd = "sendPrepareAttackIsland"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.player = NetProtoIsland.ST_player.parse(map[53]) -- 被攻击方玩家信息
        ret.city = NetProtoIsland.ST_city.parse(map[54]) -- 被攻击方主城信息
        ret.player2 = NetProtoIsland.ST_player.parse(map[141]) -- 攻击方玩家信息
        ret.city2 = NetProtoIsland.ST_city.parse(map[142]) -- 攻击方主城信息
        ret.fleetinfor = NetProtoIsland.ST_fleetinfor.parse(map[107]) -- 进攻方舰队数据
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_getPlayerSimple
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public playerSimple NetProtoIsland.ST_playerSimple 玩家简要信息
    getPlayerSimple = function(map)
        local ret = {}
        ret.cmd = "getPlayerSimple"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.playerSimple = NetProtoIsland.ST_playerSimple.parse(map[226]) -- 玩家简要信息
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_onChatChg
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public chatInfors NetProtoIsland.ST_chatInfor Array List 聊天信息列表
    onChatChg = function(map)
        local ret = {}
        ret.cmd = "onChatChg"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.chatInfors = NetProtoIsland._parseList(NetProtoIsland.ST_chatInfor, map[220]) -- 聊天信息列表
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_onMyselfCityChg
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public city NetProtoIsland.ST_city 主城信息
    onMyselfCityChg = function(map)
        local ret = {}
        ret.cmd = "onMyselfCityChg"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.city = NetProtoIsland.ST_city.parse(map[54]) -- 主城信息
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_summonMagic
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    summonMagic = function(map)
        local ret = {}
        ret.cmd = "summonMagic"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_onTechChg
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public techInfor NetProtoIsland.ST_techInfor 科技信息
    onTechChg = function(map)
        local ret = {}
        ret.cmd = "onTechChg"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.techInfor = NetProtoIsland.ST_techInfor.parse(map[251]) -- 科技信息
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_getChats
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public chatInfors NetProtoIsland.ST_chatInfor Array List 公聊信息列表
    ---@field public chatInfors2 NetProtoIsland.ST_chatInfor Array List 私聊信息列表
    ---@field public chatInfors3 NetProtoIsland.ST_chatInfor Array List 联盟聊天信息列表
    getChats = function(map)
        local ret = {}
        ret.cmd = "getChats"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.chatInfors = NetProtoIsland._parseList(NetProtoIsland.ST_chatInfor, map[220]) -- 公聊信息列表
        ret.chatInfors2 = NetProtoIsland._parseList(NetProtoIsland.ST_chatInfor, map[223]) -- 私聊信息列表
        ret.chatInfors3 = NetProtoIsland._parseList(NetProtoIsland.ST_chatInfor, map[224]) -- 联盟聊天信息列表
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_useItem
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public item NetProtoIsland.ST_item 道具信息
    useItem = function(map)
        local ret = {}
        ret.cmd = "useItem"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.item = NetProtoIsland.ST_item.parse(map[212]) -- 道具信息
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_summonMagicSpeedUp
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    summonMagicSpeedUp = function(map)
        local ret = {}
        ret.cmd = "summonMagicSpeedUp"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_onBuildingChg
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public building NetProtoIsland.ST_building 建筑信息
    onBuildingChg = function(map)
        local ret = {}
        ret.cmd = "onBuildingChg"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.building = NetProtoIsland.ST_building.parse(map[45]) -- 建筑信息
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_getReportResult
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public battleresult NetProtoIsland.ST_battleresult 战斗结果
    getReportResult = function(map)
        local ret = {}
        ret.cmd = "getReportResult"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.battleresult = NetProtoIsland.ST_battleresult.parse(map[138]) -- 战斗结果
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_onBattleBuildingDie
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    onBattleBuildingDie = function(map)
        local ret = {}
        ret.cmd = "onBattleBuildingDie"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_onFinishBuildOneShip
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public buildingIdx  造船厂的idx int
    ---@field public shipAttrID  舰船的配置id
    ---@field public shipNum  舰船的数量
    onFinishBuildOneShip = function(map)
        local ret = {}
        ret.cmd = "onFinishBuildOneShip"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.buildingIdx = map[15]-- 造船厂的idx int
        ret.shipAttrID = map[58]-- 舰船的配置id
        ret.shipNum = map[59]-- 舰船的数量
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_getUnitsInBuilding
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public unitsInBuilding NetProtoIsland.ST_unitsInBuilding 造船厂的idx int
    getUnitsInBuilding = function(map)
        local ret = {}
        ret.cmd = "getUnitsInBuilding"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.unitsInBuilding = NetProtoIsland.ST_unitsInBuilding.parse(map[259]) -- 造船厂的idx int
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_buildShip
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public building NetProtoIsland.ST_building 造船厂信息
    buildShip = function(map)
        local ret = {}
        ret.cmd = "buildShip"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.building = NetProtoIsland.ST_building.parse(map[45]) -- 造船厂信息
        doCallback(map, ret)
        return ret
    end,
    ---@class NetProtoIsland.RC_getReportDetail
    ---@field public retInfor NetProtoIsland.ST_retInfor 返回信息
    ---@field public idx  战报idx
    ---@field public battleType  战斗类型
    ---@field public battleDetail NetProtoIsland.ST_battleDetail 攻岛战斗详细数据（根据类型不同，可能为空）
    ---@field public battleFleetDetail NetProtoIsland.ST_battleFleetDetail 舰队战详细数据（根据类型不同，可能为空）
    ---@field public battleresult NetProtoIsland.ST_battleresult 战斗结果
    getReportDetail = function(map)
        local ret = {}
        ret.cmd = "getReportDetail"
        ret.retInfor = NetProtoIsland.ST_retInfor.parse(map[2]) -- 返回信息
        ret.idx = map[16]-- 战报idx
        ret.battleType = map[244]-- 战斗类型
        ret.battleDetail = NetProtoIsland.ST_battleDetail.parse(map[243]) -- 攻岛战斗详细数据（根据类型不同，可能为空）
        ret.battleFleetDetail = NetProtoIsland.ST_battleFleetDetail.parse(map[238]) -- 舰队战详细数据（根据类型不同，可能为空）
        ret.battleresult = NetProtoIsland.ST_battleresult.parse(map[138]) -- 战斗结果
        doCallback(map, ret)
        return ret
    end,
    }
    --==============================
    NetProtoIsland.dispatch[211]={onReceive = NetProtoIsland.recive.onItemChg, send = NetProtoIsland.send.onItemChg}
    NetProtoIsland.dispatch[148]={onReceive = NetProtoIsland.recive.onBattleLootRes, send = NetProtoIsland.send.onBattleLootRes}
    NetProtoIsland.dispatch[108]={onReceive = NetProtoIsland.recive.fleetDepart, send = NetProtoIsland.send.fleetDepart}
    NetProtoIsland.dispatch[186]={onReceive = NetProtoIsland.recive.sendMail, send = NetProtoIsland.send.sendMail}
    NetProtoIsland.dispatch[164]={onReceive = NetProtoIsland.recive.sendBattleDeployUnit, send = NetProtoIsland.send.sendBattleDeployUnit}
    NetProtoIsland.dispatch[77]={onReceive = NetProtoIsland.recive.collectRes, send = NetProtoIsland.send.collectRes}
    NetProtoIsland.dispatch[61]={onReceive = NetProtoIsland.recive.rmTile, send = NetProtoIsland.send.rmTile}
    NetProtoIsland.dispatch[86]={onReceive = NetProtoIsland.recive.onMapCellChg, send = NetProtoIsland.send.onMapCellChg}
    NetProtoIsland.dispatch[64]={onReceive = NetProtoIsland.recive.moveBuilding, send = NetProtoIsland.send.moveBuilding}
    NetProtoIsland.dispatch[150]={onReceive = NetProtoIsland.recive.onBattleUnitDie, send = NetProtoIsland.send.onBattleUnitDie}
    NetProtoIsland.dispatch[68]={onReceive = NetProtoIsland.recive.upLevBuildingImm, send = NetProtoIsland.send.upLevBuildingImm}
    NetProtoIsland.dispatch[130]={onReceive = NetProtoIsland.recive.fleetAttackFleet, send = NetProtoIsland.send.fleetAttackFleet}
    NetProtoIsland.dispatch[76]={onReceive = NetProtoIsland.recive.moveTile, send = NetProtoIsland.send.moveTile}
    NetProtoIsland.dispatch[214]={onReceive = NetProtoIsland.recive.getItem, send = NetProtoIsland.send.getItem}
    NetProtoIsland.dispatch[155]={onReceive = NetProtoIsland.recive.onBattleDeployUnit, send = NetProtoIsland.send.onBattleDeployUnit}
    NetProtoIsland.dispatch[44]={onReceive = NetProtoIsland.recive.upLevBuilding, send = NetProtoIsland.send.upLevBuilding}
    NetProtoIsland.dispatch[46]={onReceive = NetProtoIsland.recive.rmBuilding, send = NetProtoIsland.send.rmBuilding}
    NetProtoIsland.dispatch[105]={onReceive = NetProtoIsland.recive.saveFleet, send = NetProtoIsland.send.saveFleet}
    NetProtoIsland.dispatch[48]={onReceive = NetProtoIsland.recive.login, send = NetProtoIsland.send.login}
    NetProtoIsland.dispatch[215]={onReceive = NetProtoIsland.recive.getItemList, send = NetProtoIsland.send.getItemList}
    NetProtoIsland.dispatch[193]={onReceive = NetProtoIsland.recive.onMailChg, send = NetProtoIsland.send.onMailChg}
    NetProtoIsland.dispatch[81]={onReceive = NetProtoIsland.recive.sendNetCfg, send = NetProtoIsland.send.sendNetCfg}
    NetProtoIsland.dispatch[116]={onReceive = NetProtoIsland.recive.setPlayerCurrLook4WorldPage, send = NetProtoIsland.send.setPlayerCurrLook4WorldPage}
    NetProtoIsland.dispatch[253]={onReceive = NetProtoIsland.recive.getTechs, send = NetProtoIsland.send.getTechs}
    NetProtoIsland.dispatch[62]={onReceive = NetProtoIsland.recive.onResChg, send = NetProtoIsland.send.onResChg}
    NetProtoIsland.dispatch[88]={onReceive = NetProtoIsland.recive.moveCity, send = NetProtoIsland.send.moveCity}
    NetProtoIsland.dispatch[221]={onReceive = NetProtoIsland.recive.sendChat, send = NetProtoIsland.send.sendChat}
    NetProtoIsland.dispatch[69]={onReceive = NetProtoIsland.recive.newTile, send = NetProtoIsland.send.newTile}
    NetProtoIsland.dispatch[74]={onReceive = NetProtoIsland.recive.getMapDataByPageIdx, send = NetProtoIsland.send.getMapDataByPageIdx}
    NetProtoIsland.dispatch[72]={onReceive = NetProtoIsland.recive.onPlayerChg, send = NetProtoIsland.send.onPlayerChg}
    NetProtoIsland.dispatch[194]={onReceive = NetProtoIsland.recive.deleteMail, send = NetProtoIsland.send.deleteMail}
    NetProtoIsland.dispatch[196]={onReceive = NetProtoIsland.recive.receiveRewardMail, send = NetProtoIsland.send.receiveRewardMail}
    NetProtoIsland.dispatch[190]={onReceive = NetProtoIsland.recive.replyMail, send = NetProtoIsland.send.replyMail}
    NetProtoIsland.dispatch[129]={onReceive = NetProtoIsland.recive.fleetAttackIsland, send = NetProtoIsland.send.fleetAttackIsland}
    NetProtoIsland.dispatch[137]={onReceive = NetProtoIsland.recive.sendEndAttackIsland, send = NetProtoIsland.send.sendEndAttackIsland}
    NetProtoIsland.dispatch[47]={onReceive = NetProtoIsland.recive.newBuilding, send = NetProtoIsland.send.newBuilding}
    NetProtoIsland.dispatch[189]={onReceive = NetProtoIsland.recive.getMails, send = NetProtoIsland.send.getMails}
    NetProtoIsland.dispatch[110]={onReceive = NetProtoIsland.recive.getFleet, send = NetProtoIsland.send.getFleet}
    NetProtoIsland.dispatch[60]={onReceive = NetProtoIsland.recive.getBuilding, send = NetProtoIsland.send.getBuilding}
    NetProtoIsland.dispatch[126]={onReceive = NetProtoIsland.recive.fleetBack, send = NetProtoIsland.send.fleetBack}
    NetProtoIsland.dispatch[65]={onReceive = NetProtoIsland.recive.logout, send = NetProtoIsland.send.logout}
    NetProtoIsland.dispatch[111]={onReceive = NetProtoIsland.recive.getAllFleets, send = NetProtoIsland.send.getAllFleets}
    NetProtoIsland.dispatch[192]={onReceive = NetProtoIsland.recive.readMail, send = NetProtoIsland.send.readMail}
    NetProtoIsland.dispatch[80]={onReceive = NetProtoIsland.recive.onFinishBuildingUpgrade, send = NetProtoIsland.send.onFinishBuildingUpgrade}
    NetProtoIsland.dispatch[73]={onReceive = NetProtoIsland.recive.heart, send = NetProtoIsland.send.heart}
    NetProtoIsland.dispatch[143]={onReceive = NetProtoIsland.recive.quitIslandBattle, send = NetProtoIsland.send.quitIslandBattle}
    NetProtoIsland.dispatch[139]={onReceive = NetProtoIsland.recive.sendStartAttackIsland, send = NetProtoIsland.send.sendStartAttackIsland}
    NetProtoIsland.dispatch[117]={onReceive = NetProtoIsland.recive.sendFleet, send = NetProtoIsland.send.sendFleet}
    NetProtoIsland.dispatch[207]={onReceive = NetProtoIsland.recive.receiveReward, send = NetProtoIsland.send.receiveReward}
    NetProtoIsland.dispatch[209]={onReceive = NetProtoIsland.recive.getRewardInfor, send = NetProtoIsland.send.getRewardInfor}
    NetProtoIsland.dispatch[255]={onReceive = NetProtoIsland.recive.upLevTechImm, send = NetProtoIsland.send.upLevTechImm}
    NetProtoIsland.dispatch[250]={onReceive = NetProtoIsland.recive.upLevTech, send = NetProtoIsland.send.upLevTech}
    NetProtoIsland.dispatch[140]={onReceive = NetProtoIsland.recive.sendPrepareAttackIsland, send = NetProtoIsland.send.sendPrepareAttackIsland}
    NetProtoIsland.dispatch[227]={onReceive = NetProtoIsland.recive.getPlayerSimple, send = NetProtoIsland.send.getPlayerSimple}
    NetProtoIsland.dispatch[219]={onReceive = NetProtoIsland.recive.onChatChg, send = NetProtoIsland.send.onChatChg}
    NetProtoIsland.dispatch[89]={onReceive = NetProtoIsland.recive.onMyselfCityChg, send = NetProtoIsland.send.onMyselfCityChg}
    NetProtoIsland.dispatch[257]={onReceive = NetProtoIsland.recive.summonMagic, send = NetProtoIsland.send.summonMagic}
    NetProtoIsland.dispatch[252]={onReceive = NetProtoIsland.recive.onTechChg, send = NetProtoIsland.send.onTechChg}
    NetProtoIsland.dispatch[222]={onReceive = NetProtoIsland.recive.getChats, send = NetProtoIsland.send.getChats}
    NetProtoIsland.dispatch[213]={onReceive = NetProtoIsland.recive.useItem, send = NetProtoIsland.send.useItem}
    NetProtoIsland.dispatch[260]={onReceive = NetProtoIsland.recive.summonMagicSpeedUp, send = NetProtoIsland.send.summonMagicSpeedUp}
    NetProtoIsland.dispatch[71]={onReceive = NetProtoIsland.recive.onBuildingChg, send = NetProtoIsland.send.onBuildingChg}
    NetProtoIsland.dispatch[199]={onReceive = NetProtoIsland.recive.getReportResult, send = NetProtoIsland.send.getReportResult}
    NetProtoIsland.dispatch[152]={onReceive = NetProtoIsland.recive.onBattleBuildingDie, send = NetProtoIsland.send.onBattleBuildingDie}
    NetProtoIsland.dispatch[57]={onReceive = NetProtoIsland.recive.onFinishBuildOneShip, send = NetProtoIsland.send.onFinishBuildOneShip}
    NetProtoIsland.dispatch[42]={onReceive = NetProtoIsland.recive.getUnitsInBuilding, send = NetProtoIsland.send.getUnitsInBuilding}
    NetProtoIsland.dispatch[66]={onReceive = NetProtoIsland.recive.buildShip, send = NetProtoIsland.send.buildShip}
    NetProtoIsland.dispatch[200]={onReceive = NetProtoIsland.recive.getReportDetail, send = NetProtoIsland.send.getReportDetail}
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
    return NetProtoIsland

