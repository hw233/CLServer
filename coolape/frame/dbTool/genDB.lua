﻿-- 数据库 工具
--[[ run cmd
./3rd/lua/lua coolape/frame/dbTool/genDB.lua [输入目录] [输出目录]
./3rd/lua/lua coolape/frame/dbTool/genDB.lua ./coolape/projects/mibao/genDB ./coolape/projects/mibao/db
--]]
package.cpath = "luaclib/?.so"
package.path = "lualib/?.lua;" .. "./coolape/frame/toolkit/?.lua"

require("CLUtl")
require("fileEx")

genDB = {}
local sqlDumpFile = "tables.sql";
local incsqlDumpFile = "tablesInc.sql";

local databaseName
local rootPath
local outPath

function genDB.getFiles()
    return fileEx.getFiles(arg[2], "lua")
end

function getFile(file_name)
    local f = assert(io.open(file_name, 'r'))
    local string = f:read("*all")
    f:close()
    return string
end

function writeFile(file_name, string)
    local f = assert(io.open(file_name, 'w'))
    f:write(string)
    f:close()
end

function stripextension(filename)
    local idx = filename:match(".+()%.%w+$")
    if (idx) then
        return filename:sub(1, idx - 1)
    else
        return filename
    end
end

-- 序列
function genDB.createSequence()
    local str = [[
#--DROP TABLE IF EXISTS sequence;
CREATE TABLE IF NOT EXISTS sequence (
     name VARCHAR(50) NOT NULL,
     current_value INT NOT NULL,
     increment INT NOT NULL DEFAULT 1,
     PRIMARY KEY (name)
) ENGINE=InnoDB;


DROP FUNCTION IF EXISTS currval;
DELIMITER $
CREATE FUNCTION currval (seq_name VARCHAR(50))
     RETURNS INTEGER
     LANGUAGE SQL
     DETERMINISTIC
     CONTAINS SQL
     SQL SECURITY DEFINER
     COMMENT ''
BEGIN
     DECLARE value INTEGER;
     SET value = 0;
     SELECT current_value INTO value
          FROM sequence
          WHERE name = seq_name;
     IF value = 0 THEN
          RETURN setval(seq_name, 1);
     END IF;
     RETURN value;
END
$
DELIMITER ;

DROP FUNCTION IF EXISTS nextval;
DELIMITER $
CREATE FUNCTION nextval (seq_name VARCHAR(50))
     RETURNS INTEGER
     LANGUAGE SQL
     DETERMINISTIC
     CONTAINS SQL
     SQL SECURITY DEFINER
     COMMENT ''
BEGIN
     UPDATE sequence
          SET current_value = current_value + increment
          WHERE name = seq_name;
     RETURN currval(seq_name);
END
$
DELIMITER ;

DROP FUNCTION IF EXISTS setval;
DELIMITER $
CREATE FUNCTION setval (seq_name VARCHAR(50), value INTEGER)
     RETURNS INTEGER
     LANGUAGE SQL
     DETERMINISTIC
     CONTAINS SQL
     SQL SECURITY DEFINER
     COMMENT ''
BEGIN
     DECLARE n INTEGER;
     SELECT COUNT(*) INTO n FROM sequence WHERE name = seq_name;
     IF n = 0 THEN
         INSERT INTO sequence VALUES (seq_name, 1, 1);
         RETURN 1;
     END IF;
     UPDATE sequence
          SET current_value = value
          WHERE name = seq_name;
     RETURN currval(seq_name);
END
$
DELIMITER ;
#----------------------------------------------
        ]]
    return str;
end

function genDB.genTables()
    local files = genDB.getFiles()
    if #files == 0 then
        return "";
    end
    local sqlStr = {};
    local incsqlStr = {};
    databaseName = arg[1]
    rootPath = arg[2]
    outPath = arg[3]
    if rootPath == nil then
        rootPath = "."
    end
    if outPath == nil then
        outPath = "."
    end
    -- 建库
    table.insert(sqlStr, "create database if not exists `" .. databaseName .. "`;")
    table.insert(sqlStr, "use `" .. databaseName .. "`;")
    table.insert(sqlStr, "alter database " .. databaseName .. " character set utf8;")
    table.insert(incsqlStr, "create database if not exists `" .. databaseName .. "`;")
    table.insert(incsqlStr, "use `" .. databaseName .. "`;")
    --建序列
    table.insert(sqlStr, genDB.createSequence());

    --建表
    local t;
    for i, v in ipairs(files) do
        t = dofile(rootPath .. "/" .. v);
        table.insert(sqlStr, genDB.genSql(t));
        genDB.genLuaFile(outPath, t);
        -- 生成增量sql
        local alertSql = genDB.genIncrementSql(rootPath .. "/preVer/" .. v, t)
        if alertSql then
            table.insert(incsqlStr, alertSql)
        end
        -- 保存上一版本
        fileEx.createDir(CLUtl.combinePath(rootPath, "/preVer/"))
        local content = fileEx.readAll(CLUtl.combinePath(rootPath, v))
        fileEx.writeAll(CLUtl.combinePath(rootPath, "/preVer/" .. v), content)
    end
    local outSqlFile = CLUtl.combinePath(outPath, sqlDumpFile)
    writeFile(outSqlFile, table.concat(sqlStr, "\n"));
    local incSqlPath = CLUtl.combinePath(rootPath, os.date("%Y_%m_%d_%H_%M_%S") .. "/")
    fileEx.createDir(incSqlPath)
    local outIncSqlFile = CLUtl.combinePath(incSqlPath, incsqlDumpFile)
    writeFile(outIncSqlFile, table.concat(incsqlStr, "\n"));
    print("success：increment SQL outfiles==" .. outIncSqlFile)
    print("success：SQL outfiles==" .. outSqlFile)
end

--增量sql
function genDB.genIncrementSql(oldPath, t)
    if not fileEx.exist(oldPath) then
        return nil
    end
    local oldt = dofile(oldPath)
    if oldt == nil then
        return nil
    end
    local columnsMap = {}
    for k, v in ipairs(oldt.columns) do
        columnsMap[v[1]] = v
    end
    local ret = {}
    local colName
    local oldCol
    for i, v in ipairs(t.columns) do
        colName = v[1]
        oldCol = columnsMap[colName]
        if oldCol == nil then
            -- 说明是新增字段
            table.insert(ret, "alter table " .. t.name .. " ADD " .. colName .. " " .. v[2] .. "; # " .. v[3])
        elseif v[2] ~= oldCol[2] then
            -- 说明有修改
            table.insert(ret, "alter table " .. t.name .. " MODIFY " .. colName .. " " .. v[2] .. "; # " .. v[3])
        end
    end
    if #ret > 0 then
        return table.concat(ret, "\n")
    end
    return nil
end

function genDB.genSql(tableCfg)
    local str = {};
    local columns = {}
    local primaryKey = {}
    local tName = tableCfg.name;
    -- 建表
    table.insert(str, "#----------------------------------------------------");
    table.insert(str, "#---- " .. tableCfg.desc);
    table.insert(str, "DROP TABLE IF EXISTS `" .. tName .. "`;");
    table.insert(str, "CREATE TABLE `" .. tName .. "` (");
    for i, v in ipairs(tableCfg.columns) do
        table.insert(columns, "  `" .. v[1] .. "` " .. v[2])
    end
    if tableCfg.primaryKey then
        for _, pk in ipairs(tableCfg.primaryKey) do
            table.insert(primaryKey, "`" .. pk .. "`");
        end
    end
    table.insert(columns, "  PRIMARY KEY (" .. table.concat(primaryKey, ", ") .. ")")
    table.insert(str, table.concat(columns, ",\n"));
    table.insert(str, ") ENGINE=InnoDB DEFAULT CHARSET=utf8;")

    -- 初始数据
    if tableCfg.defaultData and #tableCfg.defaultData > 0 then
        local datas = {};
        local line = {};
        for i, v in ipairs(tableCfg.defaultData) do
            line = {};
            for _, d in ipairs(v[i]) do
                if type(d) == "number" then
                    table.insert(line, "d");
                else
                    table.insert(line, "`" .. d .. "`");
                end
            end
            table.insert(datas, "(" .. table.concat(line, ",") .. ")")
        end

        table.insert(str, "INSERT INTO `" .. tName .. "` (")
        columns = {}
        for i, v in ipairs(tableCfg.columns) do
            table.insert(columns, "`" .. v[1] .. "`")
        end
        table.insert(str, table.concat(columns, ","))
        table.insert(str, ") VALUES ")
        table.insert(str, table.concat(datas, ",") .. ";")
    end
    return table.concat(str, "\n")
end

function genDB.genLuaFile(outPath, tableCfg)
    local str = {}
    local name = "db" .. tableCfg.name

    local dataInit = {}
    local dataSet = {}
    local columns = {}
    local dataInsert = {}
    local dataUpdate = {}
    local where = {}
    local where2 = {}
    local getsetFunc = {}
    local shardataKey = {}
    local shardataKey2 = {}
    local callParams = {}
    local callParamswithData = {}
    for i, v in ipairs(tableCfg.columns) do
        table.insert(getsetFunc, "function " .. name .. ":set_" .. v[1] .. "(v)")
        table.insert(getsetFunc, "    " .. (v[3] and "-- " .. v[3] or ""))
        table.insert(getsetFunc, "    if self:isEmpty() then")
        table.insert(getsetFunc, "        skynet.error(\"[" .. name .. ":set_" .. v[1] .. "],please init first!!\")")
        table.insert(getsetFunc, "        return nil")
        table.insert(getsetFunc, "    end")

        local types = v[2]:upper()
        if types:find("DEC") or types:find("INT") or types:find("FLOAT") or types:find("DOUBLE") then
            table.insert(getsetFunc, "    v = tonumber(v) or 0")
        elseif types:find("BOOL") then
            table.insert(getsetFunc, "    local val = 0")
            table.insert(getsetFunc, "    if type(v) == \"string\" then")
            table.insert(getsetFunc, "        if v == \"false\" or v ==\"0\" then")
            table.insert(getsetFunc, "            v = 0")
            table.insert(getsetFunc, "        else")
            table.insert(getsetFunc, "            v = 1")
            table.insert(getsetFunc, "        end")
            table.insert(getsetFunc, "    elseif type(v) == \"number\" then")
            table.insert(getsetFunc, "        if v == 0 then")
            table.insert(getsetFunc, "            v = 0")
            table.insert(getsetFunc, "        else")
            table.insert(getsetFunc, "            v = 1")
            table.insert(getsetFunc, "        end")
            table.insert(getsetFunc, "    else")
            table.insert(getsetFunc, "        val = 1")
            table.insert(getsetFunc, "    end")
        elseif types:find("DATETIME") then
            table.insert(getsetFunc, "    if type(v) == \"number\" then")
            table.insert(getsetFunc, "        v = dateEx.seconds2Str(v/1000)")
            table.insert(getsetFunc, "    end")
        else
            table.insert(getsetFunc, "    v = v or \"\"")
        end
        table.insert(getsetFunc, "    skynet.call(\"CLDB\", \"lua\", \"set\", self.__name__, self.__key__, \"" .. v[1] .. "\", v)")
        table.insert(getsetFunc, "end")
        table.insert(getsetFunc, "function " .. name .. ":get_" .. v[1] .. "()")
        table.insert(getsetFunc, "    " .. (v[3] and "-- " .. v[3] or ""))
        if v[2]:upper():find("BOOL") then
            table.insert(getsetFunc, "    local val = skynet.call(\"CLDB\", \"lua\", \"get\", self.__name__, self.__key__, \"" .. v[1] .. "\")")
            table.insert(getsetFunc, "    if val == nil or val == 0 or val == false then")
            table.insert(getsetFunc, "        return false")
            table.insert(getsetFunc, "    else")
            table.insert(getsetFunc, "        return true")
            table.insert(getsetFunc, "    end")
        elseif v[2]:upper():find("DATETIME") then
            table.insert(getsetFunc, "    local val = skynet.call(\"CLDB\", \"lua\", \"get\", self.__name__, self.__key__, \"" .. v[1] .. "\")")
            table.insert(getsetFunc, "    if type(val) == \"string\" then")
            table.insert(getsetFunc, "        return dateEx.str2Seconds(val)*1000 -- 转成毫秒")
            table.insert(getsetFunc, "    else")
            table.insert(getsetFunc, "        return val")
            table.insert(getsetFunc, "    end")
        elseif types:find("DEC") or types:find("INT") or types:find("FLOAT") or types:find("DOUBLE") then
            table.insert(getsetFunc, "    local val = skynet.call(\"CLDB\", \"lua\", \"get\", self.__name__, self.__key__, \"" .. v[1] .. "\")")
            table.insert(getsetFunc, "    return (tonumber(val) or 0)")
        else
            table.insert(getsetFunc, "    return skynet.call(\"CLDB\", \"lua\", \"get\", self.__name__, self.__key__, \"" .. v[1] .. "\")")
        end
        table.insert(getsetFunc, "end")
        table.insert(getsetFunc, "")

        table.insert(columns, "`" .. v[1] .. "`")
        local types = v[2]:upper()
        if types:find("DEC") or types:find("INT") or types:find("FLOAT") or types:find("DOUBLE") or types:find("BOOL") then
            table.insert(dataInit, "    self." .. v[1] .. " = 0" .. (v[3] and "    -- " .. v[3] or ""))
            table.insert(dataSet, "    self." .. v[1] .. " = data." .. v[1] .. (v[3] and "    -- " .. v[3] or ""))
            table.insert(dataInsert, "(self." .. v[1] .. " and self." .. v[1] .. " or 0)");
            table.insert(dataUpdate, "\"`" .. v[1] .. "`=\" .. (self." .. v[1] .. " and self." .. v[1] .. " or 0)");
        else
            table.insert(dataInit, "    self." .. v[1] .. " = \"\"" .. (v[3] and "    -- " .. v[3] or ""))
            table.insert(dataSet, "    self." .. v[1] .. " = data." .. v[1] .. (v[3] and "    -- " .. v[3] or ""))
            table.insert(dataInsert, "(self." .. v[1] .. " and \"'\" .. self." .. v[1] .. " .. \"'\" or \"NULL\")");
            table.insert(dataUpdate, "\"'" .. v[1] .. "`=\" .. " .. "(self." .. v[1] .. " and \"'\" .. self." .. v[1] .. " .. \"'\" or \"NULL\")" .. " .. \"'\"");
        end
    end

    for i, pkey in ipairs(tableCfg.cacheKey) do
        table.insert(shardataKey, "data." .. pkey);
        table.insert(shardataKey2, "v." .. pkey);
    end

    if tableCfg.primaryKey then
        for i, pkey in ipairs(tableCfg.primaryKey) do
            local types = ""
            for j, col in ipairs(tableCfg.columns) do
                if pkey == col[1] then
                    types = col[2]:upper()
                    break
                end
            end

            for j, ck in ipairs(tableCfg.cacheKey) do
                if ck == pkey then
                    table.insert(callParams, pkey);
                    table.insert(callParamswithData, "data." .. pkey)
                    break
                else
                    if j == #(tableCfg.cacheKey) then
                        table.insert(callParams, "nil");
                        table.insert(callParamswithData, "nil")
                    end
                end
            end
            if types:find("DEC") or types:find("INT") or types:find("FLOAT") or types:find("DOUBLE") or types:find("BOOL") then
                table.insert(where, "\"`" .. pkey .. "`=\" .. (self." .. pkey .. " and self." .. pkey .. " or 0)");
                table.insert(where2, "\"`" .. pkey .. "`=\" .. (" .. pkey .. " and " .. pkey .. " or 0)");
            else
                table.insert(where, "\"`" .. pkey .. "`=\" .. " .. "(self." .. pkey .. " and \"'\" .. self." .. pkey .. " .. \"'\" or \"NULL\")");
                table.insert(where2, "\"`" .. pkey .. "`=\" .. " .. "(" .. pkey .. " and \"'\" .. " .. pkey .. " ..\"'\" or \"\")");
            end
        end
    end
    -----------------------------------
    table.insert(str, "--[[")
    table.insert(str, "使用时特别注意：")
    table.insert(str, "1、常用方法如下，在不知道表里有没有数据时可以采用如下方法（可能会查询一次表）")
    table.insert(str, "    local obj＝ " .. name .. ".instanse(" .. table.concat(tableCfg.cacheKey, ", ") .. ");")
    table.insert(str, "    if obj:isEmpty() then")
    table.insert(str, "        -- 没有数据")
    table.insert(str, "    else")
    table.insert(str, "        -- 有数据")
    table.insert(str, "    end")
    table.insert(str, "2、使用如下用法时，程序会自动判断是否是insert还是update")
    table.insert(str, "    local obj＝ " .. name .. ".new(data);")
    table.insert(str, "3、使用如下用法时，程序会自动判断是否是insert还是update")
    table.insert(str, "    local obj＝ " .. name .. ".new();")
    table.insert(str, "    obj:init(data);")
    table.insert(str, "]]")
    table.insert(str, "")
    table.insert(str, "require(\"class\")")
    table.insert(str, "local skynet = require \"skynet\"")
    table.insert(str, "local tonumber = tonumber")
    table.insert(str, "require(\"dateEx\")")
    table.insert(str, "")
    table.insert(str, "-- " .. tableCfg.desc)
    table.insert(str, "---@class " .. name)
    table.insert(str, name .. " = class(\"" .. name .. "\")")
    table.insert(str, "")
    table.insert(str, name .. ".name = \"" .. tableCfg.name .. "\"")
    table.insert(str, "")
    table.insert(str, name .. ".keys = {")
    for i, v in ipairs(tableCfg.columns) do
        table.insert(str, "    " .. v[1] .. " = \"" .. v[1] .. "\", -- " .. v[3])
    end
    table.insert(str, "}")
    table.insert(str, "")
    table.insert(str, "function " .. name .. ":ctor(v)")
    table.insert(str, "    self.__name__ = \"" .. tableCfg.name .. "\"    -- 表名")
    table.insert(str, "    self.__isNew__ = nil -- false:说明mysql里已经有数据了")
    table.insert(str, "    if v then")
    table.insert(str, "        self:init(v)")
    table.insert(str, "    end")
    --table.insert(str, table.concat(dataInit, "\n"))
    table.insert(str, "end")
    table.insert(str, "")

    table.insert(str, "function " .. name .. ":init(data, isNew)")
    --table.insert(str, table.concat(dataSet, "\n"))
    table.insert(str, "    data = " .. name .. ".validData(data)")
    table.insert(str, "    self.__key__ = " .. table.concat(shardataKey, " .. \"_\" .. "))
    table.insert(str, "    local hadCacheData = false")
    table.insert(str, "    if self.__isNew__ == nil and isNew == nil then")
    table.insert(str, "        local d = skynet.call(\"CLDB\", \"lua\", \"get\", " .. name .. ".name, self.__key__)")
    table.insert(str, "        if d == nil then")
    table.insert(str, "            d = skynet.call(\"CLMySQL\", \"lua\", \"exesql\", " .. name .. ".querySql(" .. table.concat(callParamswithData, ", ") .. "))")
    table.insert(str, "            if d and d.errno == nil and #d > 0 then")
    table.insert(str, "                self.__isNew__ = false")
    table.insert(str, "            else")
    table.insert(str, "                self.__isNew__ = true")
    table.insert(str, "            end")
    table.insert(str, "        else")
    table.insert(str, "            hadCacheData = true")
    table.insert(str, "            self.__isNew__ = false")
    table.insert(str, "        end")
    table.insert(str, "    else")
    table.insert(str, "        self.__isNew__ = isNew")
    table.insert(str, "    end")
    table.insert(str, "    if self.__isNew__ then")
    table.insert(str, "        -- 说明之前表里没有数据，先入库")
    table.insert(str, "        local sql = skynet.call(\"CLDB\", \"lua\", \"GETINSERTSQL\", self.__name__, data)")
    table.insert(str, "        local r = skynet.call(\"CLMySQL\", \"lua\", \"save\", sql)")
    table.insert(str, "        if r == nil or r.errno == nil then")
    table.insert(str, "            self.__isNew__ = false")
    table.insert(str, "        else")
    table.insert(str, "            return false")
    table.insert(str, "        end")
    table.insert(str, "    end")
    table.insert(str, "    if not hadCacheData then")
    table.insert(str, "        skynet.call(\"CLDB\", \"lua\", \"set\", self.__name__, self.__key__, data)")
    table.insert(str, "    end")
    table.insert(str, "    skynet.call(\"CLDB\", \"lua\", \"SETUSE\", self.__name__, self.__key__)")
    table.insert(str, "    return true")
    table.insert(str, "end")
    table.insert(str, "")
    table.insert(str, "function " .. name .. ":tablename() -- 取得表名")
    table.insert(str, "    return self.__name__")
    table.insert(str, "end")
    table.insert(str, "")
    table.insert(str, "function " .. name .. ":value2copy()  -- 取得数据复样，注意是只读的数据且只有当前时刻是最新的，如果要取得最新数据及修改数据，请用get、set")
    table.insert(str, "    local ret = skynet.call(\"CLDB\", \"lua\", \"get\", self.__name__, self.__key__)")
    if #tableCfg.columns >0 then
        table.insert(str, "    if ret then")
    end
    for i, v in ipairs(tableCfg.columns) do
        local types = v[2]:upper()
        if types:find("BOOL") or types:find("DATETIME") then
            table.insert(str, "        ret." .. v[1] .. " = self:get_" .. v[1] .. "()")
        end
    end
    if #tableCfg.columns >0 then
        table.insert(str, "    end")
    end
    table.insert(str, "    return ret")
    table.insert(str, "end")
    table.insert(str, "")

    table.insert(str, "function " .. name .. ":refreshData(data)")
    table.insert(str, "    if data == nil or self.__key__ == nil then")
    table.insert(str, "        skynet.error(\"" .. name .. ":refreshData error!\")")
    table.insert(str, "        return")
    table.insert(str, "    end")
    table.insert(str, "    local orgData = self:value2copy()")
    table.insert(str, "    if orgData == nil then")
    table.insert(str, "        skynet.error(\"get old data error!!\")")
    table.insert(str, "    end")
    table.insert(str, "    for k, v in pairs(data) do")
    table.insert(str, "        orgData[k] = v")
    table.insert(str, "    end")
    table.insert(str, "    orgData = " .. name .. ".validData(orgData)")
    table.insert(str, "    skynet.call(\"CLDB\", \"lua\", \"set\", self.__name__, self.__key__, orgData)")
    table.insert(str, "end")
    table.insert(str, "")

    table.insert(str, table.concat(getsetFunc, "\n"))

    table.insert(str, "-- 把数据flush到mysql里， immd=true 立即生效")
    table.insert(str, "function " .. name .. ":flush(immd)")
    table.insert(str, "    local sql")
    table.insert(str, "    if self.__isNew__ then")
    table.insert(str, "        sql = skynet.call(\"CLDB\", \"lua\", \"GETINSERTSQL\", self.__name__, self:value2copy())")
    table.insert(str, "    else")
    table.insert(str, "        sql = skynet.call(\"CLDB\", \"lua\", \"GETUPDATESQL\", self.__name__, self:value2copy())")
    table.insert(str, "    end")
    table.insert(str, "    return skynet.call(\"CLMySQL\", \"lua\", \"save\", sql, immd)")
    table.insert(str, "end")
    table.insert(str, "")

    table.insert(str, "function " .. name .. ":isEmpty()")
    local tmp = {}
    for i, v in ipairs(tableCfg.cacheKey) do
        table.insert(tmp, "(self:get_" .. v .. "() == nil)")
    end
    table.insert(str, "    return (self.__key__ == nil) or " .. table.concat(tmp, " or "))
    table.insert(str, "end")
    table.insert(str, "")

    table.insert(str, "function " .. name .. ":release()")
    table.insert(str, "    skynet.call(\"CLDB\", \"lua\", \"SETUNUSE\", self.__name__, self.__key__)")
    table.insert(str, "    self.__isNew__ = nil")
    table.insert(str, "    self.__key__ = nil")
    table.insert(str, "end")
    table.insert(str, "")

    table.insert(str, "function " .. name .. ":delete()")
    table.insert(str, "    local d = self:value2copy()")
    table.insert(str, "    skynet.call(\"CLDB\", \"lua\", \"SETUNUSE\", self.__name__, self.__key__)")
    table.insert(str, "    skynet.call(\"CLDB\", \"lua\", \"REMOVE\", self.__name__, self.__key__)")
    table.insert(str, "    local sql = skynet.call(\"CLDB\", \"lua\", \"GETDELETESQL\", self.__name__, d)")
    table.insert(str, "    return skynet.call(\"CLMySQL\", \"lua\", \"EXESQL\", sql)")
    table.insert(str, "end")
    table.insert(str, "")

    table.insert(str, "---@public 设置触发器（当有数据改变时回调）")
    table.insert(str, "---@param server 触发回调服务地址")
    table.insert(str, "---@param cmd 触发回调服务方法")
    table.insert(str, "---@param fieldKey 字段key(可为nil)")
    table.insert(str, "function " .. name .. ":setTrigger(server, cmd, fieldKey)")
    table.insert(str, "    skynet.call(\"CLDB\", \"lua\", \"ADDTRIGGER\", self.__name__, self.__key__, server, cmd, fieldKey)")
    table.insert(str, "end")
    table.insert(str, "")
    table.insert(str, "---@param server 触发回调服务地址")
    table.insert(str, "---@param cmd 触发回调服务方法")
    table.insert(str, "---@param fieldKey 字段key(可为nil)")
    table.insert(str, "function " .. name .. ":unsetTrigger(server, cmd, fieldKey)")
    table.insert(str, "    skynet.call(\"CLDB\", \"lua\", \"REMOVETRIGGER\", self.__name__, self.__key__, server, cmd, fieldKey)")
    table.insert(str, "end")
    table.insert(str, "")

    --table.insert(str, "function " .. name .. ":insertSql()")
    --table.insert(str, "    local sql = \"INSERT INTO `" .. tableCfg.name .. "` (" .. table.concat(columns, ",") .. ")\"")
    --table.insert(str, "    .. \" VALUES (\"")
    --table.insert(str, "    .. " .. table.concat(dataInsert, " .. \",\"\n    .. "))
    --table.insert(str, "    .. \");\"")
    --table.insert(str, "    return sql")
    --table.insert(str, "end")
    --table.insert(str, "")
    --
    --table.insert(str, "function " .. name .. ":updateSql()")
    --table.insert(str, "    local sql = \"UPDATE " .. tableCfg.name .. " SET \"..")
    --table.insert(str, "    " .. table.concat(dataUpdate, " .. \",\"\n    .. "))
    --table.insert(str, "    .. \"WHERE \" .. " .. table.concat(where, " .. \" AND \" .. ") .. " .. \";\"")
    --table.insert(str, "    return sql")
    --table.insert(str, "end")
    --table.insert(str, "")
    --
    --table.insert(str, "function " .. name .. ":delSql()")
    --table.insert(str, "    local sql = \"DELETE FROM " .. tableCfg.name .. " WHERE \".. " .. table.concat(where, " .. \" AND \" .. ") .. " .. \";\"")
    --table.insert(str, "    return sql")
    --table.insert(str, "end")
    --table.insert(str, "")
    --
    --table.insert(str, "function " .. name .. ":toSql()")
    --table.insert(str, "    if self.__isNew__ then")
    --table.insert(str, "        return self:insertSql()")
    --table.insert(str, "    else")
    --table.insert(str, "        return self:updateSql()")
    --table.insert(str, "    end")
    --table.insert(str, "end")
    --table.insert(str, "")

    if tableCfg.primaryKey then
        table.insert(str, "function " .. name .. ".querySql(" .. table.concat(tableCfg.primaryKey, ", ") .. ")")
        table.insert(str, "    -- 如果某个参数为nil,则where条件中不包括该条件")
        table.insert(str, "    local where = {}")
        for i, k in ipairs(tableCfg.primaryKey) do
            local types = ""
            for j, col in ipairs(tableCfg.columns) do
                if k == col[1] then
                    types = col[2]:upper()
                    break
                end
            end
            table.insert(str, "    if " .. k .. " then")
            if types:find("DEC") or types:find("INT") or types:find("FLOAT") or types:find("DOUBLE") or types:find("BOOL") then
                table.insert(str, "        table.insert(where, \"`" .. k .. "`=\" .. " .. k .. ")")
            else
                table.insert(str, "        table.insert(where, \"`" .. k .. "`=\" .. \"'\" .. " .. k .. "  .. \"'\")")
            end
            table.insert(str, "    end")
        end

        table.insert(str, "    if #where > 0 then")
        table.insert(str, "        return \"SELECT * FROM " .. tableCfg.name .. " WHERE \" .. table.concat(where, \" and \") .. \";\"")
        table.insert(str, "    else")
        table.insert(str, "       return \"SELECT * FROM " .. tableCfg.name .. ";\"")
        table.insert(str, "    end")
    else
        table.insert(str, "function " .. name .. ".querySql()")
        table.insert(str, "    return \"SELECT * FROM" .. tableCfg.name .. ";")
    end
    table.insert(str, "end")
    table.insert(str, "")

    if tableCfg.groupKey and #tableCfg.groupKey > 0 then
        for i, group in ipairs(tableCfg.groupKey) do
            local where = ""
            local funcName = table.concat(group, "_")
            local funcParm = table.concat(group, ", ")
            local funcParm2 = table.concat(group, " .. \"_\" .. ")
            for j, gkey in ipairs(group) do
                local types = ""
                for j, col in ipairs(tableCfg.columns) do
                    if gkey == col[1] then
                        types = col[2]:upper()
                        break
                    end
                end
                if types:find("DEC") or types:find("INT") or types:find("FLOAT") or types:find("DOUBLE") or types:find("BOOL") then
                    local _where = gkey .. "=\"" .. " .. " .. gkey .. " .. "
                    where = where:len() > 0 and where .. "\" AND " .. _where or _where
                else
                    local _where = gkey .. "=\"" .. " .. \"'\" .. " .. gkey .. " .. \"'\" .. "
                    where = where:len() > 0 and where .. "\" AND " .. _where or _where
                end
            end
            table.insert(str, "---@public 取得一个组")
            table.insert(str, "---@param forceSelect boolean 强制从mysql取数据")
            table.insert(str, "---@param orderby string 排序")
            table.insert(str, "function " .. name .. ".getListBy" .. funcName .. "(" .. funcParm .. ", forceSelect, orderby, limitOffset, limitNum)")
            table.insert(str, "    if orderby and orderby ~= \"\" then")
            table.insert(str, "        forceSelect = true")
            table.insert(str, "    end")
            table.insert(str, "    local data")
            table.insert(str, "    local ret = {}")
            table.insert(str, "    local cachlist, isFullCached, list")
            table.insert(str, "    local groupInfor = skynet.call(\"CLDB\", \"lua\", \"GETGROUP\", " .. name .. ".name, " .. funcParm2 .. ") or {}")
            table.insert(str, "    cachlist = groupInfor[1] or {}")
            table.insert(str, "    isFullCached = groupInfor[2]")
            table.insert(str, "    if isFullCached == true and (not forceSelect) then")
            table.insert(str, "        list = cachlist")
            table.insert(str, "        for k, v in pairs(list) do")
            table.insert(str, "            data = " .. name .. ".new(v, false)")
            table.insert(str, "            table.insert(ret, data:value2copy())")
            table.insert(str, "            data:release()")
            table.insert(str, "        end")
            table.insert(str, "    else")
            table.insert(str, "        local sql = \"SELECT * FROM " .. tableCfg.name .. " WHERE " .. where .. " (orderby and \" ORDER BY\" ..  orderby or \"\") .. ((limitOffset and limitNum) and (\" LIMIT \" ..  limitOffset .. \",\" .. limitNum) or \"\") .. \";\"")
            table.insert(str, "        list = skynet.call(\"CLMySQL\", \"lua\", \"exesql\", sql)")
            table.insert(str, "        if list and list.errno then")
            table.insert(str, "            skynet.error(\"[" .. name .. ".getGroup] sql error==\" .. sql)")
            table.insert(str, "            return nil")
            table.insert(str, "         end")
            table.insert(str, "         for i, v in ipairs(list) do")
            table.insert(str, "             local key = tostring(" .. table.concat(shardataKey2, " .. \"_\" .. ") .. ")")
            table.insert(str, "             local d = cachlist[key]")
            table.insert(str, "             if d ~= nil then")
            table.insert(str, "                 -- 用缓存的数据才是最新的")
            table.insert(str, "                 list[i] = d")
            table.insert(str, "                 cachlist[key] = nil")
            table.insert(str, "             end")
            table.insert(str, "         end")
            table.insert(str, "         for k ,v in pairs(cachlist) do")
            table.insert(str, "             table.insert(list, v)")
            table.insert(str, "         end")
            table.insert(str, "         cachlist = nil")
            
            table.insert(str, "         for k, v in ipairs(list) do")
            table.insert(str, "             data = " .. name .. ".new(v, false)")
            table.insert(str, "             ret[k] = data:value2copy()")
            table.insert(str, "             data:release()")
            table.insert(str, "         end")
            table.insert(str, "     end")

            table.insert(str, "     list = nil")
            table.insert(str, "     -- 设置当前缓存数据是全的数据")
            table.insert(str, "     skynet.call(\"CLDB\", \"lua\", \"SETGROUPISFULL\", ".. name .. ".name, ".. funcParm2 .. ")")
            table.insert(str, "     return ret")
            table.insert(str, "end")
            table.insert(str, "")
        end
    end

    table.insert(str, "function " .. name .. ".validData(data)")
    table.insert(str, "    if data == nil then return nil end")
    table.insert(str, "");

    for i, v in ipairs(tableCfg.columns) do
        local types = v[2]:upper()
        local filed = "data." .. v[1]
        if types:find("DEC") or types:find("INT") or types:find("FLOAT") or types:find("DOUBLE") then
            table.insert(str, "    if type(" .. filed .. ") ~= \"number\" then")
            table.insert(str, "        " .. filed .. " = tonumber(" .. filed .. ") or 0")
            table.insert(str, "    end")
        elseif types:find("BOOL") then
            table.insert(str, "    if type(" .. filed .. ") == \"string\" then")
            table.insert(str, "        if " .. filed .. " == \"false\" or " .. filed .. " ==\"0\" then")
            table.insert(str, "            " .. filed .. " = 0")
            table.insert(str, "        else")
            table.insert(str, "            " .. filed .. " = 1")
            table.insert(str, "        end")
            table.insert(str, "    elseif type(" .. filed .. ") == \"number\" then")
            table.insert(str, "        if " .. filed .. " == 0 then")
            table.insert(str, "            " .. filed .. " = 0")
            table.insert(str, "        else")
            table.insert(str, "            " .. filed .. " = 1")
            table.insert(str, "        end")
            table.insert(str, "    else")
            table.insert(str, "        " .. filed .. " = 0")
            table.insert(str, "    end")
        elseif types:find("DATETIME") then
            table.insert(str, "    if type(" .. filed .. ") == \"number\" then")
            table.insert(str, "        " .. filed .. " = dateEx.seconds2Str(" .. filed .. "/1000)")
            table.insert(str, "    end")
        else
            --table.insert(str, "    " .. filed .. " = ".. filed .. " == nil and nil or tostring(" .. filed .. ")")
        end
    end

    table.insert(str, "    return data")
    table.insert(str, "end")
    table.insert(str, "")

    if tableCfg.primaryKey then
        table.insert(str, "function " .. name .. ".instanse(" .. table.concat(tableCfg.cacheKey, ", ") .. ")")
    else
        table.insert(str, "function " .. name .. ".instanse()")
    end

    table.insert(str, "    if type(" .. tableCfg.cacheKey[1] .. ") == \"table\" then")
    table.insert(str, "        local d = " .. tableCfg.cacheKey[1])
    for i, v in ipairs(tableCfg.cacheKey) do
        table.insert(str, "        " .. v .. " = d." .. v)
    end
    table.insert(str, "    end")

    local checkNil = {}
    local keyTmp = {}
    for i, v in ipairs(tableCfg.cacheKey) do
        table.insert(checkNil, v .. " == nil")
        table.insert(keyTmp, "(" .. v .. " or \"\")")
    end

    table.insert(str, "    if " .. table.concat(checkNil, " and ") .. " then")
    table.insert(str, "        skynet.error(\"[" .. name .. ".instanse] all input params == nil\")")
    table.insert(str, "        return nil")
    table.insert(str, "    end")

    table.insert(str, "    local key = " .. table.concat(keyTmp, " .. \"_\" .. "))
    table.insert(str, "    if key == \"\" then")
    table.insert(str, "        error(\"the key is null\", 0)")
    --table.insert(str, "        return ")
    table.insert(str, "    end")

    table.insert(str, "    ---@type " .. name)
    table.insert(str, "    local obj = " .. name .. ".new()");
    table.insert(str, "    local d = skynet.call(\"CLDB\", \"lua\", \"get\", " .. name .. ".name, key)");
    table.insert(str, "    if d == nil then")
    table.insert(str, "        d = skynet.call(\"CLMySQL\", \"lua\", \"exesql\", " .. name .. ".querySql(" .. table.concat(callParams, ", ") .. "))")
    table.insert(str, "        if d and d.errno == nil and #d > 0 then")
    table.insert(str, "            if #d == 1 then")
    table.insert(str, "                d = d[1]")
    table.insert(str, "                -- 取得mysql表里的数据")
    table.insert(str, "                obj.__isNew__ = false")
    table.insert(str, "                obj.__key__ = key")
    table.insert(str, "                obj:init(d)")
    table.insert(str, "            else")
    table.insert(str, "                error(\"get data is more than one! count==\" .. #d .. \", lua==" .. name .. "\")")
    table.insert(str, "            end")
    table.insert(str, "        else")
    table.insert(str, "            -- 没有数据")
    table.insert(str, "            obj.__isNew__ = true")
    table.insert(str, "        end")
    table.insert(str, "    else")
    table.insert(str, "        obj.__isNew__ = false")
    table.insert(str, "        obj.__key__ = key")
    table.insert(str, "        skynet.call(\"CLDB\", \"lua\", \"SETUSE\", " .. name .. ".name, key)");
    table.insert(str, "    end")
    table.insert(str, "    return obj");
    table.insert(str, "end")
    table.insert(str, "")

    table.insert(str, "------------------------------------")
    table.insert(str, "return " .. name)
    table.insert(str, "")

    local outFile = CLUtl.combinePath(outPath, name .. ".lua")
    writeFile(outFile, table.concat(str, "\n"))
    print("out lua file==" .. outFile)
end
--------------------------------------------
if #arg < 3 then
    print("err:参数错误！！第一个参数是database名， 第二个参数是表配置目录，第三个参数是相关lua文件输出目录。")
    return
end
genDB.genTables();
--------------------------------------------
return genDB;
