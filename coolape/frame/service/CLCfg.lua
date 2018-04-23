-- 属性配制相关
local skynet = require "skynet"
require "skynet.manager"    -- import skynet.register
local sharedata = require "skynet.sharedata"
require("CLUtl")
require("fileEx")
require("CLGlobal")
---@type json
local json = require("json")

local command = {}

local sharedataKeys = {
    tablesdesign = "__tablesdesign__", -- 表设计
    dataCfg = "__dataCfg__", -- 数据配制
}
--==========================================
--==========================================
local function init()
    -- 加载表配制
    local tablesdesign = {}
    local path = assert(skynet.getenv("projectPath"))
    path = path .. "dbDesign/"
    local tables = fileEx.getFiles(path, "lua")
    for i, v in ipairs(tables) do
        local t = dofile(path .. v )
        if tablesdesign[t.name] then
            printe("allready had load the table design==" .. t.name)
        else
            tablesdesign[t.name] = t
        end
    end
    sharedata.new(sharedataKeys.tablesdesign, tablesdesign)

    -- 加载配制数据
    local cfgDatas = {};
    path = assert(skynet.getenv("projectPath"))
    path = path .. "cfg/"
    local files = fileEx.getFiles(path, "json") or {}
    local jsonstr
    local list
    local cfgName
    for i, fileName in ipairs(files) do
        print("load cfg fileName==" .. fileName)
        local cfg = {}
        jsonstr = fileEx.readAll(path .. fileName )
        list = json.decode(jsonstr)
        if #list < 2 then
            printe("load data cfg error.path=[" .. path .. fileName .. "]")
        else
            local keys = list[1] -- 第一行是字段名
            local count = #list
            local cellList
            for i = 2, count do
                cellList = list[i]
                local cell = {}
                for j, v in ipairs(cellList) do
                    cell[keys[j]] = v
                end
                if cell.ID then
                    cfg[cell.ID] = cell
                else
                    table.insert(cfg, cell)
                end
            end
        end
        cfgName = string.gsub(fileName, "%.json", "")
        cfgDatas[cfgName] = cfg
    end
    sharedata.new(sharedataKeys.dataCfg, cfgDatas)
end

--==========================================
--==========================================
-- 取得共享数据，可以传多个key
function command.GET(key1, ...)
    local d = sharedata.query(key1)
    local keys = { ... }
    if d then
        if #keys > 0 then
            local sd = d
            for i, k in ipairs(keys) do
                sd = sd[k]
                if sd == nil then
                    return nil
                end
            end
            return sd
        else
            return d
        end
    end
    return nil
end

-- 取得表的定义配制
function command.GETTABLESCFG(tableName)
    return command.GET(sharedataKeys.tablesdesign, tableName)
end

-- 取得数据配制，可以传多个key
function command.GETDATACFG(cfgName, ...)
    return command.GET(sharedataKeys.dataCfg, cfgName, ...)
end

--==========================================
--==========================================
skynet.start(function()
    init()

    skynet.dispatch("lua", function(session, address, cmd, ...)
        cmd = cmd:upper()
        local f = command[cmd]
        if f then
            skynet.ret(skynet.pack(f(...)))
        else
            error(string.format("Unknown command %s", tostring(cmd)))
        end
    end)

    skynet.register "CLCfg"
end)
