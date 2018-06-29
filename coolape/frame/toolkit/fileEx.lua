-- 文件处理
require("CLUtl")
---@class fileEx
fileEx = {}

-- 文件是否存在
function fileEx.exist(path)
    local f = io.open(path, "r")
    if f == nil then
        return false
    end
    return true
end

function fileEx.createDir(path)
    if path == nil or path == "" then return end
    os.execute("mkdir -p " .. path)
end

-- 取得目录列表
function fileEx.getDirs(path)
    local cmd = ""
    if path then
        cmd = "ls -l " .. path
    else
        cmd = "ls -l"
    end
    --io.popen 返回的是一个FILE，跟c里面的popen一样
    local s = io.popen(cmd)
    if s == nil then
        return {}
    end
    local fileLists = s:read("*all")

    local lines = CLUtl.strSplit(fileLists, "\n")

    local ret = {}
    local items
    for i,v in ipairs(lines) do
        if string.find(v, "d") == 1 then
            -- 说明是文件夹
            items = CLUtl.strSplit(v, " ")
            table.insert(ret, items[#items])
        end
    end
    return ret
end

-- 取得目录下文件列表
function fileEx.getFiles(path, suffix)
    local cmd = ""
    if path then
        cmd = "ls " .. path
    else
        cmd = "ls"
    end
    local ret = {}
    --io.popen 返回的是一个FILE，跟c里面的popen一样
    local s = io.popen(cmd)
    if s == nil then
        return {}
    end
    local fileLists = s:read("*all")
    --print(fileLists)

    local start_pos = 1
    local end_pos, line
    local pattern = ""
    if suffix and suffix ~= "" then
        pattern = "([^\n\r]+." .. suffix .. ")"
    else
        pattern = "([^\n\r]+)"
    end
    while true do
        --从文件列表里一行一行的获取文件名
        _, end_pos, line = string.find(fileLists, pattern, start_pos)
        if not end_pos then
            break
        end
        table.insert(ret, line)
        start_pos = end_pos + 1
    end
    return ret;
end

function fileEx.readAll(file_name)
    local f = io.open(file_name, 'r')
    if f == nil then
        return nil;
    end
    local string = f:read("*all")
    f:close()
    return string
end

function fileEx.writeAll(file_name, string)
    local f = assert(io.open(file_name, 'w'))
    if f == nil then
        return
    end
    f:write(string)
    f:close()
end

return fileEx
