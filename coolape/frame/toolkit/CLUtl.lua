-- 工具
do
    Utl = {}
    function Utl.strSplit(inputstr, sep)
        if sep == nil then
            sep = "%s"
        end
        local t = {}
        local i = 1
        for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
            t[i] = str
            i = i + 1
        end
        return t;
    end

    function Utl.isArray(t)
        if t == nil then
            return false;
        end
        local ret = true;
        if type(t) == "table" then
            local i = 0
            for _ in pairs(t) do
                i = i + 1
                if t[i] == nil then
                    return false
                end
            end
        else
            ret = false;
        end
        return ret;
    end

    function combinePath(p1, p2)
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

    return Utl;
end
