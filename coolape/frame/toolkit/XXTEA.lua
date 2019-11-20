--[[/*
******************************************************************************** 
  *Copyright(C),coolae.net 
  *Author:  chenbin
  *Version:  1.0 
  *Date:  2017-01-09
  *Description:  xxtea 一个非常快速小巧的加解密算法
  *						http://en.wikipedia.org/wiki/XXTEA
  *Others:  
  *History:
*********************************************************************************
*/ ]]
require("BitUtl")

local defaultKey = "coolape"

local function convertStringToBytes(str)
    local bytes = {}
    local strLength = #(str)
    for i = 1, strLength do
        table.insert(bytes, string.byte(str, i))
    end

    return bytes
end

local function convertBytesToString(bytes)
    local bytesLength = #(bytes)
    local str = {}
    for i = 1, bytesLength do
        table.insert(str, string.char(bytes[i]))
    end

    return table.concat(str)
end

local function convertToUInt32(value)
    if value < 0 then
        local absValue = math.abs(value)
        local a = math.modf(absValue / 0xFFFFFFFF)
        local b = value + a * 0xFFFFFFFF
        local c = 0xFFFFFFFF + b + 1
        return c
    end

    return math.fmod(value, 0xFFFFFFFF) - math.modf(value / 0xFFFFFFFF)
end

---@param Data Byte[]
---@param IncludeLength Boolean
local function ToUInt32Array(Data, IncludeLength)
    -- local n = (((#Data & 3) == 0) ? (Data.Length >> 2) : ((Data.Length >> 2) + 1));
    local n
    if BitUtl.andOp(#Data, 3) == 0 then
        n = BitUtl.rShiftOp(#Data, 2)
    else
        n = BitUtl.rShiftOp(#Data, 2) + 1
    end

    local Result = {}
    for i = 1, n do
        Result[i] = convertToUInt32(0)
    end
    if IncludeLength then
        Result[n + 1] = convertToUInt32(#Data)
    end

    n = #Data

    local _i
    for i = 0, n - 1 do
        -- Result [i >> 2] |= (UInt32)Data [i] << ((i & 3) << 3);
        _i = (BitUtl.rShiftOp(i, 2)) + 1
        Result[_i] =
            BitUtl.orOp(
            Result[_i],
            BitUtl.lShiftOp(convertToUInt32(Data[i + 1]), BitUtl.lShiftOp(BitUtl.andOp(i, 3), 3))
        )
    end
    return Result
end

---@param Data UInt32[]
---@param IncludeLength Boolean
local function ToByteArray(Data, IncludeLength)
    local n
    if IncludeLength then
        n = Data[#Data]
    else
        n = BitUtl.lShiftOp(#Data, 2)
    end
    local Result = {}
    local _i
    for i = 0, n - 1 do
        _i = BitUtl.rShiftOp(i, 2) + 1
        Result[i + 1] = BitUtl.rShiftOp(Data[_i], BitUtl.lShiftOp(BitUtl.andOp(i, 3), 3))
        Result[i + 1] = BitUtl.andOp(Result[i + 1], 0xff)
    end
    return Result
end

local function mx(sum, y, z, p, e, k)
    local aa = BitUtl.rShiftOp(z, 5)
    local ab = convertToUInt32(BitUtl.lShiftOp(y, 2))
    local ac = BitUtl.xorOp(aa, ab)

    local ba = BitUtl.rShiftOp(y, 3)
    local bb = convertToUInt32(BitUtl.lShiftOp(z, 4))
    local bc = BitUtl.xorOp(ba, bb)
    local ca = BitUtl.xorOp(sum, y)

    local dia = BitUtl.andOp(p, 3)
    local dib = BitUtl.xorOp(dia, e)
    local da = k[dib + 1]
    local db = BitUtl.xorOp(da, z)

    local ea = convertToUInt32(ca + db)
    local fa = convertToUInt32(ac + bc)
    local ga = BitUtl.xorOp(fa, ea)

    return convertToUInt32(ga)
end

---@param v UInt32[]
---@param k UInt32[]
local function EncryptInt32(v, k)
    local n = #v - 1
    if (n < 1) then
        return v
    end
    for i = #k + 1, 4 do
        table.insert(k, 0)
    end
    local z = v[n + 1]
    local y = v[1]
    local delta = 0x9E3779B9
    local sum = 0
    local e = 0
    local p
    local q = 6 + math.modf(52 / (n + 1))
    while (q > 0) do
        q = q - 1
        sum = convertToUInt32(sum + delta)
        e = BitUtl.andOp(BitUtl.rShiftOp(sum, 2), 3)
        for p = 0, n - 1 do
            y = v[p + 1 + 1]
            v[p + 1] = convertToUInt32(v[p + 1] + mx(sum, y, z, p, e, k))
            z = v[p + 1]
        end
        y = v[1]
        p = n
        v[n + 1] = convertToUInt32(v[n + 1] + mx(sum, y, z, p, e, k))
        z = v[n + 1]
    end
    return v
end

---@param v UInt32[]
---@param k UInt32[]
local function DecryptInt32(v, k)
    local n = #v - 1
    if n < 1 then
        return v
    end
    for i = #k + 1, 4 do
        table.insert(k, 0)
    end
    -- UInt32
    local z, y, delta, sum, e = v[n + 1], v[1], 0x9E3779B9, 0, 0
    local p
    local q = 6 + math.modf(52 / (n + 1))
    sum = convertToUInt32(q * delta)
    while (sum ~= 0) do
        e = BitUtl.andOp(BitUtl.rShiftOp(sum, 2), 3)
        for p = n, 1, -1 do
            z = v[p - 1 + 1]
            v[p + 1] = convertToUInt32(v[p + 1] - mx(sum, y, z, p, e, k))
            y = v[p + 1]
        end
        z = v[n + 1]
        p = 0
        v[1] = convertToUInt32(v[1] - mx(sum, y, z, p, e, k))
        y = v[1]
        sum = convertToUInt32(sum - delta)
    end
    return v
end

---@param DataStr string
---@param KeyStr string
local function Encrypt(DataStr, KeyStr)
    if CLUtl.isNilOrEmpty(DataStr) then
        return nil
    end
    KeyStr = KeyStr or defaultKey
    local keyBytes = nil
    keyBytes = convertStringToBytes(KeyStr)
    local databytes = convertStringToBytes(DataStr)

    if (#databytes == 0) then
        return databytes
    end
    local bytes = ToByteArray(EncryptInt32(ToUInt32Array(databytes, true), ToUInt32Array(keyBytes, false)), false)
    if bytes then
        return convertBytesToString(bytes)
    end
    return bytes
end

---@param Data byte[]
---@param KeyStr string
local function Decrypt(Data, KeyStr)
    if (#Data == 0) then
        return Data
    end
    KeyStr = KeyStr or defaultKey
    local keyBytes = convertStringToBytes(KeyStr)
    local databytes = convertStringToBytes(Data)
    local bytes = ToByteArray(DecryptInt32(ToUInt32Array(databytes, false), ToUInt32Array(keyBytes, false)), true)
    if bytes then
        return convertBytesToString(bytes)
    end
    return bytes
end

---@class XXTEA
XXTEA = {
    encrypt = Encrypt,
    decrypt = Decrypt,
    bytes2Str = convertBytesToString,
    str2Bytes = convertStringToBytes
}
