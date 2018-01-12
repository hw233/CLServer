-- 属性配制相关
local skynet = require "skynet"
require "skynet.manager"    -- import skynet.register
local sharedata = require "skynet.sharedata"
require("CLUtl")

local command = {}

local sharedataKeys = {
    tablesdesign = "__tablesdesign__", -- 表设计
}
--==========================================
--==========================================
local function init()
    -- 加载表配制
    local tablesdesign = {}
    local path = assert(skynet.getenv("projectPath"))
    path = path .. "dbDesign/"
    print(path)
    local tables = CLUtl.getFiles(path, "lua")
    for i, v in ipairs(tables) do
        local t = dofile(path .. v );
        if tablesdesign[t.name] then
            skynet.error();
        else
            tablesdesign[t.name] = t;
        end
    end
    sharedata.new(sharedataKeys.tablesdesign, tablesdesign);

end

--==========================================
--==========================================
-- 取得共享数据，可以传多个key
function command.GET(key1, ...)
    local d = sharedata.query(key1)
    local keys = {...}
    if d then
        if #keys > 0 then
            local sd = d;
            for i, k in ipairs(keys) do
                sd = sd[k]
                if sd == nil then
                    return nil;
                end
            end
            return sd;
        else
            return d;
        end
    end
    return nil
end

-- 取得表的定义配制
function command.GETTABLESCFG(tableName)
    return command.GET(sharedataKeys.tablesdesign, tableName)
end

--==========================================
--==========================================
skynet.start(function()
    init();

    skynet.dispatch("lua", function(session, address, cmd, ...)
        cmd = cmd:upper()
        local f = command[cmd]
        if f then
            skynet.ret(skynet.pack(f(...)))
        else
            error(string.format("Unknown command %s", tostring(cmd)))
        end
    end)

    skynet.register "cfgattr"
end)
