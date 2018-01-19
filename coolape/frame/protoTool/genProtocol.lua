do
    --[[ run cmd
    ./3rd/lua/lua coolape/frame/protoTool/genProtocol.lua
    --]]
    package.cpath = "luaclib/?.so"
    package.path = "lualib/?.lua;" .. "./coolape/frame/toolkit/?.lua"

    require("CLUtl")
    local add = table.insert
    local KeyCodeProtocol;
    local getKeyCode;
    local defProtocol;
    --===================================================
    --===================================================
    local keyCodeProtocolFile = "";
    local clientFilePath = "";
    local serverFilePath = "";
    local StructHead = "ST_"
    --===================================================
    --===================================================
    -- 返回table是否为一个array， 第二返回值是table的count
    local function isArray(t)
        if t == nil then
            return false, 0;
        end
        local i = 0
        local ret = true;
        for _ in pairs(t) do
            i = i + 1
            if t[i] == nil then
                ret = false
            end
        end
        return ret, i
    end

    local function createKeyCodeFile(m)
        local content = {}
        add(content, "do")
        add(content, "    local KeyCodeProtocol = {}")
        add(content, "    KeyCodeProtocol.map = {}")
        add(content, "    local map = KeyCodeProtocol.map")
        if m then
            local key, val;
            for k, v in pairs(m) do
                key = type(k) == "string" and "\"" .. k .. "\"" or k
                val = type(v) == "string" and "\"" .. v .. "\"" or v
                add(content, "    map[" .. key .. "] = " .. val)
            end
        else
            add(content, "    map.cmd = 0")
            add(content, "    map[0] = \"cmd\"")
            add(content, "    map.__session__ = 1")
            add(content, "    map[1] = \"__session__\"")
            add(content, "    map.retInfor = 2")
            add(content, "    map[2] = \"retInfor\"")
            add(content, "    map.__currIndex__ = 10")
        end

        add(content, "    \n")
        add(content, "    KeyCodeProtocol.getKeyCode = function(key)")
        add(content, "        local val = map[key]")
        add(content, "        if val == nil then")
        add(content, "            map[key] = map.__currIndex__")
        add(content, "            map[map.__currIndex__] = key")
        add(content, "            map.__currIndex__ = map.__currIndex__ + 1")
        add(content, "        end")
        add(content, "        val = map[key]")
        add(content, "        return val;")
        add(content, "    end")

        add(content, "    return KeyCodeProtocol")
        add(content, "end")
        return table.concat(content, "\n");
    end

    --===================================================
    --===================================================
    local function init()
        --先判断文件是否存大
        local file, err = io.open(keyCodeProtocolFile, "r")
        --loadstring("do end")

        local content = "";
        if file then
            io.input(file)
            content = io.read("*a")
            io.close(file)
        else
            content = createKeyCodeFile()
        end

        KeyCodeProtocol = load(content)()
        getKeyCode = KeyCodeProtocol.getKeyCode
    end
    --===================================================
    --===================================================
    local function getKeyByVal(list, val)
        for k, v in pairs(list) do
            if v == val then
                return k;
            end
        end
        return nil;
    end

    local getStName = function(stName)
        return defProtocol.name .."." ..  StructHead.. stName;
    end
    --===================================================
    --===================================================
    local function makeStruct(map, isInt2bio)
        local ret = {}
        add(ret, "    -- public toMap")
        add(ret, "    ".. defProtocol.name .."._toMap = function(stuctobj, m)");
        add(ret, "        local ret = {}");
        add(ret, "        if m == nil then return ret end");
        add(ret, "        for k,v in pairs(m) do");
        add(ret, "            ret[k] = stuctobj.toMap(v)");
        add(ret, "        end");
        add(ret, "        return ret");
        add(ret, "    end");

        add(ret, "    -- public toList")
        add(ret, "    ".. defProtocol.name .."._toList = function(stuctobj, m)");
        add(ret, "        local ret = {}");
        add(ret, "        if m == nil then return ret end");
        add(ret, "        for i,v in ipairs(m) do");
        add(ret, "            table.insert(ret, stuctobj.toMap(v))");
        add(ret, "        end");
        add(ret, "        return ret");
        add(ret, "    end");


        add(ret, "    -- public parse")
        add(ret, "    ".. defProtocol.name .."._parseMap = function(stuctobj, m)");
        add(ret, "        local ret = {}");
        add(ret, "        if m == nil then return ret end");
        add(ret, "        for k,v in pairs(m) do");
        add(ret, "            ret[k] = stuctobj.parse(v)");
        add(ret, "        end");
        add(ret, "        return ret");
        add(ret, "    end");

        add(ret, "    -- public parse")
        add(ret, "    ".. defProtocol.name .."._parseList = function(stuctobj, m)");
        add(ret, "        local ret = {}");
        add(ret, "        if m == nil then return ret end");
        add(ret, "        for i,v in ipairs(m) do");
        add(ret, "            table.insert(ret, stuctobj.parse(v))");
        add(ret, "        end");
        add(ret, "        return ret");
        add(ret, "    end");
        add(ret, "  --==================================")
        add(ret, "  --==================================")

        for name, val in pairs(map) do
            add(ret, "    -- " .. val[1]);
            add(ret, "    ".. getStName(name) .. " = {");
            add(ret, "        toMap = function(m)")
            add(ret, "            local r = {}")
            add(ret, "            if m == nil then return r end");
            local typeName = ""
            for k, v in pairs(val[2]) do
                typeName = type(v[1])
                if typeName =="table" then
                    local stName = getKeyByVal(defProtocol.structs, v[1]);
                    if stName then
                        add(ret, "            r[" .. getKeyCode(k) .."] = ".. getStName(stName) .. ".toMap(m." .. k .. ") -- " .. (v[2] or "" ))
                    else
                        local isList = isArray(v[1])
                        if isList then
                            stName = nil
                            stName = getKeyByVal(defProtocol.structs, v[1][1]);
                            if stName then
                                add(ret, "            r[" .. getKeyCode(k) .."] = ".. defProtocol.name .."._toList(" .. getStName(stName) .. ", m." .. k .. ")  -- " .. (v[2] or ""))
                            else
                                add(ret, "            r[" .. getKeyCode(k) .."] = m." .. k .. "  -- " .. (v[2] or ""))
                            end
                        else
                            stName = nil;
                            for k2, v2 in pairs(v[1]) do
                                stName = getKeyByVal(defProtocol.structs, v2);
                                break;
                            end
                            if stName then
                                add(ret, "            r[" .. getKeyCode(k) .."] = ".. defProtocol.name .."._toMap(" .. getStName(stName) .. ", m." .. k .. ")  -- " .. (v[2] or ""))
                            else
                                add(ret, "            r[" .. getKeyCode(k) .."] = m." .. k .. "  -- " .. (v[2] or ""))
                            end
                        end
                    end
                elseif typeName =="number" then
                    local minInt = math.floor(v[1]);
                    if minInt == v[1] then
                        -- 说明是整数
                        if isInt2bio then
                            -- 需要保存成bio形式
                            add(ret, "            r[" .. getKeyCode(k) .."] =  BioUtl.int2bio(m." .. k .. ")  -- " .. (v[2] or "") .. " int")
                        else
                            add(ret, "            r[" .. getKeyCode(k) .."] = m." .. k .. "  -- " .. (v[2] or "") .. " int")
                        end
                    else
                        add(ret, "            r[" .. getKeyCode(k) .."] = m." .. k .. "  -- " .. (v[2] or "") .. " number")
                    end
                else
                    add(ret, "            r[" .. getKeyCode(k) .."] = m." .. k .. "  -- " .. (v[2] or " ") .. " " .. typeName)
                end
            end
            add(ret, "            return r;")
            add(ret, "        end,")

            add(ret, "        parse = function(m)")
            add(ret, "            local r = {}")
            add(ret, "            if m == nil then return r end");
            for k, v in pairs(val[2]) do
                typeName = type(v[1])
                if typeName =="table" then
                    local stName = getKeyByVal(defProtocol.structs, v[1]);
                    --assert(stName, "get struct name is null")
                    if stName then
                        add(ret, "            r." .. k .." = ".. defProtocol.name .."." ..  StructHead.. stName .. ".parse(m[" .. getKeyCode(k) .."]) -- " .. " " .. typeName )
                    else
                        local isList = isArray(v[1])
                        if isList then
                            stName = nil
                            stName = getKeyByVal(defProtocol.structs, v[1][1]);
                            if stName then
                                add(ret, "            r." .. k .." = ".. defProtocol.name .."._parseList(" .. getStName(stName) .. ", m." .. k .. ")  -- " .. (v[2] or ""))
                            else
                                add(ret, "            r." .. k .." = m[" .. getKeyCode(k) .."] -- "  .. " " .. typeName )
                            end
                        else
                            stName = nil;
                            for k2, v2 in pairs(v[1]) do
                                stName = getKeyByVal(defProtocol.structs, v2);
                                break;
                            end
                            if stName then
                                add(ret, "            r." .. k .." = ".. defProtocol.name .."._parseMap(" .. getStName(stName) .. ", m." .. k .. ")  -- " .. (v[2] or ""))
                            else
                                add(ret, "            r." .. k .." = m[" .. getKeyCode(k) .."] -- "  .. " " .. typeName )
                            end
                        end
                    end
                elseif typeName =="number" then
                    local minInt = math.floor(v[1]);
                    if minInt == v[1] then
                        add(ret, "            r." .. k .." = m[" .. getKeyCode(k) .."] -- "  .. " int" )
                    else
                        add(ret, "            r." .. k .." = m[" .. getKeyCode(k) .."] -- "  .. " " .. typeName )
                    end
                else
                    add(ret, "            r." .. k .." = m[" .. getKeyCode(k) .."] -- "  .. " " .. typeName )
                end
            end
            add(ret, "            return r;")
            add(ret, "        end,")
            add(ret, "    }");
        end
        return table.concat(ret, "\n")
    end
    --===================================================
    --===================================================
    local function main()
        init();
        local strsClient = {}
        local strsServer = {}
        add(strsClient, "do");
        add(strsServer, "do");
        add(strsClient, "    ".. defProtocol.name .." = {}");
        add(strsServer, "    ".. defProtocol.name .." = {}");
        add(strsClient, "    local table = table");
        add(strsServer, "    local table = table");
        add(strsClient, "    require(\"bio.BioUtl\")\n")
        add(strsServer, "    local skynet = require \"skynet\"\n")
        add(strsServer, "    require(\"BioUtl\")\n")
        add(strsClient, "    ".. defProtocol.name ..".__sessionID = 0; -- 会话ID");
        add(strsClient, "    ".. defProtocol.name ..".dispatch = {}");
        add(strsServer, "    ".. defProtocol.name ..".dispatch = {}");
        add(strsClient, "    --==============================");
        add(strsServer, "    --==============================");
        add(strsClient, makeStruct(defProtocol.structs, false));
        add(strsServer, makeStruct(defProtocol.structs, defProtocol.isSendClientInt2bio));
        add(strsClient, "    --==============================");
        add(strsServer, "    --==============================");
        local dispatch = {}
        local requires = {}
        local dispatchserver = {}
        local clientSend = {}
        local serverSend = {}
        local clientRecive = {}
        local serverRecive = {}
        for cmd, cfg in pairs(defProtocol.cmds) do
            requires[cfg.logic] = true;
            add(dispatch,       "    ".. defProtocol.name ..".dispatch[" .. getKeyCode(cmd) .. "]={onReceive = ".. defProtocol.name ..".recive." .. cmd .. ", send = ".. defProtocol.name ..".send." .. cmd .."}")
            add(dispatchserver, "    ".. defProtocol.name ..".dispatch[" .. getKeyCode(cmd) .. "]={onReceive = ".. defProtocol.name ..".recive." .. cmd .. ", send = ".. defProtocol.name ..".send." .. cmd ..", logic = " .. cfg.logic .. "}")
            if cfg.desc then
                add(clientSend, "    -- " .. cfg.desc);
                add(serverRecive, "    -- " .. cfg.desc);
            end
            local inputParams = {}
            local outputParams = {}
            local toMapStrClient = {};
            local toMapStrServer = {};
            local clientReciveParams = {}
            local serverReciveParams = {}
            if cfg.input then
                local inputDesList = {}
                if cfg.inputDesc then
                    inputDesList = cfg.inputDesc
                end

                for i, v2 in ipairs(cfg.input) do
                    local pname = v2;
                    local isList = false
                    if type(v2) == "table" then
                        pname = getKeyByVal(defProtocol.structs, v2)
                        if pname == nil or pname == "" then
                            isList = isArray(v2)
                            if isList then
                                -- 说明是list
                                local type2 = type(v2[1])
                                if type2 == "table"  then
                                    pname = getKeyByVal(defProtocol.structs, v2[1])
                                    assert(pname, "get key by val is null==" .. i)
                                    add(toMapStrClient, "        ret[" .. getKeyCode(pname .. "s") .. "] = ".. defProtocol.name .."._toList(" .. getStName(pname) .. ", " .. pname .. "s" .. ")  -- " .. (inputDesList[i] or ""));
                                else
                                    add(toMapStrClient, "        ret[" .. getKeyCode("list") .. "] = list -- " .. (inputDesList[i] or ""));
                                end
                            end
                        else
                            add(toMapStrClient, "        ret[" .. getKeyCode(pname) .. "] = ".. defProtocol.name .."." .. StructHead .. pname .. ".toMap(".. pname .."); -- " .. (inputDesList[i] or ""));
                        end
                    else
                        add(toMapStrClient, "        ret[" .. getKeyCode(pname) .. "] = " .. pname .. "; -- " .. (inputDesList[i] or ""));
                    end

                    if isList then
                        table.insert(inputParams, pname .. "s")
                    else
                        table.insert(inputParams, pname)
                    end

                    -- recive
                    if type(v2) == "table" then
                        if isList then
                            local stName = pname .. "s"
                            add(serverReciveParams, "        ret." .. stName .. " = ".. defProtocol.name .."._parseList(" .. getStName(pname) .. ", map[" .. getKeyCode(stName) .. "]) -- " .. (inputDesList[i] or ""))
                        else
                            add(serverReciveParams, "        ret." .. pname .. " = ".. defProtocol.name .."." .. StructHead .. pname .. ".parse(map[" .. getKeyCode(pname) .."]) -- " .. (inputDesList[i] or ""));
                        end
                    else
                        add(serverReciveParams, "        ret." .. pname .. " = " .. "map[" .. getKeyCode(pname) .."]-- " .. (inputDesList[i] or ""));
                    end
                end
            end

            if cfg.output then
                local inputDesList = {}
                if cfg.outputDesc then
                    inputDesList = cfg.outputDesc
                end

                for i, v2 in ipairs(cfg.output) do
                    local pname = v2;
                    local isList = false
                    if type(v2) == "table" then
                        pname = getKeyByVal(defProtocol.structs, v2)
                        if pname == nil or pname == "" then
                            isList = isArray(v2)
                            if isList then
                                -- 说明是list
                                local type2 = type(v2[1])
                                if type2 == "table"  then
                                    pname = getKeyByVal(defProtocol.structs, v2[1])
                                    assert(pname, "get key by val is null==" .. i)
                                    add(toMapStrServer, "        ret[" .. getKeyCode(pname .. "s") .. "] = ".. defProtocol.name .."._toList(" .. getStName(pname) .. ", " .. pname .. "s" .. ")  -- " .. (inputDesList[i] or ""));
                                else
                                    add(toMapStrServer, "        ret[" .. getKeyCode("list") .. "] = list -- " .. (inputDesList[i] or ""));
                                end
                            else
                                print("not support this case")
                            end
                        else
                            add(toMapStrServer, "        ret[" .. getKeyCode(pname) .. "] = ".. defProtocol.name .."." .. StructHead .. pname .. ".toMap(".. pname .."); -- " .. (inputDesList[i] or ""));
                        end
                    else
                        add(toMapStrServer, "        ret[" .. getKeyCode(pname) .. "] = " .. pname .. "; -- " .. (inputDesList[i] or ""));
                    end

                    if isList then
                        table.insert(outputParams, pname .. "s")
                    else
                        table.insert(outputParams, pname)
                    end

                    -- recive
                    if type(v2) == "table" then
                        if isList then
                            local stName = pname .. "s"
                            add(clientReciveParams, "        ret." .. stName .. " = ".. defProtocol.name .."._parseList(" .. getStName(pname) .. ", map[" .. getKeyCode(stName) .. "]) -- " .. (inputDesList[i] or ""))
                        else
                            add(clientReciveParams, "        ret." .. pname .. " = ".. defProtocol.name .."." .. StructHead .. pname .. ".parse(map[" .. getKeyCode(pname) .."]) -- " .. (inputDesList[i] or ""))
                        end
                    else
                        add(clientReciveParams, "        ret." .. pname .. " = " .. "map[" .. getKeyCode(pname) .."]-- " .. (inputDesList[i] or ""));
                    end
                end
            end

            if #inputParams == 0 then
                -- 没有入参数
                add(clientSend, "    " .. cmd .. " = function()");
            else
                add(clientSend, "    " .. cmd .. " = function(" .. table.concat(inputParams, ", ") .. ")");
            end

            if #outputParams == 0 then
                -- 没有入参数
                add(serverSend, "    " .. cmd .. " = function()");
            else
                add(serverSend, "    " .. cmd .. " = function(" .. table.concat(outputParams, ", ") .. ")");
            end

            add(clientSend, "        local ret = {}");
            add(serverSend, "        local ret = {}");
            add(clientSend, "        ret[" .. getKeyCode("cmd") .. "] = " .. getKeyCode(cmd));
            add(serverSend, "        ret[" .. getKeyCode("cmd") .. "] = " .. getKeyCode(cmd));
            add(clientSend, "        ret[" .. getKeyCode("__session__") .. "] = ".. defProtocol.name ..".__sessionID");
            if #toMapStrClient > 0 then
                add(clientSend, table.concat(toMapStrClient, "\n"));
            end

            if #toMapStrServer > 0 then
                add(serverSend, table.concat(toMapStrServer, "\n"));
            end
            add(clientSend, "        return ret");
            add(serverSend, "        return ret");
            add(clientSend, "    end,");
            add(serverSend, "    end,");

            -- recive
            add(clientRecive, "    " .. cmd .. " = function(map)");
            add(clientRecive, "        local ret = {}");
            add(clientRecive, "        ret.cmd = \"" .. cmd .. "\"");
            if #clientReciveParams > 0 then
                add(clientRecive, table.concat(clientReciveParams, "\n"));
            end
            add(clientRecive, "        return ret");
            add(clientRecive, "    end,");


            add(serverRecive, "    " .. cmd .. " = function(map)");
            add(serverRecive, "        local ret = {}");
            add(serverRecive, "        ret.cmd = \"" .. cmd .. "\"");
            add(serverRecive, "        ret.__session__ = map[" .. getKeyCode("__session__") .."]");
            if #serverReciveParams > 0 then
                add(serverRecive, table.concat(serverReciveParams, "\n"));
            end
            add(serverRecive, "        return ret");
            add(serverRecive, "    end,");
        end

        add(strsClient, "    ".. defProtocol.name ..".send = {");
        add(strsClient, table.concat(clientSend, "\n"));
        add(strsClient, "    }");

        add(strsServer, "    ".. defProtocol.name ..".recive = {");
        add(strsServer, table.concat(serverRecive, "\n"));
        add(strsServer, "    }");

        add(strsClient, "    --==============================");
        add(strsServer, "    --==============================");
        add(strsClient, "    ".. defProtocol.name ..".recive = {");
        add(strsClient, table.concat(clientRecive, "\n"));
        add(strsClient, "    }");

        add(strsServer, "    ".. defProtocol.name ..".send = {");
        add(strsServer, table.concat(serverSend, "\n"));
        add(strsServer, "    }");

        add(strsClient, "    --==============================");
        add(strsServer, "    --==============================");
        -- dispatch
        add(strsClient, table.concat(dispatch, "\n"));
        add(strsServer, table.concat(dispatchserver, "\n"));

        add(strsServer, "    --==============================");
        add(strsServer, "    function ".. defProtocol.name ..".dispatcher(map, client_fd)")
        add(strsServer, "        if map == nil then")
        add(strsServer, "            skynet.error(\"[dispatcher] mpa == nil\")")
        add(strsServer, "            return nil")
        add(strsServer, "        end")
        add(strsServer, "        local cmd = map[0]")
        add(strsServer, "        if cmd == nil then")
        add(strsServer, "            skynet.error(\"get cmd is nil\")")
        add(strsServer, "            return nil;")
        add(strsServer, "        end")
        add(strsServer, "        local dis = ".. defProtocol.name ..".dispatch[cmd]")
        add(strsServer, "        if dis == nil then")
        add(strsServer, "            skynet.error(\"get protocol cfg is nil\")")
        add(strsServer, "            return nil;")
        add(strsServer, "        end")
        add(strsServer, "        local m = dis.onReceive(map)")
        add(strsServer, "        local logicCMD = assert(dis.logic.CMD)")
        add(strsServer, "        local f = assert(logicCMD[m.cmd])")
        add(strsServer, "        if f then")
        add(strsServer, "            return f(m, client_fd)")
        add(strsServer, "        end")
        add(strsServer, "        return nil;")
        add(strsServer, "    end")
        add(strsServer, "    --==============================");

        add(strsClient, "    return ".. defProtocol.name .."");
        add(strsServer, "    return ".. defProtocol.name .."");
        add(strsClient, "end");
        add(strsServer, "end");

        for k,v in pairs(requires) do
            table.insert(strsServer, 3, "    local " .. k .. " = require(\"".. k .. "\")")
        end

        --==================
        local strs = "";
        local file;
        strs = createKeyCodeFile(KeyCodeProtocol.map);
        file = io.open(keyCodeProtocolFile, "w")
        io.output(file)
        io.write(strs)
        io.close(file)

        strs = table.concat(strsClient, "\n")
        file = io.open(clientFilePath, "w")
        io.output(file)
        io.write(strs)
        io.close(file)

        strs = table.concat(strsServer, "\n")
        file = io.open(serverFilePath, "w")
        io.output(file)
        io.write(strs)
        io.close(file)
        print("Finished")
    end
    --===================================================
    --===================================================
    if #arg < 2 then
        print("err:参数错误！！第一个参数是配置协议的lua文件，第二个参数是文件输出目录。")
        return
    end
    defProtocol = dofile(arg[1])
    if defProtocol == nil then
        print("err:加载配置协议的lua文件失败！")
        return
    end

    keyCodeProtocolFile = CLUtl.combinePath(arg[2] , "KeyCodeProtocol.lua");
    clientFilePath = CLUtl.combinePath(arg[2] , defProtocol.name .. "Client.lua");
    serverFilePath = CLUtl.combinePath(arg[2] , defProtocol.name .. "Server.lua");
    main();
end
