-- 数据库 工具
--[[ run cmd
./3rd/lua/lua coolape/frame/dbTool/genDB.lua [输入目录] [输出目录]
./3rd/lua/lua coolape/frame/dbTool/genDB.lua ./coolape/projects/mibao/genDB ./coolape/projects/mibao/db
--]]
package.cpath = "luaclib/?.so"
package.path = "lualib/?.lua;" .. "./coolape/frame/toolkit/?.lua"

require("CLUtl")

genDB = {}
local sqlDumpFile = "tables.sql";

function genDB.getFiles()
    return CLUtl.getFiles(arg[1], "lua")
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
    local rootPath = arg[1]
    local outPath = arg[2]
    if rootPath == nil then
        rootPath = "."
    end
    if outPath == nil then
        outPath = "."
    end

    --建序列
    table.insert(sqlStr, genDB.createSequence());

    --建表
    local t;
    for i, v in ipairs(files) do
        t = dofile(rootPath .. "/" .. v );
        table.insert(sqlStr, genDB.genSql(t));
        genDB.genLuaFile(outPath, t);
    end
    local outSqlFile = CLUtl.combinePath(outPath, sqlDumpFile)
    writeFile(outSqlFile, table.concat(sqlStr, "\n"));
    print("success：SQL outfiles==" .. outSqlFile)
end

function genDB.genSql(tableCfg)
    local str = {};
    local columns = {}
    local primaryKey = {}
    local tName = tableCfg.name;
    -- 建表
    table.insert(str, "#----------------------------------------------------");
    table.insert(str, "#---- " .. tableCfg.desc );
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
    for i, v in ipairs(tableCfg.columns) do
        table.insert(columns, "`" .. v[1] .. "`" )
        local types = v[2]:upper()
        if types:find("INT") or types:find("FLOAT") or types:find("DOUBLE") then
            table.insert(dataInit, "    self." .. v[1] .. " = 0" .. ( v[3] and "    -- " .. v[3] or ""))
            table.insert(dataSet, "    self." .. v[1] .. " = data." .. v[1] .. ( v[3] and "    -- " .. v[3] or ""))
            table.insert(dataInsert, "(self." .. v[1] .. " and self." .. v[1] .. " or 0)");
            table.insert(dataUpdate, "\"`" .. v[1] .. "`=\" .. (self." .. v[1] .. " and self." .. v[1] .. " or 0)");
        else
            table.insert(dataInit, "    self." .. v[1] .. " = \"\"" .. ( v[3] and "    -- " .. v[3] or ""))
            table.insert(dataSet, "    self." .. v[1] .. " = data." .. v[1] .. ( v[3] and "    -- " .. v[3] or ""))
            table.insert(dataInsert, "\"'\" .. " .. "(self." .. v[1] .. " and self." .. v[1] .. " or \"\")" .. " .. \"'\"");
            table.insert(dataUpdate, "\"`" .. v[1] .. "`='\" .. " .. "(self." .. v[1] .. " and self." .. v[1] .. " or \"\")" .. " .. \"'\"");
        end
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

            if types:find("INT") or types:find("FLOAT") or types:find("DOUBLE") then
                table.insert(where, "\"`" .. pkey .. "`=\" .. (self." .. pkey .. " and self." .. pkey .. " or 0)");
                table.insert(where2, "\"`" .. pkey .. "`=\" .. (" .. pkey .. " and " .. pkey .. " or 0)");
            else
                table.insert(where, "\"`" .. pkey .. "`='\" .. " .. "(self." .. pkey .. " and self." .. pkey .. " or \"\")" .. " .. \"'\"");
                table.insert(where2, "\"`" .. pkey .. "`='\" .. " .. "(" .. pkey .. " and " .. pkey .. " or \"\")" .. " .. \"'\"");
            end
        end
    end
    -----------------------------------
    table.insert(str, "require(\"class\")")
    table.insert(str, "local skynet = require \"skynet\"")
    table.insert(str, "")
    table.insert(str, "-- " .. tableCfg.desc)
    table.insert(str, name .. " = class(\"" .. name .. "\")")
    table.insert(str, "")
    table.insert(str, name .. ".name = \"" .. tableCfg.name .. "\"")
    table.insert(str, "")
    table.insert(str, "function " .. name .. ":ctor(v)")
    table.insert(str, "    self.__name__ = \"" .. tableCfg.name .. "\"    -- 表名")
    table.insert(str, "    self.__isNew__ = true    -- 新建数据，说明mysql表里没有数据")
    table.insert(str, table.concat(dataInit, "\n"))
    table.insert(str, "end")
    table.insert(str, "")

    table.insert(str, "function " .. name .. ":init(data)")
    table.insert(str, table.concat(dataSet, "\n"))
    table.insert(str, "end")
    table.insert(str, "")

    table.insert(str, "function " .. name .. ":insertSql()")
    table.insert(str, "    local sql = \"INSERT INTO `" .. tableCfg.name .. "` (" .. table.concat(columns, ",") .. ")\"")
    table.insert(str, "    .. \" VALUES (\"")
    table.insert(str, "    .. " .. table.concat(dataInsert, " .. \",\"\n    .. "))
    table.insert(str, "    .. \");\"")
    table.insert(str, "    return sql")
    table.insert(str, "end")
    table.insert(str, "")

    table.insert(str, "function " .. name .. ":updateSql()")
    table.insert(str, "    local sql = \"UPDATE " .. tableCfg.name .. " SET \"..")
    table.insert(str, "    " .. table.concat(dataUpdate, " .. \",\"\n    .. "))
    table.insert(str, "    .. \"WHERE \" .. " .. table.concat(where, " .. \" AND \" .. ") .. " .. \";\"")
    table.insert(str, "    return sql")
    table.insert(str, "end")
    table.insert(str, "")

    table.insert(str, "function " .. name .. ":delSql()")
    table.insert(str, "    local sql = \"DELETE FROM " .. tableCfg.name .. " WHERE \".. " .. table.concat(where, " .. \" AND \" .. ") .. " .. \";\"")
    table.insert(str, "    return sql")
    table.insert(str, "end")
    table.insert(str, "")

    table.insert(str, "function " .. name .. ":toSql()")
    table.insert(str, "    if self.__isNew__ then")
    table.insert(str, "        return self:insertSql()")
    table.insert(str, "    else")
    table.insert(str, "        return self:updateSql()")
    table.insert(str, "    end")
    table.insert(str, "end")
    table.insert(str, "")

    if tableCfg.primaryKey then
        table.insert(str, "function " .. name .. ".querySql(" .. table.concat(tableCfg.primaryKey, ", ") .. ")")
    else
        table.insert(str, "function " .. name .. ".querySql()")
    end
    table.insert(str, "    return \"SELECT * FROM " .. tableCfg.name .. " WHERE \" .. " .. table.concat(where2, " .. \" AND \" .. ") .. " .. \";\"")
    table.insert(str, "end")
    table.insert(str, "")

    if tableCfg.primaryKey then
        table.insert(str, "function " .. name .. ".instanse(" .. table.concat(tableCfg.primaryKey, ", ") .. ")")
    else
        table.insert(str, "function " .. name .. ".instanse()")
    end
    table.insert(str, "    local key = " .. table.concat(tableCfg.primaryKey, " .. \"_\" .. "))
    table.insert(str, "    if key == \"\" then")
    table.insert(str, "        error(\"the key is null\", 0)")
    --table.insert(str, "        return ")
    table.insert(str, "    end")

    table.insert(str, "    ---@type dbuser")
    table.insert(str, "    local obj = skynet.call(\"CLDB\", \"lua\", \"get\", " .. name .. ".name, key)");
    table.insert(str, "    if obj == nil then")
    table.insert(str, "        local d = skynet.call(\"CLMySQL\", \"lua\", \"exesql\", " .. name .. ".querySql(" .. table.concat(tableCfg.primaryKey, ",") .. "))")
    table.insert(str, "        obj = dbuser.new()");
    table.insert(str, "        if d and #d > 0 then")
    table.insert(str, "            if #d == 0 then")
    table.insert(str, "                d = d[1]")
    table.insert(str, "            else")
    table.insert(str, "                error(\"get data is more than one! count==\" .. #d .. \"lua==" .. name .. "\")")
    table.insert(str, "            end")
    table.insert(str, "            -- 取得mysql表里的数据")
    table.insert(str, "            obj:init(d)")
    table.insert(str, "            obj.__isNew__ = false")
    table.insert(str, "            skynet.call(\"CLDB\", \"lua\", \"set\", " .. name .. ".name, key, obj)")
    table.insert(str, "        else")
    table.insert(str, "            -- 没有数据")
    table.insert(str, "            obj.__isNew__ = true")
    table.insert(str, "        end")
    table.insert(str, "    else")
    table.insert(str, "        obj.__isNew__ = false")
    table.insert(str, "        skynet.call(\"CLDB\", \"lua\", \"removetimeout\", " .. name .. ".name, key)");
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
if #arg < 2 then
    print("err:参数错误！！第一个参数是表配置目录，第二个参数是相关lua文件输出目录。")
    return
end
genDB.genTables();
--------------------------------------------
return genDB;
