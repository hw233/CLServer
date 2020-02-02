do
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
    ---@field public fidx number 所属舰队idx int
    ---@field public id number 配置数量的id int
    ---@field public bidx number 所属建筑idx int
    ---@field public num number 数量 int
    NetProtoIsland.ST_unitInfor = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[24] =  BioUtl.number2bio(m.lev)  -- 等级(大部分情况下lev可能是0，而是由科技决定，但是联盟里的兵等级是有值的) int int
            r[101] =  BioUtl.number2bio(m.fidx)  -- 所属舰队idx int int
            r[99] =  BioUtl.number2bio(m.id)  -- 配置数量的id int int
            r[100] =  BioUtl.number2bio(m.bidx)  -- 所属建筑idx int int
            r[67] =  BioUtl.number2bio(m.num)  -- 数量 int int
            return r
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.lev = m[24] --  int
            r.fidx = m[101] --  int
            r.id = m[99] --  int
            r.bidx = m[100] --  int
            r.num = m[67] --  int
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
    ---@field public fidx number 舰队idx
    ---@field public cidx number 主城idx
    ---@field public val1 number 值1
    ---@field public type number 地块类型 3：玩家，4：npc
    ---@field public state number 状态  1:正常; int
    ---@field public name string 名称
    ---@field public attrid number 配置id
    NetProtoIsland.ST_mapCell = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[16] =  BioUtl.number2bio(m.idx)  -- 网格index int
            r[13] =  BioUtl.number2bio(m.pageIdx)  -- 所在屏的index int
            r[22] =  BioUtl.number2bio(m.val2)  -- 值2 int
            r[21] =  BioUtl.number2bio(m.val3)  -- 值3 int
            r[24] =  BioUtl.number2bio(m.lev)  -- 等级 int
            r[101] =  BioUtl.number2bio(m.fidx)  -- 舰队idx int
            r[18] =  BioUtl.number2bio(m.cidx)  -- 主城idx int
            r[29] =  BioUtl.number2bio(m.val1)  -- 值1 int
            r[30] =  BioUtl.number2bio(m.type)  -- 地块类型 3：玩家，4：npc int
            r[28] =  BioUtl.number2bio(m.state)  -- 状态  1:正常; int int
            r[35] = m.name  -- 名称 string
            r[17] =  BioUtl.number2bio(m.attrid)  -- 配置id int
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
            r.fidx = m[101] --  int
            r.cidx = m[18] --  int
            r.val1 = m[29] --  int
            r.type = m[30] --  int
            r.state = m[28] --  int
            r.name = m[35] --  string
            r.attrid = m[17] --  int
            return r
        end,
    }
    ---@class NetProtoIsland.ST_battleresult 战斗结果
    ---@field public exp number 获得的经验
    ---@field public lootRes resInfor 掠夺的资源
    ---@field public usedUnits table 进攻方投入的战斗单元
    ---@field public iswin useData 胜负
    ---@field public star number 星级
    NetProtoIsland.ST_battleresult = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[132] =  BioUtl.number2bio(m.exp)  -- 获得的经验 int
            r[131] = NetProtoIsland.ST_resInfor.toMap(m.lootRes) -- 掠夺的资源
            r[133] = NetProtoIsland._toList(NetProtoIsland.ST_unitInfor, m.usedUnits)  -- 进攻方投入的战斗单元
            r[134] = m.iswin  -- 胜负 boolean
            r[135] =  BioUtl.number2bio(m.star)  -- 星级 int
            return r
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.exp = m[132] --  int
            r.lootRes = NetProtoIsland.ST_resInfor.parse(m[131]) --  table
            r.usedUnits = NetProtoIsland._parseList(NetProtoIsland.ST_unitInfor, m[133])  -- 进攻方投入的战斗单元
            r.iswin = m[134] --  boolean
            r.star = m[135] --  int
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
    ---@field public status number 状态 1:正常; int
    ---@field public lev number 等级 int
    ---@field public name string 名称
    ---@field public buildings table 建筑信息 key=idx, map
    ---@field public pos number 城所在世界grid的index int
    ---@field public pidx number 玩家idx int
    NetProtoIsland.ST_city = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[16] =  BioUtl.number2bio(m.idx)  -- 唯一标识 int int
            r[144] =  BioUtl.number2bio(m.protectEndTime)  -- 免战结束时间 int
            r[34] = NetProtoIsland._toMap(NetProtoIsland.ST_tile, m.tiles)  -- 地块信息 key=idx, map
            r[37] =  BioUtl.number2bio(m.status)  -- 状态 1:正常; int int
            r[24] =  BioUtl.number2bio(m.lev)  -- 等级 int int
            r[35] = m.name  -- 名称 string
            r[36] = NetProtoIsland._toMap(NetProtoIsland.ST_building, m.buildings)  -- 建筑信息 key=idx, map
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
            r.status = m[37] --  int
            r.lev = m[24] --  int
            r.name = m[35] --  string
            r.buildings = NetProtoIsland._parseMap(NetProtoIsland.ST_building, m[36])  -- 建筑信息 key=idx, map
            r.pos = m[19] --  int
            r.pidx = m[38] --  int
            return r
        end,
    }
    ---@class NetProtoIsland.ST_fleetinfor 舰队数据
    ---@field public idx number 唯一标识舰队idx
    ---@field public curpos number 当前所在世界grid的index
    ---@field public status number 状态 none = 1, -- 无;moving = 2, -- 航行中;docked = 3, -- 停泊在港口;stay = 4, -- 停留在海面;fighting = 5 -- 正在战斗中
    ---@field public pname string 玩家名
    ---@field public units table 战斗单元列表
    ---@field public frompos number 出征的开始所在世界grid的index
    ---@field public arrivetime number 到达时间
    ---@field public cidx number 城市idx
    ---@field public deadtime number 沉没的时间
    ---@field public fromposv3 vector3 坐标
    ---@field public topos number 出征的目地所在世界grid的index
    ---@field public task number 执行任务类型 idel = 1, -- 待命状态;voyage = 2, -- 出征;back = 3, -- 返航;attack = 4 -- 攻击
    ---@field public name string 名称
    NetProtoIsland.ST_fleetinfor = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[16] =  BioUtl.number2bio(m.idx)  -- 唯一标识舰队idx int
            r[113] =  BioUtl.number2bio(m.curpos)  -- 当前所在世界grid的index int
            r[37] =  BioUtl.number2bio(m.status)  -- 状态 none = 1, -- 无;moving = 2, -- 航行中;docked = 3, -- 停泊在港口;stay = 4, -- 停留在海面;fighting = 5 -- 正在战斗中 int
            r[127] = m.pname  -- 玩家名 string
            r[103] = NetProtoIsland._toList(NetProtoIsland.ST_unitInfor, m.units)  -- 战斗单元列表
            r[114] =  BioUtl.number2bio(m.frompos)  -- 出征的开始所在世界grid的index int
            r[118] =  BioUtl.number2bio(m.arrivetime)  -- 到达时间 int
            r[18] =  BioUtl.number2bio(m.cidx)  -- 城市idx int
            r[104] =  BioUtl.number2bio(m.deadtime)  -- 沉没的时间 int
            r[122] = NetProtoIsland.ST_vector3.toMap(m.fromposv3) -- 坐标
            r[115] =  BioUtl.number2bio(m.topos)  -- 出征的目地所在世界grid的index int
            r[119] =  BioUtl.number2bio(m.task)  -- 执行任务类型 idel = 1, -- 待命状态;voyage = 2, -- 出征;back = 3, -- 返航;attack = 4 -- 攻击 int
            r[35] = m.name  -- 名称 string
            return r
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[16] --  int
            r.curpos = m[113] --  int
            r.status = m[37] --  int
            r.pname = m[127] --  string
            r.units = NetProtoIsland._parseList(NetProtoIsland.ST_unitInfor, m[103])  -- 战斗单元列表
            r.frompos = m[114] --  int
            r.arrivetime = m[118] --  int
            r.cidx = m[18] --  int
            r.deadtime = m[104] --  int
            r.fromposv3 = NetProtoIsland.ST_vector3.parse(m[122]) --  table
            r.topos = m[115] --  int
            r.task = m[119] --  int
            r.name = m[35] --  string
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
    ---@class NetProtoIsland.ST_dockyardShips 造船厂的舰船信息
    ---@field public ships table 舰船数据
    ---@field public buildingIdx number 造船厂的idx
    NetProtoIsland.ST_dockyardShips = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[102] = NetProtoIsland._toList(NetProtoIsland.ST_unitInfor, m.ships)  -- 舰船数据
            r[15] =  BioUtl.number2bio(m.buildingIdx)  -- 造船厂的idx int
            return r
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.ships = NetProtoIsland._parseList(NetProtoIsland.ST_unitInfor, m[102])  -- 舰船数据
            r.buildingIdx = m[15] --  int
            return r
        end,
    }
    ---@class NetProtoIsland.ST_player 用户信息
    ---@field public idx number 唯一标识 int
    ---@field public unionidx number 联盟id int
    ---@field public status number 状态 1：正常 int
    ---@field public cityidx number 城池id int
    ---@field public lev number 等级 long
    ---@field public attacking useData 正在攻击玩家的岛屿
    ---@field public name string 名字
    ---@field public exp number 经验值 long
    ---@field public diam number 钻石 long
    ---@field public diam4reward number 钻石 long
    ---@field public beingattacked useData 正在被玩家攻击
    NetProtoIsland.ST_player = {
        toMap = function(m)
            local r = {}
            if m == nil then return r end
            r[16] =  BioUtl.number2bio(m.idx)  -- 唯一标识 int int
            r[41] =  BioUtl.number2bio(m.unionidx)  -- 联盟id int int
            r[37] =  BioUtl.number2bio(m.status)  -- 状态 1：正常 int int
            r[40] =  BioUtl.number2bio(m.cityidx)  -- 城池id int int
            r[24] =  BioUtl.number2bio(m.lev)  -- 等级 long int
            r[146] = m.attacking  -- 正在攻击玩家的岛屿 boolean
            r[35] = m.name  -- 名字 string
            r[132] =  BioUtl.number2bio(m.exp)  -- 经验值 long int
            r[39] =  BioUtl.number2bio(m.diam)  -- 钻石 long int
            r[136] =  BioUtl.number2bio(m.diam4reward)  -- 钻石 long int
            r[147] = m.beingattacked  -- 正在被玩家攻击 boolean
            return r
        end,
        parse = function(m)
            local r = {}
            if m == nil then return r end
            r.idx = m[16] --  int
            r.unionidx = m[41] --  int
            r.status = m[37] --  int
            r.cityidx = m[40] --  int
            r.lev = m[24] --  int
            r.attacking = m[146] --  boolean
            r.name = m[35] --  string
            r.exp = m[132] --  int
            r.diam = m[39] --  int
            r.diam4reward = m[136] --  int
            r.beingattacked = m[147] --  boolean
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
    --==============================
    ---@class NetProtoIsland.RC_Base
    ---@field public cmd number
    ---@field public __session__ string

    NetProtoIsland.recive = {
    -- 取得造船厂所有舰艇列表
    ---@class NetProtoIsland.RC_getShipsByBuildingIdx : NetProtoIsland.RC_Base
    ---@field public buildingIdx  造船厂的idx int
    getShipsByBuildingIdx = function(map)
        local ret = {}
        ret.cmd = "getShipsByBuildingIdx"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.buildingIdx = map[15] -- 造船厂的idx int
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
    ---@field public deviceID  机器码
    ---@field public isEditMode  编辑模式
    login = function(map)
        local ret = {}
        ret.cmd = "login"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        ret.uidx = map[49] -- 用户id
        ret.channel = map[50] -- 渠道号
        ret.deviceID = map[51] -- 机器码
        ret.isEditMode = map[52] -- 编辑模式
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
    -- 准备攻击岛
    ---@class NetProtoIsland.RC_sendPrepareAttackIsland : NetProtoIsland.RC_Base
    sendPrepareAttackIsland = function(map)
        local ret = {}
        ret.cmd = "sendPrepareAttackIsland"
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
    -- 资源变化时推送
    ---@class NetProtoIsland.RC_onResChg : NetProtoIsland.RC_Base
    onResChg = function(map)
        local ret = {}
        ret.cmd = "onResChg"
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
    -- 建筑变化时推送
    ---@class NetProtoIsland.RC_onBuildingChg : NetProtoIsland.RC_Base
    onBuildingChg = function(map)
        local ret = {}
        ret.cmd = "onBuildingChg"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
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
    -- 自己的城变化时推送
    ---@class NetProtoIsland.RC_onMyselfCityChg : NetProtoIsland.RC_Base
    onMyselfCityChg = function(map)
        local ret = {}
        ret.cmd = "onMyselfCityChg"
        ret.__session__ = map[1] or map["1"]
        ret.callback = map[3]
        return ret
    end,
    }
    --==============================
    NetProtoIsland.send = {
    getShipsByBuildingIdx = function(mapOrig, retInfor, dockyardShips) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 42
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[43] = NetProtoIsland.ST_dockyardShips.toMap(dockyardShips); -- 造船厂的idx int
        return ret
    end,
    sendEndAttackIsland = function(mapOrig, retInfor, battleresult) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 137
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[138] = NetProtoIsland.ST_battleresult.toMap(battleresult); -- 战斗结果
        return ret
    end,
    newBuilding = function(mapOrig, retInfor, building) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 47
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[45] = NetProtoIsland.ST_building.toMap(building); -- 建筑信息对象
        return ret
    end,
    getFleet = function(mapOrig, retInfor, fleetinfor) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 110
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[107] = NetProtoIsland.ST_fleetinfor.toMap(fleetinfor); -- 舰队信息
        return ret
    end,
    getBuilding = function(mapOrig, retInfor, building) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 60
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[45] = NetProtoIsland.ST_building.toMap(building); -- 建筑信息对象
        return ret
    end,
    rmTile = function(mapOrig, retInfor, idx) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 61
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        if type(idx) == "number" then
            ret[16] = BioUtl.number2bio(idx); -- 被移除地块的idx int
        else
            ret[16] = idx; -- 被移除地块的idx int
        end
        return ret
    end,
    fleetBack = function(mapOrig, retInfor, fleetinfor) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 126
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[107] = NetProtoIsland.ST_fleetinfor.toMap(fleetinfor); -- 舰队信息
        return ret
    end,
    onMapCellChg = function(mapOrig, retInfor, mapCell, isRemove) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 86
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[87] = NetProtoIsland.ST_mapCell.toMap(mapCell); -- 地块
        if type(isRemove) == "number" then
            ret[98] = BioUtl.number2bio(isRemove); -- 是否是删除
        else
            ret[98] = isRemove; -- 是否是删除
        end
        return ret
    end,
    moveBuilding = function(mapOrig, retInfor, building) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 64
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[45] = NetProtoIsland.ST_building.toMap(building); -- 建筑信息
        return ret
    end,
    logout = function(mapOrig, retInfor) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 65
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        return ret
    end,
    getAllFleets = function(mapOrig, retInfor, fleetinfors) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 111
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[112] = NetProtoIsland._toList(NetProtoIsland.ST_fleetinfor, fleetinfors)  -- 舰队列表
        return ret
    end,
    upLevBuildingImm = function(mapOrig, retInfor, building) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 68
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[45] = NetProtoIsland.ST_building.toMap(building); -- 建筑信息
        return ret
    end,
    fleetAttackFleet = function(mapOrig, retInfor, mapCell, fleetinfor, fleetinfor2) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 130
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[87] = NetProtoIsland.ST_mapCell.toMap(mapCell); -- 被攻击方地块
        ret[107] = NetProtoIsland.ST_fleetinfor.toMap(fleetinfor); -- 被攻击方舰队数据
        ret[128] = NetProtoIsland.ST_fleetinfor.toMap(fleetinfor2); -- 进攻方舰队数据
        return ret
    end,
    onFinishBuildingUpgrade = function(mapOrig, retInfor, building) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 80
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[45] = NetProtoIsland.ST_building.toMap(building); -- 建筑信息
        return ret
    end,
    heart = function(mapOrig) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 73
        ret[3] = mapOrig and mapOrig.callback or nil
        return ret
    end,
    moveTile = function(mapOrig, retInfor, tile) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 76
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[70] = NetProtoIsland.ST_tile.toMap(tile); -- 地块信息
        return ret
    end,
    sendStartAttackIsland = function(mapOrig, retInfor, player, city, dockyardShipss, player2, fleetinfor, endTimeLimit) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 139
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[53] = NetProtoIsland.ST_player.toMap(player); -- 被攻击方玩家信息
        ret[54] = NetProtoIsland.ST_city.toMap(city); -- 被攻击方主城信息
        ret[91] = NetProtoIsland._toList(NetProtoIsland.ST_dockyardShips, dockyardShipss)  -- 被攻击方舰船数据
        ret[141] = NetProtoIsland.ST_player.toMap(player2); -- 攻击方玩家信息
        ret[107] = NetProtoIsland.ST_fleetinfor.toMap(fleetinfor); -- 进攻方舰队数据
        if type(endTimeLimit) == "number" then
            ret[145] = BioUtl.number2bio(endTimeLimit); -- 战斗限制时间
        else
            ret[145] = endTimeLimit; -- 战斗限制时间
        end
        return ret
    end,
    sendFleet = function(mapOrig, retInfor, fleetinfor, isRemove) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 117
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[107] = NetProtoIsland.ST_fleetinfor.toMap(fleetinfor); -- 舰队信息
        if type(isRemove) == "number" then
            ret[98] = BioUtl.number2bio(isRemove); -- 是否移除
        else
            ret[98] = isRemove; -- 是否移除
        end
        return ret
    end,
    upLevBuilding = function(mapOrig, retInfor, building) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 44
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[45] = NetProtoIsland.ST_building.toMap(building); -- 建筑信息
        return ret
    end,
    rmBuilding = function(mapOrig, retInfor, idx) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 46
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        if type(idx) == "number" then
            ret[16] = BioUtl.number2bio(idx); -- 被移除建筑的idx int
        else
            ret[16] = idx; -- 被移除建筑的idx int
        end
        return ret
    end,
    saveFleet = function(mapOrig, retInfor, fleetinfor) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 105
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[107] = NetProtoIsland.ST_fleetinfor.toMap(fleetinfor); -- 舰队信息
        return ret
    end,
    login = function(mapOrig, retInfor, player, city, systime, session) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 48
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[53] = NetProtoIsland.ST_player.toMap(player); -- 玩家信息
        ret[54] = NetProtoIsland.ST_city.toMap(city); -- 主城信息
        if type(systime) == "number" then
            ret[55] = BioUtl.number2bio(systime); -- 系统时间 long
        else
            ret[55] = systime; -- 系统时间 long
        end
        if type(session) == "number" then
            ret[56] = BioUtl.number2bio(session); -- 会话id
        else
            ret[56] = session; -- 会话id
        end
        return ret
    end,
    sendNetCfg = function(mapOrig, retInfor, netCfg, systime) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 81
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[82] = NetProtoIsland.ST_netCfg.toMap(netCfg); -- 网络协议解析配置
        if type(systime) == "number" then
            ret[55] = BioUtl.number2bio(systime); -- 系统时间 long
        else
            ret[55] = systime; -- 系统时间 long
        end
        return ret
    end,
    sendPrepareAttackIsland = function(mapOrig, retInfor, player, city, player2, city2, fleetinfor) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 140
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[53] = NetProtoIsland.ST_player.toMap(player); -- 被攻击方玩家信息
        ret[54] = NetProtoIsland.ST_city.toMap(city); -- 被攻击方主城信息
        ret[141] = NetProtoIsland.ST_player.toMap(player2); -- 攻击方玩家信息
        ret[142] = NetProtoIsland.ST_city.toMap(city2); -- 攻击方主城信息
        ret[107] = NetProtoIsland.ST_fleetinfor.toMap(fleetinfor); -- 进攻方舰队数据
        return ret
    end,
    setPlayerCurrLook4WorldPage = function(mapOrig, retInfor) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 116
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        return ret
    end,
    onResChg = function(mapOrig, retInfor, resInfor) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 62
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[63] = NetProtoIsland.ST_resInfor.toMap(resInfor); -- 资源信息
        return ret
    end,
    quitIslandBattle = function(mapOrig, retInfor) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 143
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        return ret
    end,
    moveCity = function(mapOrig, retInfor) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 88
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        return ret
    end,
    fleetAttackIsland = function(mapOrig, retInfor, fleetinfor) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 129
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[107] = NetProtoIsland.ST_fleetinfor.toMap(fleetinfor); -- 进攻方舰队数据
        return ret
    end,
    fleetDepart = function(mapOrig, retInfor, fleetinfor) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 108
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[107] = NetProtoIsland.ST_fleetinfor.toMap(fleetinfor); -- 舰队信息
        return ret
    end,
    newTile = function(mapOrig, retInfor, tile) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 69
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[70] = NetProtoIsland.ST_tile.toMap(tile); -- 地块信息对象
        return ret
    end,
    onBuildingChg = function(mapOrig, retInfor, building) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 71
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[45] = NetProtoIsland.ST_building.toMap(building); -- 建筑信息
        return ret
    end,
    onPlayerChg = function(mapOrig, retInfor, player) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 72
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[53] = NetProtoIsland.ST_player.toMap(player); -- 玩家信息
        return ret
    end,
    onFinishBuildOneShip = function(mapOrig, retInfor, buildingIdx, shipAttrID, shipNum) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 57
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        if type(buildingIdx) == "number" then
            ret[15] = BioUtl.number2bio(buildingIdx); -- 造船厂的idx int
        else
            ret[15] = buildingIdx; -- 造船厂的idx int
        end
        if type(shipAttrID) == "number" then
            ret[58] = BioUtl.number2bio(shipAttrID); -- 舰船的配置id
        else
            ret[58] = shipAttrID; -- 舰船的配置id
        end
        if type(shipNum) == "number" then
            ret[59] = BioUtl.number2bio(shipNum); -- 舰船的数量
        else
            ret[59] = shipNum; -- 舰船的数量
        end
        return ret
    end,
    buildShip = function(mapOrig, retInfor, building) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 66
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[45] = NetProtoIsland.ST_building.toMap(building); -- 造船厂信息
        return ret
    end,
    getMapDataByPageIdx = function(mapOrig, retInfor, mapPage, fleetinfors) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 74
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[75] = NetProtoIsland.ST_mapPage.toMap(mapPage); -- 在地图一屏数据 map
        ret[112] = NetProtoIsland._toList(NetProtoIsland.ST_fleetinfor, fleetinfors)  -- 舰队列表
        return ret
    end,
    collectRes = function(mapOrig, retInfor, resType, resVal, building) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 77
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        if type(resType) == "number" then
            ret[78] = BioUtl.number2bio(resType); -- 收集的资源类型 int
        else
            ret[78] = resType; -- 收集的资源类型 int
        end
        if type(resVal) == "number" then
            ret[79] = BioUtl.number2bio(resVal); -- 收集到的资源量 int
        else
            ret[79] = resVal; -- 收集到的资源量 int
        end
        ret[45] = NetProtoIsland.ST_building.toMap(building); -- 建筑信息
        return ret
    end,
    onMyselfCityChg = function(mapOrig, retInfor, city) -- mapOrig:客户端原始入参
        local ret = {}
        ret[0] = 89
        ret[3] = mapOrig and mapOrig.callback or nil
        ret[2] = NetProtoIsland.ST_retInfor.toMap(retInfor); -- 返回信息
        ret[54] = NetProtoIsland.ST_city.toMap(city); -- 主城信息
        return ret
    end,
    }
    --==============================
    NetProtoIsland.dispatch[42]={onReceive = NetProtoIsland.recive.getShipsByBuildingIdx, send = NetProtoIsland.send.getShipsByBuildingIdx, logicName = "cmd4city"}
    NetProtoIsland.dispatch[137]={onReceive = NetProtoIsland.recive.sendEndAttackIsland, send = NetProtoIsland.send.sendEndAttackIsland, logicName = "LDSWorld"}
    NetProtoIsland.dispatch[47]={onReceive = NetProtoIsland.recive.newBuilding, send = NetProtoIsland.send.newBuilding, logicName = "cmd4city"}
    NetProtoIsland.dispatch[110]={onReceive = NetProtoIsland.recive.getFleet, send = NetProtoIsland.send.getFleet, logicName = "LDSWorld"}
    NetProtoIsland.dispatch[60]={onReceive = NetProtoIsland.recive.getBuilding, send = NetProtoIsland.send.getBuilding, logicName = "cmd4city"}
    NetProtoIsland.dispatch[61]={onReceive = NetProtoIsland.recive.rmTile, send = NetProtoIsland.send.rmTile, logicName = "cmd4city"}
    NetProtoIsland.dispatch[126]={onReceive = NetProtoIsland.recive.fleetBack, send = NetProtoIsland.send.fleetBack, logicName = "LDSWorld"}
    NetProtoIsland.dispatch[86]={onReceive = NetProtoIsland.recive.onMapCellChg, send = NetProtoIsland.send.onMapCellChg, logicName = "LDSWorld"}
    NetProtoIsland.dispatch[64]={onReceive = NetProtoIsland.recive.moveBuilding, send = NetProtoIsland.send.moveBuilding, logicName = "cmd4city"}
    NetProtoIsland.dispatch[65]={onReceive = NetProtoIsland.recive.logout, send = NetProtoIsland.send.logout, logicName = "cmd4player"}
    NetProtoIsland.dispatch[111]={onReceive = NetProtoIsland.recive.getAllFleets, send = NetProtoIsland.send.getAllFleets, logicName = "LDSWorld"}
    NetProtoIsland.dispatch[68]={onReceive = NetProtoIsland.recive.upLevBuildingImm, send = NetProtoIsland.send.upLevBuildingImm, logicName = "cmd4city"}
    NetProtoIsland.dispatch[130]={onReceive = NetProtoIsland.recive.fleetAttackFleet, send = NetProtoIsland.send.fleetAttackFleet, logicName = "LDSWorld"}
    NetProtoIsland.dispatch[80]={onReceive = NetProtoIsland.recive.onFinishBuildingUpgrade, send = NetProtoIsland.send.onFinishBuildingUpgrade, logicName = "cmd4city"}
    NetProtoIsland.dispatch[73]={onReceive = NetProtoIsland.recive.heart, send = NetProtoIsland.send.heart, logicName = "cmd4com"}
    NetProtoIsland.dispatch[76]={onReceive = NetProtoIsland.recive.moveTile, send = NetProtoIsland.send.moveTile, logicName = "cmd4city"}
    NetProtoIsland.dispatch[139]={onReceive = NetProtoIsland.recive.sendStartAttackIsland, send = NetProtoIsland.send.sendStartAttackIsland, logicName = "LDSWorld"}
    NetProtoIsland.dispatch[117]={onReceive = NetProtoIsland.recive.sendFleet, send = NetProtoIsland.send.sendFleet, logicName = ""}
    NetProtoIsland.dispatch[44]={onReceive = NetProtoIsland.recive.upLevBuilding, send = NetProtoIsland.send.upLevBuilding, logicName = "cmd4city"}
    NetProtoIsland.dispatch[46]={onReceive = NetProtoIsland.recive.rmBuilding, send = NetProtoIsland.send.rmBuilding, logicName = "cmd4city"}
    NetProtoIsland.dispatch[105]={onReceive = NetProtoIsland.recive.saveFleet, send = NetProtoIsland.send.saveFleet, logicName = "LDSWorld"}
    NetProtoIsland.dispatch[48]={onReceive = NetProtoIsland.recive.login, send = NetProtoIsland.send.login, logicName = "cmd4player"}
    NetProtoIsland.dispatch[81]={onReceive = NetProtoIsland.recive.sendNetCfg, send = NetProtoIsland.send.sendNetCfg, logicName = ""}
    NetProtoIsland.dispatch[140]={onReceive = NetProtoIsland.recive.sendPrepareAttackIsland, send = NetProtoIsland.send.sendPrepareAttackIsland, logicName = "LDSWorld"}
    NetProtoIsland.dispatch[116]={onReceive = NetProtoIsland.recive.setPlayerCurrLook4WorldPage, send = NetProtoIsland.send.setPlayerCurrLook4WorldPage, logicName = "LDSWorld"}
    NetProtoIsland.dispatch[62]={onReceive = NetProtoIsland.recive.onResChg, send = NetProtoIsland.send.onResChg, logicName = "cmd4city"}
    NetProtoIsland.dispatch[143]={onReceive = NetProtoIsland.recive.quitIslandBattle, send = NetProtoIsland.send.quitIslandBattle, logicName = "LDSWorld"}
    NetProtoIsland.dispatch[88]={onReceive = NetProtoIsland.recive.moveCity, send = NetProtoIsland.send.moveCity, logicName = "LDSWorld"}
    NetProtoIsland.dispatch[129]={onReceive = NetProtoIsland.recive.fleetAttackIsland, send = NetProtoIsland.send.fleetAttackIsland, logicName = "LDSWorld"}
    NetProtoIsland.dispatch[108]={onReceive = NetProtoIsland.recive.fleetDepart, send = NetProtoIsland.send.fleetDepart, logicName = "LDSWorld"}
    NetProtoIsland.dispatch[69]={onReceive = NetProtoIsland.recive.newTile, send = NetProtoIsland.send.newTile, logicName = "cmd4city"}
    NetProtoIsland.dispatch[71]={onReceive = NetProtoIsland.recive.onBuildingChg, send = NetProtoIsland.send.onBuildingChg, logicName = "cmd4city"}
    NetProtoIsland.dispatch[72]={onReceive = NetProtoIsland.recive.onPlayerChg, send = NetProtoIsland.send.onPlayerChg, logicName = "cmd4player"}
    NetProtoIsland.dispatch[57]={onReceive = NetProtoIsland.recive.onFinishBuildOneShip, send = NetProtoIsland.send.onFinishBuildOneShip, logicName = "cmd4city"}
    NetProtoIsland.dispatch[66]={onReceive = NetProtoIsland.recive.buildShip, send = NetProtoIsland.send.buildShip, logicName = "cmd4city"}
    NetProtoIsland.dispatch[74]={onReceive = NetProtoIsland.recive.getMapDataByPageIdx, send = NetProtoIsland.send.getMapDataByPageIdx, logicName = "LDSWorld"}
    NetProtoIsland.dispatch[77]={onReceive = NetProtoIsland.recive.collectRes, send = NetProtoIsland.send.collectRes, logicName = "cmd4city"}
    NetProtoIsland.dispatch[89]={onReceive = NetProtoIsland.recive.onMyselfCityChg, send = NetProtoIsland.send.onMyselfCityChg, logicName = "cmd4city"}
    --==============================
    NetProtoIsland.cmds = {
        getShipsByBuildingIdx = "getShipsByBuildingIdx", -- 取得造船厂所有舰艇列表,
        sendEndAttackIsland = "sendEndAttackIsland", -- 结束攻击岛,
        newBuilding = "newBuilding", -- 新建建筑,
        getFleet = "getFleet", -- 取得舰队信息,
        getBuilding = "getBuilding", -- 取得建筑,
        rmTile = "rmTile", -- 移除地块,
        fleetBack = "fleetBack", -- 舰队返航,
        onMapCellChg = "onMapCellChg", -- 当地块发生变化时推送,
        moveBuilding = "moveBuilding", -- 移动建筑,
        logout = "logout", -- 登出,
        getAllFleets = "getAllFleets", -- 取得所有舰队信息,
        upLevBuildingImm = "upLevBuildingImm", -- 立即升级建筑,
        fleetAttackFleet = "fleetAttackFleet", -- 舰队攻击舰队,
        onFinishBuildingUpgrade = "onFinishBuildingUpgrade", -- 建筑升级完成,
        heart = "heart", -- 心跳,
        moveTile = "moveTile", -- 移动地块,
        sendStartAttackIsland = "sendStartAttackIsland", -- 开始攻击岛,
        sendFleet = "sendFleet", -- 推送舰队信息,
        upLevBuilding = "upLevBuilding", -- 升级建筑,
        rmBuilding = "rmBuilding", -- 移除建筑,
        saveFleet = "saveFleet", -- 新建、更新舰队,
        login = "login", -- 登陆,
        sendNetCfg = "sendNetCfg", -- 网络协议配置,
        sendPrepareAttackIsland = "sendPrepareAttackIsland", -- 准备攻击岛,
        setPlayerCurrLook4WorldPage = "setPlayerCurrLook4WorldPage", -- 设置用户当前正在查看大地图的哪一页，便于后续推送数据,
        onResChg = "onResChg", -- 资源变化时推送,
        quitIslandBattle = "quitIslandBattle", -- 主动离开攻击岛,
        moveCity = "moveCity", -- 搬迁,
        fleetAttackIsland = "fleetAttackIsland", -- 舰队攻击岛屿,
        fleetDepart = "fleetDepart", -- 舰队出征,
        newTile = "newTile", -- 新建地块,
        onBuildingChg = "onBuildingChg", -- 建筑变化时推送,
        onPlayerChg = "onPlayerChg", -- 玩家信息变化时推送,
        onFinishBuildOneShip = "onFinishBuildOneShip", -- 当完成建造部分舰艇的通知,
        buildShip = "buildShip", -- 造船,
        getMapDataByPageIdx = "getMapDataByPageIdx", -- 取得一屏的在地图数据,
        collectRes = "collectRes", -- 收集资源,
        onMyselfCityChg = "onMyselfCityChg", -- 自己的城变化时推送
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
            return nil;
        end
        cmd = tonumber(cmd)
        local dis = NetProtoIsland.dispatch[cmd]
        if dis == nil then
            skynet.error("get protocol cfg is nil")
            return nil;
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
end
