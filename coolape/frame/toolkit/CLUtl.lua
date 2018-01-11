-- 工具
do
    Utl = {}
    function Utl.strSplit(inputstr, sep)
        if sep == nil then
            sep = "%s"
        end
        local t = {}
        local i = 1
        for str in string.gmatch(inputstr, "([^".. sep.. "]+)") do
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
    return Utl;
end
