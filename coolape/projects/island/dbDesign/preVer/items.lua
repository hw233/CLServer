local tab = {
    name = "items",
    desc = "道具物品",
    columns = {
        {"idx", "int(11) NOT NULL", "唯一标识"},
        {"pidx", "int(11) NOT NULL", "玩家唯一标识"},
        {"id", "int(11) NOT NULL", "对应的id"},
        {
            "type",
            "TINYINT NOT NULL",
            "类型，1：资源、经验值等（领奖就直接把数值加上），2：加速(建筑、造船、科技)，3：护盾4：碎片(海怪碎片)，5：图纸，6：舰船，7：复活药水(建筑、海怪)99：宝箱(嵌套礼包)"
        },
        {"num", "int(11)", "数量"}
    },
    primaryKey = {"idx", "pidx"},
    cacheKey = {"idx"}, -- 缓存key
    groupKey = {{"pidx"}}, -- 组key
    defaultData = {}, -- 初始数据
    needBak = true -- 需要备份
}

return tab
