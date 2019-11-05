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
    local clientJSFilePath = "";
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
            add(content, "    map.callback = 3")
            add(content, "    map[3] = \"callback\"")
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
        add(content, "        return val")
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
        return defProtocol.name .. "." .. StructHead .. stName;
    end
    --===================================================
    --===================================================
    local function makeStruct(map, isInt2bio)
        local ret = {}
        add(ret, "    -- public toMap")
        add(ret, "    " .. defProtocol.name .. "._toMap = function(stuctobj, m)");
        add(ret, "        local ret = {}");
        add(ret, "        if m == nil then return ret end");
        add(ret, "        for k,v in pairs(m) do");
        add(ret, "            ret[k] = stuctobj.toMap(v)");
        add(ret, "        end");
        add(ret, "        return ret");
        add(ret, "    end");

        add(ret, "    -- public toList")
        add(ret, "    " .. defProtocol.name .. "._toList = function(stuctobj, m)");
        add(ret, "        local ret = {}");
        add(ret, "        if m == nil then return ret end");
        add(ret, "        for i,v in ipairs(m) do");
        add(ret, "            table.insert(ret, stuctobj.toMap(v))");
        add(ret, "        end");
        add(ret, "        return ret");
        add(ret, "    end");


        add(ret, "    -- public parse")
        add(ret, "    " .. defProtocol.name .. "._parseMap = function(stuctobj, m)");
        add(ret, "        local ret = {}");
        add(ret, "        if m == nil then return ret end");
        add(ret, "        for k,v in pairs(m) do");
        add(ret, "            ret[k] = stuctobj.parse(v)");
        add(ret, "        end");
        add(ret, "        return ret");
        add(ret, "    end");

        add(ret, "    -- public parse")
        add(ret, "    " .. defProtocol.name .. "._parseList = function(stuctobj, m)");
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
            add(ret, "    ---@class " .. getStName(name) .. " " .. val[1]);
            for k,v in pairs(val[2]) do
                local typeName = type(v[1])
                if typeName == "table" then
                    local stName = getKeyByVal(defProtocol.structs, v[1]);
                    if stName then
                        add(ret, "    ---@field public " .. k .. " " .. stName .. " " .. (v[2] or "" ));
                    else
                        add(ret, "    ---@field public " .. k .. " table " .. (v[2] or "" ));
                    end
                elseif typeName == "number" then
                    add(ret, "    ---@field public " .. k .. " number " .. (v[2] or "" ));
                elseif typeName == "string" then
                    add(ret, "    ---@field public " .. k .. " string " .. (v[2] or "" ));
                else
                    add(ret, "    ---@field public " .. k .. " useData " .. (v[2] or "" ));
                end
            end
            add(ret, "    " .. getStName(name) .. " = {");
            add(ret, "        toMap = function(m)")
            add(ret, "            local r = {}")
            add(ret, "            if m == nil then return r end");
            local typeName = ""
            for k, v in pairs(val[2]) do
                typeName = type(v[1])
                if typeName == "table" then
                    local stName = getKeyByVal(defProtocol.structs, v[1]);
                    if stName then
                        add(ret, "            r[" .. getKeyCode(k) .. "] = " .. getStName(stName) .. ".toMap(m." .. k .. ") -- " .. (v[2] or "" ))
                    else
                        local isList = isArray(v[1])
                        if isList then
                            stName = nil
                            stName = getKeyByVal(defProtocol.structs, v[1][1]);
                            if stName then
                                add(ret, "            r[" .. getKeyCode(k) .. "] = " .. defProtocol.name .. "._toList(" .. getStName(stName) .. ", m." .. k .. ")  -- " .. (v[2] or ""))
                            else
                                add(ret, "            r[" .. getKeyCode(k) .. "] = m." .. k .. "  -- " .. (v[2] or ""))
                            end
                        else
                            stName = nil;
                            for k2, v2 in pairs(v[1]) do
                                stName = getKeyByVal(defProtocol.structs, v2);
                                break;
                            end
                            if stName then
                                add(ret, "            r[" .. getKeyCode(k) .. "] = " .. defProtocol.name .. "._toMap(" .. getStName(stName) .. ", m." .. k .. ")  -- " .. (v[2] or ""))
                            else
                                add(ret, "            r[" .. getKeyCode(k) .. "] = m." .. k .. "  -- " .. (v[2] or ""))
                            end
                        end
                    end
                elseif typeName == "number" then
                    local minInt = math.floor(v[1]);
                    if minInt == v[1] then
                        -- 说明是整数
                        if isInt2bio then
                            -- 需要保存成bio形式
                            add(ret, "            r[" .. getKeyCode(k) .. "] =  BioUtl.number2bio(m." .. k .. ")  -- " .. (v[2] or "") .. " int")
                        else
                            add(ret, "            r[" .. getKeyCode(k) .. "] = m." .. k .. "  -- " .. (v[2] or "") .. " int")
                        end
                    else
                        add(ret, "            r[" .. getKeyCode(k) .. "] = m." .. k .. "  -- " .. (v[2] or "") .. " number")
                    end
                else
                    add(ret, "            r[" .. getKeyCode(k) .. "] = m." .. k .. "  -- " .. (v[2] or " ") .. " " .. typeName)
                end
            end
            add(ret, "            return r;")
            add(ret, "        end,")

            add(ret, "        parse = function(m)")
            add(ret, "            local r = {}")
            add(ret, "            if m == nil then return r end");
            local valueStr = ""
            for k, v in pairs(val[2]) do
                typeName = type(v[1])
                if defProtocol.compatibleJsonp then
                    valueStr = "m[" .. getKeyCode(k) .. "] or m[\"" .. getKeyCode(k) .. "\"]"
                else
                    valueStr = "m[" .. getKeyCode(k) .. "]"
                end
                if typeName == "table" then
                    local stName = getKeyByVal(defProtocol.structs, v[1]);
                    --assert(stName, "get struct name is null")
                    if stName then
                        add(ret, "            r." .. k .. " = " .. defProtocol.name .. "." .. StructHead .. stName .. ".parse(" .. valueStr .. ") -- " .. " " .. typeName )
                    else
                        local isList = isArray(v[1])
                        if isList then
                            stName = nil
                            stName = getKeyByVal(defProtocol.structs, v[1][1]);
                            if stName then
                                add(ret, "            r." .. k .. " = " .. defProtocol.name .. "._parseList(" .. getStName(stName) .. ", ".. valueStr .. ")  -- " .. (v[2] or ""))
                            else
                                add(ret, "            r." .. k .. " = ".. valueStr .. " -- " .. " " .. typeName )
                            end
                        else
                            stName = nil;
                            for k2, v2 in pairs(v[1]) do
                                stName = getKeyByVal(defProtocol.structs, v2);
                                break;
                            end
                            if stName then
                                add(ret, "            r." .. k .. " = " .. defProtocol.name .. "._parseMap(" .. getStName(stName) .. ", ".. valueStr .. ")  -- " .. (v[2] or ""))
                            else
                                add(ret, "            r." .. k .. " = ".. valueStr .. " -- " .. " " .. typeName )
                            end
                        end
                    end
                elseif typeName == "number" then
                    local minInt = math.floor(v[1]);
                    if minInt == v[1] then
                        add(ret, "            r." .. k .. " = ".. valueStr .. " -- " .. " int" )
                    else
                        add(ret, "            r." .. k .. " = ".. valueStr .. " -- " .. " " .. typeName )
                    end
                else
                    add(ret, "            r." .. k .. " = " .. valueStr .. " -- " .. " " .. typeName )
                end
            end
            add(ret, "            return r;")
            add(ret, "        end,")
            add(ret, "    }");
        end
        return table.concat(ret, "\n")
    end

    --===================================================
    local function makeStructJS(map, isInt2bio)
        local ret = {}
        add(ret, "    // public toMap")
        add(ret, "    " .. defProtocol.name .. "._toMap = function(stuctobj, m) {");
        add(ret, "        var ret = {};");
        add(ret, "        if (m == null) { return ret; }");
        add(ret, "        for(k in m) {");
        add(ret, "            ret[k] = stuctobj.toMap(m[k]);");
        add(ret, "        }");
        add(ret, "        return ret;");
        add(ret, "    };");

        add(ret, "    // public toList")
        add(ret, "    " .. defProtocol.name .. "._toList = function(stuctobj, m) {");
        add(ret, "        var ret = [];");
        add(ret, "        if (m == null) { return ret; }");
        add(ret, "        var count = m.length;")
        add(ret, "        for (var i = 0; i < count; i++) {");
        add(ret, "            ret.push(stuctobj.toMap(m[i]));");
        add(ret, "        }");
        add(ret, "        return ret;");
        add(ret, "    };");


        add(ret, "    // public parse")
        add(ret, "    " .. defProtocol.name .. "._parseMap = function(stuctobj, m) {");
        add(ret, "        var ret = {};");
        add(ret, "        if(m == null){ return ret; }");
        add(ret, "        for(k in m) {");
        add(ret, "            ret[k] = stuctobj.parse(m[k]);");
        add(ret, "        }");
        add(ret, "        return ret;");
        add(ret, "    };");

        add(ret, "    // public parse")
        add(ret, "    " .. defProtocol.name .. "._parseList = function(stuctobj, m) {");
        add(ret, "        var ret = [];");
        add(ret, "        if(m == null){return ret; }");
        add(ret, "        var count = m.length;")
        add(ret, "        for(var i = 0; i < count; i++) {");
        add(ret, "            ret.push(stuctobj.parse(m[i]));");
        add(ret, "        }");
        add(ret, "        return ret;");
        add(ret, "    };");
        add(ret, "  //==================================")
        add(ret, "  //==================================")

        for name, val in pairs(map) do
            add(ret, "    ///@class " .. getStName(name) .. " " .. val[1]);
            for k,v in pairs(val[2]) do
                local typeName = type(v[1])
                if typeName == "table" then
                    local stName = getKeyByVal(defProtocol.structs, v[1]);
                    if stName then
                        add(ret, "    ///@field public " .. k .. " " .. stName .. " " .. (v[2] or "" ));
                    else
                        add(ret, "    ///@field public " .. k .. " table " .. (v[2] or "" ));
                    end
                elseif typeName == "number" then
                    add(ret, "    ///@field public " .. k .. " number " .. (v[2] or "" ));
                elseif typeName == "string" then
                    add(ret, "    ///@field public " .. k .. " string " .. (v[2] or "" ));
                else
                    add(ret, "    ///@field public " .. k .. " useData " .. (v[2] or "" ));
                end
            end
            add(ret, "    " .. getStName(name) .. " = {");
            add(ret, "        toMap : function(m) {")
            add(ret, "            var r = {};")
            add(ret, "            if(m == null) { return r; }");
            local typeName = ""
            for k, v in pairs(val[2]) do
                typeName = type(v[1])
                if typeName == "table" then
                    local stName = getKeyByVal(defProtocol.structs, v[1]);
                    if stName then
                        add(ret, "            r[" .. getKeyCode(k) .. "] = " .. getStName(stName) .. ".toMap(m." .. k .. ") // " .. (v[2] or "" ))
                    else
                        local isList = isArray(v[1])
                        if isList then
                            stName = nil
                            stName = getKeyByVal(defProtocol.structs, v[1][1]);
                            if stName then
                                add(ret, "            r[" .. getKeyCode(k) .. "] = " .. defProtocol.name .. "._toList(" .. getStName(stName) .. ", m." .. k .. ")  // " .. (v[2] or ""))
                            else
                                add(ret, "            r[" .. getKeyCode(k) .. "] = m." .. k .. "  // " .. (v[2] or ""))
                            end
                        else
                            stName = nil;
                            for k2, v2 in pairs(v[1]) do
                                stName = getKeyByVal(defProtocol.structs, v2);
                                break;
                            end
                            if stName then
                                add(ret, "            r[" .. getKeyCode(k) .. "] = " .. defProtocol.name .. "._toMap(" .. getStName(stName) .. ", m." .. k .. ")  // " .. (v[2] or ""))
                            else
                                add(ret, "            r[" .. getKeyCode(k) .. "] = m." .. k .. "  // " .. (v[2] or ""))
                            end
                        end
                    end
                elseif typeName == "number" then
                    local minInt = math.floor(v[1]);
                    if minInt == v[1] then
                        -- 说明是整数
                        if isInt2bio then
                            -- 需要保存成bio形式
                            add(ret, "            r[" .. getKeyCode(k) .. "] =  BioUtl.number2bio(m." .. k .. ")  // " .. (v[2] or "") .. " int")
                        else
                            add(ret, "            r[" .. getKeyCode(k) .. "] = m." .. k .. "  // " .. (v[2] or "") .. " int")
                        end
                    else
                        add(ret, "            r[" .. getKeyCode(k) .. "] = m." .. k .. "  // " .. (v[2] or "") .. " number")
                    end
                else
                    add(ret, "            r[" .. getKeyCode(k) .. "] = m." .. k .. "  // " .. (v[2] or " ") .. " " .. typeName)
                end
            end
            add(ret, "            return r;")
            add(ret, "        },")

            add(ret, "        parse : function(m) {")
            add(ret, "            var r = {};")
            add(ret, "            if(m == null) { return r; }");
            for k, v in pairs(val[2]) do
                typeName = type(v[1])
                if typeName == "table" then
                    local stName = getKeyByVal(defProtocol.structs, v[1]);
                    --assert(stName, "get struct name is null")
                    if stName then
                        add(ret, "            r." .. k .. " = " .. defProtocol.name .. "." .. StructHead .. stName .. ".parse(m[" .. getKeyCode(k) .. "]) // " .. " " .. typeName )
                    else
                        local isList = isArray(v[1])
                        if isList then
                            stName = nil
                            stName = getKeyByVal(defProtocol.structs, v[1][1]);
                            if stName then
                                add(ret, "            r." .. k .. " = " .. defProtocol.name .. "._parseList(" .. getStName(stName) .. ", m[" .. getKeyCode(k) .. "])  // " .. (v[2] or ""))
                            else
                                add(ret, "            r." .. k .. " = m[" .. getKeyCode(k) .. "] // " .. " " .. typeName )
                            end
                        else
                            stName = nil;
                            for k2, v2 in pairs(v[1]) do
                                stName = getKeyByVal(defProtocol.structs, v2);
                                break;
                            end
                            if stName then
                                add(ret, "            r." .. k .. " = " .. defProtocol.name .. "._parseMap(" .. getStName(stName) .. ", m[" .. getKeyCode(k) .. "])  // " .. (v[2] or ""))
                            else
                                add(ret, "            r." .. k .. " = m[" .. getKeyCode(k) .. "] // " .. " " .. typeName )
                            end
                        end
                    end
                elseif typeName == "number" then
                    local minInt = math.floor(v[1]);
                    if minInt == v[1] then
                        add(ret, "            r." .. k .. " = m[" .. getKeyCode(k) .. "] // " .. " int" )
                    else
                        add(ret, "            r." .. k .. " = m[" .. getKeyCode(k) .. "] // " .. " " .. typeName )
                    end
                else
                    add(ret, "            r." .. k .. " = m[" .. getKeyCode(k) .. "] // " .. " " .. typeName )
                end
            end
            add(ret, "            return r;")
            add(ret, "        },")
            add(ret, "    }");
        end
        return table.concat(ret, "\n")
    end
    --===================================================
    --===================================================
    local function main()
        init();
        local strsClient = {}
        local strsClientJS = {}
        local strsServer = {}

        add(strsClientJS, "    var " .. defProtocol.name .. " = {}; // 网络协议");
        add(strsClientJS, "    " .. defProtocol.name .. ".__sessionID = 0; // 会话ID");
        add(strsClientJS, "    //==============================")
        add(strsClientJS, "    " .. defProtocol.name .. ".init = function(url) {")
        add(strsClientJS, "        " .. defProtocol.name .. ".url = url;")
        add(strsClientJS, "    };")
        add(strsClientJS, "    /*")
        add(strsClientJS, "    * 跨域调用")
        add(strsClientJS, "    * url:地址")
        add(strsClientJS, "    * params：参数")
        add(strsClientJS, "    * success：成功回调，（result, status, xhr）")
        add(strsClientJS, "    * error：失败回调，（jqXHR, textStatus, errorThrown）")
        add(strsClientJS, "    */")
        add(strsClientJS, "    " .. defProtocol.name .. ".call = function ( params, callback) {")
        add(strsClientJS, "        $.ajax({")
        add(strsClientJS, "            url: " .. defProtocol.name .. ".url,")
        add(strsClientJS, "            data: params,")
        add(strsClientJS, "            dataType: 'jsonp',")
        add(strsClientJS, "            crossDomain: true,")
        add(strsClientJS, "            jsonp:'callback',  //Jquery生成验证参数的名称")
        add(strsClientJS, "            success: function(result, status, xhr) { //成功的回调函数,")
        add(strsClientJS, "                if(callback != null) {")
        add(strsClientJS, "                    var cmd = result[0]")
        add(strsClientJS, "                    var dispatch = " .. defProtocol.name .. ".dispatch[cmd]")
        add(strsClientJS, "                    if(dispatch != null) {")
        add(strsClientJS, "                        callback(dispatch.onReceive(result), status, xhr)")
        add(strsClientJS, "                    }")
        add(strsClientJS, "                }")
        add(strsClientJS, "            },")
        add(strsClientJS, "            error: function(jqXHR, textStatus, errorThrown) {")
        add(strsClientJS, "                if(callback != null) {")
        add(strsClientJS, "                    callback(nil, textStatus, jqXHR)")
        add(strsClientJS, "                }")
        add(strsClientJS, "                console.log(textStatus + \":\" + errorThrown)")
        add(strsClientJS, "            }")
        add(strsClientJS, "        });")
        add(strsClientJS, "    }")

        add(strsClient, "do");
        add(strsServer, "do");
        add(strsClient, "    ---@class " .. defProtocol.name .. " 网络协议");
        add(strsServer, "    ---@class " .. defProtocol.name .. " 网络协议");
        add(strsClient, "    " .. defProtocol.name .. " = {}");
        add(strsServer, "    local " .. defProtocol.name .. " = {}");
        add(strsClient, "    local table = table");
        add(strsServer, "    local table = table");
        add(strsServer, "    local CMD = {}");
        add(strsClient, "    require(\"bio.BioUtl\")\n")
        add(strsServer, "    local skynet = require \"skynet\"\n")
        add(strsServer, "    require \"skynet.manager\"    -- import skynet.register")
        add(strsServer, "    require(\"BioUtl\")\n")
        add(strsClient, "    " .. defProtocol.name .. ".__sessionID = 0 -- 会话ID");
        add(strsClient, "    " .. defProtocol.name .. ".dispatch = {}");
        add(strsClientJS, "    " .. defProtocol.name .. ".dispatch = {};");
        add(strsClient, "    local __callbackInfor = {} -- 回调信息")
        add(strsClient, "    local __callTimes = 1")

        add(strsClient, "    ---@public 设计回调信息")
        add(strsClient, "    local setCallback = function (callback, orgs, ret)")
        add(strsClient, "       if callback then")
        add(strsClient, "           local callbackKey = os.time() + __callTimes")
        add(strsClient, "           __callTimes = __callTimes + 1")
        add(strsClient, "           __callbackInfor[callbackKey] = {callback, orgs}")
        add(strsClient, "           ret[3] = callbackKey")
        add(strsClient, "        end")
        add(strsClient, "    end")

        add(strsClient, "    ---@public 处理回调")
        add(strsClient, "    local doCallback = function(map, result)")
        add(strsClient, "        local callbackKey = map[3]")
        add(strsClient, "        if callbackKey then")
        add(strsClient, "            local cbinfor = __callbackInfor[callbackKey]")
        add(strsClient, "            if cbinfor then")
        add(strsClient, "                pcall(cbinfor[1], cbinfor[2], result)")
        add(strsClient, "            end")
        add(strsClient, "            __callbackInfor[callbackKey] = nil")
        add(strsClient, "        end")
        add(strsClient, "    end")

        add(strsServer, "    " .. defProtocol.name .. ".dispatch = {}");
        add(strsClient, "    --==============================");
        add(strsClientJS, "    //==============================");
        add(strsServer, "    --==============================");
        add(strsClient, makeStruct(defProtocol.structs, false));
        add(strsClientJS, makeStructJS(defProtocol.structs, false));
        add(strsServer, makeStruct(defProtocol.structs, defProtocol.isSendClientInt2bio));
        add(strsClient, "    --==============================");
        add(strsClientJS, "    //==============================");
        add(strsServer, "    --==============================");
        local dispatch = {}
        local dispatchJS = {}
        local requires = {}
        local dispatchserver = {}
        local clientSend = {}
        local clientSendJS = {}
        local serverSend = {}
        local clientRecive = {}
        local clientReciveJS = {}
        local serverRecive = {}
        local cmdMap = {}
        local cmdMapJS = {}
        for cmd, cfg in pairs(defProtocol.cmds) do
            requires[cfg.logic] = true;
            add(cmdMap, "        " .. cmd .. " = \"" .. cmd .. "\", -- " .. cfg.desc)
            add(cmdMapJS, "        " .. cmd .. " : \"" .. cmd .. "\", // " .. cfg.desc)
            add(dispatch, "    " .. defProtocol.name .. ".dispatch[" .. getKeyCode(cmd) .. "]={onReceive = " .. defProtocol.name .. ".recive." .. cmd .. ", send = " .. defProtocol.name .. ".send." .. cmd .. "}")
            add(dispatchJS, "    " .. defProtocol.name .. ".dispatch[" .. getKeyCode(cmd) .. "]={onReceive : " .. defProtocol.name .. ".recive." .. cmd .. ", send : " .. defProtocol.name .. ".send." .. cmd .. "}")
            add(dispatchserver, "    " .. defProtocol.name .. ".dispatch[" .. getKeyCode(cmd) .. "]={onReceive = " .. defProtocol.name .. ".recive." .. cmd .. ", send = " .. defProtocol.name .. ".send." .. cmd .. ", logicName = \"" .. cfg.logic .. "\"}")
            if cfg.desc then
                add(clientSend, "    -- " .. cfg.desc);
                add(clientSendJS, "    // " .. cfg.desc);
                add(serverRecive, "    -- " .. cfg.desc);
            end
            local inputParams = {}
            local outputParams = {}
            local toMapStrClient = {};
            local toMapStrClientJS = {};
            local toMapStrServer = {};
            local clientReciveParams = {}
            local clientReciveParamsJS = {}
            local clientReciveParamsFields = {}
            local clientReciveParamsFieldsJS = {}
            local serverReciveParams = {}
            local parmasTimes_ = {} -- 因为可能出现参数名相同的情况
            local getParamName = function(paramName)
                local times = parmasTimes_[paramName] or 1
                local ret = paramName
                if times > 1 then
                    ret = paramName .. times
                end
                parmasTimes_[paramName] = times + 1
                return ret
            end
            -- 入参处理
            if cfg.input then
                local inputDesList = {}
                if cfg.inputDesc then
                    inputDesList = cfg.inputDesc
                end

                for i, v2 in ipairs(cfg.input) do
                    local pname = v2;
                    local paramName = ""
                    local isList = false
                    if type(v2) == "table" then
                        pname = getKeyByVal(defProtocol.structs, v2)
                        if pname == nil or pname == "" then
                            isList = isArray(v2)
                            if isList then
                                -- 说明是list
                                local type2 = type(v2[1])
                                if type2 == "table" then
                                    pname = getKeyByVal(defProtocol.structs, v2[1])
                                    assert(pname, "get key by val is null==" .. i)
                                    paramName = getParamName(pname.. "s")
                                    add(toMapStrClient, "        ret[" .. getKeyCode(paramName) .. "] = " .. defProtocol.name .. "._toList(" .. getStName(pname) .. ", " .. paramName .. ")  -- " .. (inputDesList[i] or ""));
                                    add(toMapStrClientJS, "        ret[" .. getKeyCode(paramName) .. "] = " .. defProtocol.name .. "._toList(" .. getStName(pname) .. ", " .. paramName .. ")  // " .. (inputDesList[i] or ""));
                                else
                                    paramName = getParamName("list")
                                    add(toMapStrClient, "        ret[" .. getKeyCode(paramName) .. "] = " .. paramName .. " -- " .. (inputDesList[i] or ""));
                                    add(toMapStrClientJS, "        ret[" .. getKeyCode(paramName) .. "] = " .. paramName .. " // " .. (inputDesList[i] or ""));
                                end
                            end
                        else
                            paramName = getParamName(pname)
                            add(toMapStrClient, "        ret[" .. getKeyCode(paramName) .. "] = " .. defProtocol.name .. "." .. StructHead .. pname .. ".toMap(" .. paramName .. "); -- " .. (inputDesList[i] or ""));
                            add(toMapStrClientJS, "        ret[" .. getKeyCode(paramName) .. "] = " .. defProtocol.name .. "." .. StructHead .. pname .. ".toMap(" .. paramName .. "); // " .. (inputDesList[i] or ""));
                        end
                    else
                        paramName = getParamName(pname)
                        add(toMapStrClient, "        ret[" .. getKeyCode(paramName) .. "] = " .. paramName .. "; -- " .. (inputDesList[i] or ""));
                        add(toMapStrClientJS, "        ret[" .. getKeyCode(paramName) .. "] = " .. paramName .. "; // " .. (inputDesList[i] or ""));
                    end

                    -- if isList then
                    --     table.insert(inputParams, paramName)
                    -- else
                        table.insert(inputParams, paramName)
                    -- end

                    -- recive
                    local valueStr
                    if defProtocol.compatibleJsonp then
                        valueStr = "map[" .. getKeyCode(paramName) .. "] or map[\"" .. getKeyCode(paramName) .. "\"]"
                    else
                        valueStr = "map[" .. getKeyCode(paramName) .. "]"
                    end
                    if type(v2) == "table" then
                        if isList then
                            add(serverReciveParams, "        ret." .. paramName .. " = " .. defProtocol.name .. "._parseList(" .. getStName(pname) .. ", " .. valueStr .. ") -- " .. (inputDesList[i] or ""))
                        else
                            add(serverReciveParams, "        ret." .. paramName .. " = " .. defProtocol.name .. "." .. StructHead .. pname .. ".parse(" .. valueStr .. ") -- " .. (inputDesList[i] or ""));
                        end
                    else
                        add(serverReciveParams, "        ret." .. paramName .. " = " .. valueStr .. " -- " .. (inputDesList[i] or ""));
                    end
                end
            end
            --出参处理
            parmasTimes_ = {} -- 清空
            if cfg.output then
                local inputDesList = {}
                if cfg.outputDesc then
                    inputDesList = cfg.outputDesc
                end
                for i, v2 in ipairs(cfg.output) do
                    local pname = v2;
                    local paramName = ""
                    local isList = false
                    if type(v2) == "table" then
                        pname = getKeyByVal(defProtocol.structs, v2)
                        if pname == nil or pname == "" then
                            isList = isArray(v2)
                            if isList then
                                -- 说明是list
                                local type2 = type(v2[1])
                                if type2 == "table" then
                                    pname = getKeyByVal(defProtocol.structs, v2[1])
                                    print("get key by val is null==" .. i)
                                    assert(pname, "get key by val is null==" .. i)
                                    paramName = getParamName(pname .. "s")
                                    add(toMapStrServer, "        ret[" .. getKeyCode(paramName) .. "] = " .. defProtocol.name .. "._toList(" .. getStName(pname) .. ", " .. paramName .. ")  -- " .. (inputDesList[i] or ""));
                                else
                                    paramName = getParamName("list")
                                    add(toMapStrServer, "        ret[" .. getKeyCode(paramName) .. "] = "..paramName.." -- " .. (inputDesList[i] or ""));
                                end
                            else
                                print("err err err:not support this case!!!!!!!!!!!!!!!!")
                            end
                        else
                            paramName = getParamName(pname)
                            add(toMapStrServer, "        ret[" .. getKeyCode(pname) .. "] = " .. defProtocol.name .. "." .. StructHead .. pname .. ".toMap(" .. pname .. "); -- " .. (inputDesList[i] or ""));
                        end
                    else
                        paramName = getParamName(pname)
                        if defProtocol.isSendClientInt2bio then
                            add(toMapStrServer, "        if type(" .. paramName .. ") == \"number\" then")
                            add(toMapStrServer, "            ret[" .. getKeyCode(paramName) .. "] = BioUtl.number2bio(" .. paramName .. "); -- " .. (inputDesList[i] or ""));
                            add(toMapStrServer, "        else")
                            add(toMapStrServer, "            ret[" .. getKeyCode(paramName) .. "] = " .. paramName .. "; -- " .. (inputDesList[i] or ""));
                            add(toMapStrServer, "        end")
                        else
                            add(toMapStrServer, "        ret[" .. getKeyCode(paramName) .. "] = " .. paramName .. "; -- " .. (inputDesList[i] or ""));
                        end
                    end

                    -- if isList then
                    --     table.insert(outputParams, pname .. "s")
                    -- else
                        table.insert(outputParams, paramName)
                    -- end

                    -- recive
                    if type(v2) == "table" then
                        if isList then
                            -- local stName = pname .. "s"
                            add(clientReciveParamsFields, "    ---@field public " .. paramName .. " " .. getStName(pname) .. " Array List " .. (inputDesList[i] or ""))
                            add(clientReciveParamsFieldsJS, "    ///@field public " .. paramName .. " " .. getStName(pname) .. " Array List " .. (inputDesList[i] or ""))
                            add(clientReciveParams, "        ret." .. paramName .. " = " .. defProtocol.name .. "._parseList(" .. getStName(pname) .. ", map[" .. getKeyCode(paramName) .. "]) -- " .. (inputDesList[i] or ""))
                            add(clientReciveParamsJS, "        ret." .. paramName .. " = " .. defProtocol.name .. "._parseList(" .. getStName(pname) .. ", map[" .. getKeyCode(paramName) .. "]) // " .. (inputDesList[i] or ""))
                        else
                            add(clientReciveParamsFields, "    ---@field public " .. paramName .. " " .. getStName(pname) .. " " .. (inputDesList[i] or ""))
                            add(clientReciveParamsFieldsJS, "    ///@field public " .. paramName .. " " .. getStName(pname) .. " " .. (inputDesList[i] or ""))
                            add(clientReciveParams, "        ret." .. paramName .. " = " .. defProtocol.name .. "." .. StructHead .. pname .. ".parse(map[" .. getKeyCode(paramName) .. "]) -- " .. (inputDesList[i] or ""))
                            add(clientReciveParamsJS, "        ret." .. paramName .. " = " .. defProtocol.name .. "." .. StructHead .. pname .. ".parse(map[" .. getKeyCode(paramName) .. "]) // " .. (inputDesList[i] or ""))
                        end
                    else
                        add(clientReciveParamsFields, "    ---@field public " .. paramName .. "  " .. (inputDesList[i] or ""))
                        add(clientReciveParamsFieldsJS, "    ///@field public " .. paramName .. "  " .. (inputDesList[i] or ""))
                        add(clientReciveParams, "        ret." .. paramName .. " = " .. "map[" .. getKeyCode(paramName) .. "]-- " .. (inputDesList[i] or ""));
                        add(clientReciveParamsJS, "        ret." .. paramName .. " = " .. "map[" .. getKeyCode(paramName) .. "] // " .. (inputDesList[i] or ""));
                    end
                end
            end

            if #inputParams == 0 then
                -- 没有入参数
                add(clientSend, "    " .. cmd .. " = function(__callback, __orgs) -- __callback:接口回调, __orgs:回调参数");
                add(clientSendJS, "    " .. cmd .. " : function(callback) {");
            else
                add(clientSend, "    " .. cmd .. " = function(" .. table.concat(inputParams, ", ") .. ", __callback, __orgs) -- __callback:接口回调, __orgs:回调参数");
                add(clientSendJS, "    " .. cmd .. " : function(" .. table.concat(inputParams, ", ") .. ", callback) {");
            end

            if #outputParams == 0 then
                -- 没有入参数
                add(serverSend, "    " .. cmd .. " = function(mapOrig) -- mapOrig:客户端原始入参");
            else
                add(serverSend, "    " .. cmd .. " = function(" .. table.concat(outputParams, ", ") .. ", mapOrig) -- mapOrig:客户端原始入参");
            end

            add(clientSend, "        local ret = {}");
            add(clientSendJS, "        var ret = {};");
            add(serverSend, "        local ret = {}");
            add(clientSend, "        ret[" .. getKeyCode("cmd") .. "] = " .. getKeyCode(cmd));
            add(clientSendJS, "        ret[" .. getKeyCode("cmd") .. "] = " .. getKeyCode(cmd) ..";");
            add(serverSend, "        ret[" .. getKeyCode("cmd") .. "] = " .. getKeyCode(cmd));
            add(serverSend, "        ret[" .. getKeyCode("callback") .. "] = mapOrig and mapOrig.callback or nil");
            add(clientSend, "        ret[" .. getKeyCode("__session__") .. "] = " .. defProtocol.name .. ".__sessionID");
            add(clientSendJS, "        ret[" .. getKeyCode("__session__") .. "] = " .. defProtocol.name .. ".__sessionID;");
            if #toMapStrClient > 0 then
                add(clientSend, table.concat(toMapStrClient, "\n"));
                add(clientSendJS, table.concat(toMapStrClientJS, "\n"));
            end

            if #toMapStrServer > 0 then
                add(serverSend, table.concat(toMapStrServer, "\n"));
            end

            add(clientSend, "        setCallback(__callback, __orgs, ret)")
            add(clientSend, "        return ret");
            add(clientSendJS, "        " .. defProtocol.name .. ".call(ret, callback);");
            add(serverSend, "        return ret");
            add(clientSend, "    end,");
            add(clientSendJS, "    },");
            add(serverSend, "    end,");

            -- recive
            add(clientRecive, "    ---@class " .. defProtocol.name .. ".RC_" .. cmd)
            add(clientReciveJS, "    ///@class " .. defProtocol.name .. ".RC_" .. cmd)
            if #clientReciveParamsFields > 0 then
                add(clientRecive, table.concat(clientReciveParamsFields, "\n"));
                add(clientReciveJS, table.concat(clientReciveParamsFieldsJS, "\n"));
            end

            add(clientRecive, "    " .. cmd .. " = function(map)");
            add(clientReciveJS, "    " .. cmd .. " : function(map) {");
            add(clientRecive, "        local ret = {}");
            add(clientReciveJS, "        var ret = {};");
            add(clientRecive, "        ret.cmd = \"" .. cmd .. "\"");
            add(clientReciveJS, "        ret.cmd = \"" .. cmd .. "\";");
            if #clientReciveParams > 0 then
                add(clientRecive, table.concat(clientReciveParams, "\n"));
                add(clientReciveJS, table.concat(clientReciveParamsJS, "\n"));
            end

            add(clientRecive, "        doCallback(map, ret)")
            add(clientRecive, "        return ret");
            add(clientReciveJS, "        return ret;");
            add(clientRecive, "    end,");
            add(clientReciveJS, "    },");

            add(serverRecive, "    " .. cmd .. " = function(map)");
            add(serverRecive, "        local ret = {}");
            add(serverRecive, "        ret.cmd = \"" .. cmd .. "\"");
            add(serverRecive, "        ret.__session__ = map[" .. getKeyCode("__session__") .. "] or map[\"" .. getKeyCode("__session__") .. "\"]");
            add(serverRecive, "        ret.callback = map[" .. getKeyCode("callback") .. "]");
            if #serverReciveParams > 0 then
                add(serverRecive, table.concat(serverReciveParams, "\n"));
            end
            add(serverRecive, "        return ret");
            add(serverRecive, "    end,");
        end

        add(strsClient, "    " .. defProtocol.name .. ".send = {");
        add(strsClientJS, "    " .. defProtocol.name .. ".send = {");
        add(strsClient, table.concat(clientSend, "\n"));
        add(strsClientJS, table.concat(clientSendJS, "\n"));
        add(strsClient, "    }");
        add(strsClientJS, "    };");

        add(strsServer, "    " .. defProtocol.name .. ".recive = {");
        add(strsServer, table.concat(serverRecive, "\n"));
        add(strsServer, "    }");

        add(strsClient, "    --==============================");
        add(strsClientJS, "    //==============================");
        add(strsServer, "    --==============================");
        add(strsClient, "    " .. defProtocol.name .. ".recive = {");
        add(strsClientJS, "    " .. defProtocol.name .. ".recive = {");
        add(strsClient, table.concat(clientRecive, "\n"));
        add(strsClientJS, table.concat(clientReciveJS, "\n"));
        add(strsClient, "    }");
        add(strsClientJS, "    };");

        add(strsServer, "    " .. defProtocol.name .. ".send = {");
        add(strsServer, table.concat(serverSend, "\n"));
        add(strsServer, "    }");

        add(strsClient, "    --==============================");
        add(strsClientJS, "    //==============================");
        add(strsServer, "    --==============================");
        -- dispatch
        add(strsClient, table.concat(dispatch, "\n"));
        add(strsClientJS, table.concat(dispatchJS, "\n"));
        add(strsServer, table.concat(dispatchserver, "\n"));

        add(strsClient, "    --==============================");
        add(strsClientJS, "    //==============================");
        add(strsClient, "    " .. defProtocol.name .. ".cmds = {");
        add(strsClientJS, "    " .. defProtocol.name .. ".cmds = {");
        add(strsClient, table.concat(cmdMap, ",\n"))
        add(strsClientJS, table.concat(cmdMapJS, ",\n"))
        add(strsClient, "    }");
        add(strsClientJS, "    }");
        add(strsClient, "    --==============================");
        add(strsClientJS, "    //==============================");

        add(strsServer, "    --==============================");
        add(strsServer, "    " .. defProtocol.name .. ".cmds = {");
        add(strsServer, table.concat(cmdMap, ",\n"))
        add(strsServer, "    }");
        add(strsServer, "");

        add(strsServer, "    --==============================");
        add(strsServer, "    function CMD.dispatcher(agent, map, client_fd)")
        add(strsServer, "        if map == nil then")
        add(strsServer, "            skynet.error(\"[dispatcher] map == nil\")")
        add(strsServer, "            return nil")
        add(strsServer, "        end")
        add(strsServer, "        local cmd = map[0]")
        add(strsServer, "        if cmd == nil then")
        add(strsServer, "            skynet.error(\"get cmd is nil\")")
        add(strsServer, "            return nil;")
        add(strsServer, "        end")
        add(strsServer, "        local dis = " .. defProtocol.name .. ".dispatch[cmd]")
        add(strsServer, "        if dis == nil then")
        add(strsServer, "            skynet.error(\"get protocol cfg is nil\")")
        add(strsServer, "            return nil;")
        add(strsServer, "        end")
        add(strsServer, "        local m = dis.onReceive(map)")
        --add(strsServer, "        local logicCMD = assert(dis.logic.CMD)")
        add(strsServer, "        local logicProc = skynet.call(agent, \"lua\", \"getLogic\", dis.logicName)")
        add(strsServer, "        if logicProc == nil then")
        add(strsServer, "            skynet.error(\"get logicServe is nil. serverName=[\" .. dis.loginAccount ..\"]\")")
        add(strsServer, "            return nil")
        add(strsServer, "        else")
        add(strsServer, "            return skynet.call(logicProc, \"lua\", m.cmd, m, client_fd, agent)")
        add(strsServer, "        end")
        add(strsServer, "    end")
        add(strsServer, "    --==============================");

        add(strsClient, "    return " .. defProtocol.name .. "");
        --add(strsServer, "    return ".. defProtocol.name .."");

        add(strsServer, "    skynet.start(function()")
        add(strsServer, "        skynet.dispatch(\"lua\", function(_, _, command, command2, ...)")
        add(strsServer, "            if command == \"send\" then")
        add(strsServer, "                local f = " .. defProtocol.name .. ".send[command2]")
        add(strsServer, "                skynet.ret(skynet.pack(f(...)))")
        add(strsServer, "            else")
        add(strsServer, "                local f = CMD[command]")
        add(strsServer, "                skynet.ret(skynet.pack(f(command2, ...)))")
        add(strsServer, "            end")
        add(strsServer, "        end)")
        add(strsServer, "    ")
        add(strsServer, "        skynet.register \"" .. defProtocol.name .. "\"")
        add(strsServer, "    end)")
        add(strsClient, "end\n");
        add(strsServer, "end\n");

        --for k,v in pairs(requires) do
        --    table.insert(strsServer, 4, "    local " .. k .. " = require(\"logic.".. k .. "\")")
        --end

        --==================
        local strs = "";
        local file;
        strs = createKeyCodeFile(KeyCodeProtocol.map);
        file = io.open(keyCodeProtocolFile, "w")
        io.output(file)
        io.write(strs)
        io.close(file)

        strs = table.concat(strsServer, "\n")
        file = io.open(serverFilePath, "w")
        io.output(file)
        io.write(strs)
        io.close(file)

        if defProtocol.isGenLuaClientFile then
            strs = table.concat(strsClient, "\n")
            file = io.open(clientFilePath, "w")
            io.output(file)
            io.write(strs)
            io.close(file)
        end

        if defProtocol.isGenJsClientFile then
            strs = table.concat(strsClientJS, "\n")
            file = io.open(clientJSFilePath, "w")
            io.output(file)
            io.write(strs)
            io.close(file)
        end
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

    keyCodeProtocolFile = CLUtl.combinePath(arg[2], "KeyCodeProtocol.lua");
    clientFilePath = CLUtl.combinePath(arg[2], defProtocol.name .. "Client.lua");
    clientJSFilePath = CLUtl.combinePath(arg[2], defProtocol.name .. "Client.js");
    serverFilePath = CLUtl.combinePath(arg[2], defProtocol.name .. "Server.lua");
    main();
end
