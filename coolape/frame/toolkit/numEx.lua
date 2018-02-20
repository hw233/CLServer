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

-- 最小数值和最大数值指定返回值的范围。
-- @function [parent=#math] clamp
function numEx.clamp(v, minValue, maxValue)
    if v < minValue then
        return minValue
    end
    if( v > maxValue) then
        return maxValue
    end
    return v
end
return numEx
