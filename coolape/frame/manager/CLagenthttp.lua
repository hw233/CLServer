local skynet = require "skynet"
require "skynet.manager"    -- import skynet.register
local sharedata = require "skynet.sharedata"
local urllib = require "http.url"
local fileEx = require "fileEx"
local httpc = require "http.httpc"
require("CLGlobal")
---@type CLUtl
local CLUtl = require("CLUtl")
local json = require("json")
local table = table
local string = string

local CMD = {}
local LogicMap = {}

-- ======================================================
local printhttp = function(url, method, header, body)
    local tmp = {}
    if header.host then
        table.insert(tmp, string.format("host: %s", header.host) .. "  " .. method)
    end
    local path, query = urllib.parse(url)
    table.insert(tmp, string.format("path: %s", path))
    if query then
        local q = urllib.parse_query(query)
        for k, v in pairs(q) do
            table.insert(tmp, string.format("query: %s= %s", k, v))
        end
    end
    table.insert(tmp, "-----header----")
    for k, v in pairs(header) do
        table.insert(tmp, string.format("%s = %s", k, v))
    end
    table.insert(tmp, "-----body----\n" .. body)
    local ret = table.concat(tmp, "\n")
    print(ret)
    return ret
end

local parseStrBody = function(body)
    local data = urllib.parse_query(body)
    return data
end

-- ======================================================
-- ======================================================
function CMD.onrequset(url, method, header, body)
    -- 有http请求
    --printhttp(url, method, header, body) -- debug log
    local path, query = urllib.parse(url)
    if method:upper() == "POST" then
        if path and path:lower() == "/frame/post" then
            if body then
                local content = parseStrBody(body)
                --TODO:
            else
                return nil
            end
        else
            local content = parseStrBody(body)
            -- TODO:
        end
    else
        if path == "/frame/stopserver" then
            -- 停服处理
            CMD.stop()
            return ""
        elseif path == "/frame/get" then
        elseif path == "/frame/manage" then
            -- 处理统一的get请求
            local requst = urllib.parse_query(query)
            local cmd = requst.cmd
            if CLUtl.isNilOrEmpty(cmd) then
                return "cmd == nil"
            end
            local cmdFunc = CMD[cmd]
            if cmdFunc == nil then
                printe("cannot deal the cmd==" .. cmd)
                return "cannot deal the cmd==" .. cmd
            end
            local ret = cmdFunc(requst)
            local jsoncallback = requst.callback
            if jsoncallback ~= nil then
                -- 说明ajax调用
                return jsoncallback .. "(" .. json.encode(ret) .. ")"
            else
                return json.encode(ret)
            end
        end
    end
end

-- 取得左边列表
function CMD.getLeftMenu (map)
    --local projectsInfor = sharedata.query("projectsInfor")
    local projectsInfor = skynet.call("CLDBCache", "lua", "get", "projectsInfor")
    if projectsInfor == nil then
        local dirs = fileEx.getDirs("coolape/projects")
        projectsInfor = {}
        local cfgPath = skynet.getenv("coolapeRoot") .. "projects/"
        for i, v in ipairs(dirs) do
            dofile(cfgPath .. v .. "/config_" .. v)
            local cfg = { key = v, name = projectDesc, consolePort = consolePort, httpPort = httpPort, socketPort = socketPort, logger = logger }
            projectsInfor[v] = cfg
        end
        --sharedata.new("projectsInfor", projectsInfor)
        skynet.call("CLDBCache", "lua", "set", "projectsInfor", projectsInfor)
    end
    return projectsInfor
end

---@public 启动服务器
function CMD.startServer(map)
    if map.projectName == nil then
        return "服务器名为nil"
    end
    --skynet.fork(
    --        function()
                local cmd = "./coolape/shell/start_" .. map.projectName .. ".sh"
                print(cmd)
                os.execute(cmd)
            --end)
    return { ret = true }
end

---@public 停止服务器
function CMD.stopServer(map)
    if map.projectName == nil then
        return "服务器名为nil"
    end
    --skynet.fork(
    --        function()
                local cmd = "./coolape/shell/stop_" .. map.projectName .. ".sh"
                print(cmd)
                os.execute(cmd)
            --end)
    return { ret = true }
end

---@public 取得服务器信息
function CMD.getProjectInfor(map)
    local projName = map.projectName
    if CLUtl.isNilOrEmpty(projName) then
        return "project name is nil"
    end

    local projects = skynet.call("CLDBCache", "lua", "get", "projectsInfor")
    if projects == nil then
        return "项目数据列表为空"
    end
    local projectCfg = projects[projName]
    if projectCfg == nil then
        return "项目数据为空"
    end

    local infor = projectCfg
    -- ===================================
    -- 取得当前服务器状态，是否启动
    local cmd = "ps -ef|grep config_" .. projName .. "|grep -v grep"
    local s = io.popen(cmd)
    if s == nil then
        infor.actived = false
    else
        local result = s:read("*all")
        s:close()
        if CLUtl.isNilOrEmpty(result) then
            infor.actived = false
        else
            infor.actived = true
        end
    end
    -- ===================================
    -- 取得日志大小
    if projectCfg.logger then
        cmd = "ls -l " .. projectCfg.logger .. " | awk '{print $5}'"
        s = io.popen(cmd)
        if s == nil then
            infor.logSize = 0
        else
            local result = s:read("*all")
            printe(result)
            s:close()
            infor.logSize = tonumber(result)
        end
    else
        infor.logSize = 0
    end
    if infor.actived then
        -- ===================================
        -- 服务器内存
        local ok, result, content = pcall(httpc.get, "127.0.0.1" .. ":" .. projectCfg.httpPort, "/" .. projName .. "/manage?cmd=memory")
        local memory = {}
        if ok and result == 200 then
            memory = json.decode(content)
        end
        -- ===================================
        -- 服务器状态
        local ok, result, content = pcall(httpc.get, "127.0.0.1" .. ":" .. projectCfg.httpPort, "/" .. projName .. "/manage?cmd=serviceStat")
        local stat = {}
        if ok and result == 200 then
            stat = json.decode(content)
        end
        -- ===================================
        -- 取得服务列表
        local ok, result, content = pcall(httpc.get, "127.0.0.1" .. ":" .. projectCfg.httpPort, "/" .. projName .. "/manage?cmd=serviceList")
        local serviceList = {}
        if ok and result == 200 then
            serviceList = json.decode(content)
        else
            serviceList = {}
        end

        -- ===================================
        -- wrap infor
        infor.serviceList = {}
        local totalMem = 0
        local totalCPU = 0
        for k, v in pairs(serviceList) do
            local serviceInfor = stat[k]
            serviceInfor = serviceInfor or {}
            serviceInfor.address = k
            serviceInfor.name = v
            local mem = 0
            if memory[k] then
                local strs = CLUtl.strSplit(memory[k], " ")
                if #strs > 0 then
                    mem = tonumber(strs[1])
                else
                    mem = 0
                end
            else
                mem = 0
            end
            serviceInfor.memory = mem
            totalMem = totalMem + mem
            totalCPU = totalCPU + (serviceInfor.cpu or 0)
            table.insert(infor.serviceList, serviceInfor)
        end
        infor.totalMem = totalMem
        infor.totalCPU = totalCPU
    end
    printe( CLUtl.dump(infor))
    return infor
end

---@public 停止服务
function CMD.stop()
    -- kill进程
    local projectname = skynet.getenv("projectName")
    local stopcmd = "ps -ef|grep config_" .. projectname .. "|grep -v grep |awk '{print $2}'|xargs -n1 kill -9"
    io.popen(stopcmd)
    --skynet.exit()
end

-- 取得逻辑处理类
function CMD.getLogic(logicName)
    local logic = LogicMap[logicName]
    if logic == nil then
        logic = skynet.newservice(logicName)
        LogicMap[logicName] = logic
    end
    return logic
end

-- ======================================================
skynet.start(function()
    skynet.dispatch("lua", function(_, _, command, ...)
        local f = CMD[command]
        skynet.ret(skynet.pack(f(...)))
    end)
end)
