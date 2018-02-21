-- 数字
---@class numEx
numEx = {}

--取一个数的整数部分
function numEx.getIntPart(x)
    local flag = 1;
    if (x < 0) then
        flag = -1;
    end
    x = math.abs(x);
    x = math.floor(x);
    return flag * x;
end

return numEx
