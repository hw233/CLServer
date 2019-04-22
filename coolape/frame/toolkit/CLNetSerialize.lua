---@class CLNetSerialize
local CLNetSerialize = {}
---@class BioUtl
local BioUtl = require("BioUtl")
local BitUtl = require("BitUtl")
local strLen = string.len
local strSub = string.sub
local strPack = string.pack
local strbyte = string.byte
local strchar = string.char
local insert = table.insert
local concat = table.concat
local floor = math.floor
local maxPackSize = 64 * 1024 - 1
local subPackSize = 64 * 1024 - 1 - 50

local index = 0
local netCfg = {}
local ValidSecondsOffet = 3 * 1000 -- 允许的客户端时间与服务器时间之差
--============================================================
local EncryptType = {
    clientEncrypt = 1,
    serverEncrypt = 2,
    both = 3,
    none = 0
}

function CLNetSerialize.setCfg()
    --[[
        cfg.encryptType:加密类别，1：只加密客户端，2：只加密服务器，3：前后端都加密，0及其它情况：不加密
        cfg.secretKey:密钥
        cfg.checkTimeStamp:检测时间戳
    ]]
    netCfg = {}
    local len = numEx.nextInt(10, 30)
    local secretKey = {}
    for i = 1, len do
        local n = numEx.nextInt(32, 126)
        if n ~= 92 then
            -- 把返斜杠去掉
            insert(secretKey, strchar(n))
        end
    end
    netCfg.encryptType = EncryptType.clientEncrypt
    netCfg.secretKey = concat(secretKey)
    netCfg.checkTimeStamp = true
    return netCfg
end

function CLNetSerialize.getCfg()
    return netCfg
end

---@public 添加时间戳
function CLNetSerialize.addTimestamp(bytes)
    if bytes == nil then
        return nil
    end
    index = index + 1
    local ts = dateEx.nowMS() + index
    return BioUtl.number2bio(ts) .. bytes
end

---@public 安全加固
local securityReinforce = function(bytes)
    -- 服务器不需要加时间戳
    if
        netCfg.encryptType and
            (netCfg.encryptType == EncryptType.serverEncrypt or netCfg.encryptType == EncryptType.both)
     then
        bytes = CLNetSerialize.encrypt(bytes, netCfg.secretKey)
    end
    return bytes
end

---@public 检测数据安全性
local checkSecurity = function(bytes)
    local bytes2
    if
        netCfg.encryptType and
            (netCfg.encryptType == EncryptType.clientEncrypt or netCfg.encryptType == EncryptType.both)
     then
        bytes2 = CLNetSerialize.decrypt(bytes, netCfg.secretKey)
    else
        bytes2 = bytes
    end
    if netCfg.checkTimeStamp then
        local timestamp, readLen = BioUtl.readObject(bytes2)
        if timestamp == nil or readLen == nil or readLen == 0 then
            printe("read timestamp err!")
            return nil
        end
        if type(timestamp) ~= "number" or math.abs(dateEx.nowMS() - timestamp) > ValidSecondsOffet then
            -- 客户端上来的数据时间上有比较大的出入，直接丢弃
            printe("客户端上来的时间未取得，或有比较大的出入，直接丢弃")
            --//TODO:可以通知客户端重新修订一次时间
            return nil
        end
        bytes2 = strSub(bytes2, readLen + 1)
    end
    return bytes2
end
--============================================================
---@public 组包，返回的是list
function CLNetSerialize.package(pack)
    if pack == nil then
        return
    end
    local packList = {}
    local bytes = BioUtl.writeObject(pack)
    local len = strLen(bytes)
    if len > maxPackSize then
        local subPackgeCount = floor(len / subPackSize)
        local left = len % subPackSize
        local count = subPackgeCount
        if left > 0 then
            count = subPackgeCount + 1
        end
        for i = 1, subPackgeCount do
            local subPackg = {}
            subPackg.__isSubPack = true
            subPackg.count = count
            subPackg.i = i
            subPackg.content = strSub(bytes, ((i - 1) * subPackSize) + 1, i * subPackSize)
            local _bytes = securityReinforce(BioUtl.writeObject(subPackg))
            local package = strPack(">s2", _bytes)
            insert(packList, package)
        end
        if left > 0 then
            local subPackg = {}
            subPackg.__isSubPack = true
            subPackg.count = count
            subPackg.i = count
            subPackg.content = strSub(bytes, (subPackgeCount * subPackSize) + 1, subPackgeCount * subPackSize + left)
            local _bytes = securityReinforce(BioUtl.writeObject(subPackg))
            local package = strPack(">s2", _bytes)
            insert(packList, package)
        end
    else
        local _bytes = securityReinforce(bytes)
        local package = strPack(">s2", _bytes)
        insert(packList, package)
    end
    return packList
end

-- 完整的接口都是table，当有分包的时候会收到list。list[1]=共有几个分包，list[2]＝第几个分包，list[3]＝ 内容
local isSubPackage = function(m)
    if m.__isSubPack then
        --判断有没有cmd
        return true
    end
    return false
end

--============================================================
---@public 处理分包的情况
--[[ 
-- 完整的接口都是table，当有分包的时候会收到list。list[1]=共有几个分包，list[2]＝第几个分包，list[3]＝ 内容
--]]
local currPack = {}
function CLNetSerialize.unPackage(bytes)
    if bytes == nil then
        return nil
    end

    local bytes2 = checkSecurity(bytes)
    if bytes2 == nil then
        return nil
    end
    local m = BioUtl.readObject(bytes2)
    if m == nil then
        return nil
    end
    local map
    if isSubPackage(m) then
        -- 是分包
        local count = m.count
        local index = m.i
        currPack[index] = m.content
        if (#currPack == count) then
            -- 说明分包已经取完整
            local bytes = concat(currPack)
            map = BioUtl.readObject(bytes)
            currPack = {}
        -- procCmd(map)
        end
    else
        map = m
    end
    return map
end
--============================================================
local secretKey = ""
---@public 加密
function CLNetSerialize.encrypt(bytes, key)
    return CLNetSerialize.xor(bytes, key)
end

---@public 解密
function CLNetSerialize.decrypt(bytes, key)
    return CLNetSerialize.xor(bytes, key)
end

function CLNetSerialize.xor(bytes, key)
    key = key or secretKey
    if key == nil or key == "" then
        return bytes
    end
    local len = #bytes
    local keyLen = #key
    local byte, byte2
    local keyIdx = 0
    local result = {}
    for i = 1, len do
        byte = strbyte(bytes, i)
        keyIdx = i % keyLen + 1
        byte2 = BitUtl.xorOp(byte, strbyte(key, keyIdx))
        insert(result, strchar(byte2))
    end
    return concat(result)
end
return CLNetSerialize
