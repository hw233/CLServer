---@class CLNetSerialize
local CLNetSerialize = {}
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
            local package = strPack(">s2", BioUtl.writeObject(subPackg))
            insert(packList, package)
            -- socket.write(client_fd, package)
        end
        if left > 0 then
            local subPackg = {}
            subPackg.__isSubPack = true
            subPackg.count = count
            subPackg.i = count
            subPackg.content = strSub(bytes, (subPackgeCount * subPackSize) + 1, subPackgeCount * subPackSize + left)
            local package = strPack(">s2", BioUtl.writeObject(subPackg))
            insert(packList, package)
            -- socket.write(client_fd, package)
        end
    else
        local package = strPack(">s2", bytes)
        -- socket.write(client_fd, package)
        insert(packList, package)
    end
    return packList
end

-- 完整的接口都是table，当有分包的时候会收到list。list[1]=共有几个分包，list[2]＝第几个分包，list[3]＝ 内容
local isSubPackage = function (m)
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
    local bytes2
    if needDecrypt then
        bytes2 = CLNetSerialize.decrypt(bytes)
    else
        bytes2 = bytes
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
        currPack[index]= m.content
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
local secretKey = "coolape99"
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
