---@class CLUtl 工具
CLUtl = {}
local table = table
local select = select
local smatch = string.match
local sfind = string.find
local insert = table.insert
local concat = table.concat

---@public 分割字符串
function CLUtl.strSplit(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    local i = 1
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end

function CLUtl.trim(s)
    -- return (s:gsub("^%s*(.-)%s*$", "%1"))
    return smatch(s, "^()%s*$") and "" or smatch(s, "^%s*(.*%S)") -- 性能略优
end

---@public 判断一个table是不是array
function CLUtl.isArray(t)
    if t == nil then
        return false
    end
    local ret = true
    if type(t) == "table" then
        local i = 0
        for _ in pairs(t) do
            i = i + 1
            if t[i] == nil then
                return false
            end
        end
    else
        ret = false
    end
    return ret
end

---@public 拼接两个路径
function CLUtl.combinePath(p1, p2)
    if p1 == nil then
        return p2
    end
    if p2 == nil then
        return p1
    end
    local last = string.sub(p1, string.len(p1))
    local first = string.sub(p2, 1)
    if (last == "/" and first ~= "/") or (last ~= "/" and first == "/") then
        return p1 .. p2
    elseif last == "/" and first == "/" then
        return string.sub(p1, 1, string.len(p1) - 1) .. p2
    elseif last ~= "/" and first ~= "/" then
        return p1 .. "/" .. p2
    else
        return p1 .. p2
    end
end

---@public 给定参数是nil或空字符串时，返回true
function CLUtl.isNilOrEmpty(s)
    if s == nil or s == "" then
        return true
    end
    return false
end

function CLUtl.dump(obj)
    local getIndent, quoteStr, wrapKey, wrapVal, dumpObj
    getIndent = function(level)
        return string.rep("\t", level)
    end
    quoteStr = function(str)
        return '"' .. string.gsub(str, '"', '\\"') .. '"'
    end
    wrapKey = function(val)
        if type(val) == "number" then
            return "[" .. val .. "]"
        elseif type(val) == "string" then
            return "[" .. quoteStr(val) .. "]"
        else
            return "[" .. tostring(val) .. "]"
        end
    end
    wrapVal = function(val, level)
        if type(val) == "table" then
            return dumpObj(val, level)
        elseif type(val) == "number" then
            return val
        elseif type(val) == "string" then
            return quoteStr(val)
        else
            return tostring(val)
        end
    end
    dumpObj = function(obj, level)
        if type(obj) ~= "table" then
            return wrapVal(obj)
        end
        level = level + 1
        local tokens = {}
        tokens[#tokens + 1] = "{"
        for k, v in pairs(obj) do
            tokens[#tokens + 1] = getIndent(level) .. wrapKey(k) .. " = " .. wrapVal(v, level) .. ","
        end
        tokens[#tokens + 1] = getIndent(level - 1) .. "}"
        return table.concat(tokens, "\n")
    end
    return dumpObj(obj, 0)
end

--==========================================
return CLUtl
