---@class USLanguage 语言（国际化）(单一服务)
local skynet = require "skynet"
require "skynet.manager" -- import skynet.register
require("public.include")
require("Errcode")
require("db.dblanguage")
require("db.dbplayer")
local logic = {}
local CMD = {}
local contentFuncMap = {}

logic.init = function()
end

---public 取得语种类型
logic.getLanguageTypes = function()
    return skynet.call("CLCfg", "lua", "getDataCfg", "DBCFLanguageTypeData")
end

---public 语言key是新key
logic.isNewKey = function(language, key)
    local lan = dblanguage.instanse(language, key)
    if lan:isEmpty() then
        lan:release()
        return true
    end
    lan:release()
    return false
end

logic.get = function(language, key)
    local lan = dblanguage.instanse(language, key)
    if lan:isEmpty() then
        lan:release()
        return key
    end
    local content = lan:get_content()
    lan:release()
    lan = nil
    return content
end

logic.set = function(language, key, content)
    local val = {
        [dblanguage.keys.language] = language,
        [dblanguage.keys.ckey] = key,
        [dblanguage.keys.content] = content
    }
    local lan = dblanguage.instanse(language, key)
    if lan:isEmpty() then
        lan = dblanguage.new()
        lan:init(val, true)
    else
        lan:refreshData(val)
    end
    return lan:release(true)
end

logic.del = function(language, key)
    local lan = dblanguage.instanse(language, key)
    lan:delete()
    lan = nil
end

logic.delByKey = function(key)
    local list = dblanguage.getListByckey(key)
    for i, v in ipairs(list) do
        logic.del(v[dblanguage.keys.language], v[dblanguage.keys.ckey])
    end
end

---public 查询
logic.seek = function(seekStr, isAll)
    local sql =
        "select * from " ..
        dblanguage.name .. " where (ckey  like '%" .. seekStr .. "%'" .. " or content like '%" .. seekStr .. "%')"
    if not isAll then
        sql = sql .. " and language<>-1;"
    end
    local list = skynet.call("CLMySQL", "lua", "exesql", sql)
    if list and list.errno then
        skynet.error("[dblanguage.seek] sql error==" .. sql)
        return {}
    end
    ---@type dblanguage
    local lan
    for i, v in ipairs(list) do
        lan = dblanguage.instanse(v[dblanguage.keys.language], v[dblanguage.keys.ckey])
        if not lan:isEmpty() then
            -- 取得缓存中的数据
            list[i] = lan:value2copy()
        end
        lan:release()
    end
    return list or {}
end

--============================================================
logic.init()
--============================================================
skynet.start(
    function()
        skynet.dispatch(
            "lua",
            function(_, _, command, ...)
                local f = CMD[command] or logic[command]
                skynet.ret(skynet.pack(f(...)))
            end
        )

        skynet.register "USLanguage"
    end
)
