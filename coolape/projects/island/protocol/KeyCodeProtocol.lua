do
    local KeyCodeProtocol = {}
    KeyCodeProtocol.map = {}
    local map = KeyCodeProtocol.map
    map[1] = "__session__"
    map[2] = "retInfor"
    map[10] = "msg"
    map[11] = "code"
    map[12] = "idx"
    map[13] = "name"
    map[14] = "release"
    map[15] = "logout"
    map[16] = "login"
    map[17] = "uidx"
    map[18] = "channel"
    map[19] = "deviceID"
    map[20] = "player"
    map[21] = "systime"
    map[22] = "session"
    map[23] = "regist"
    map[24] = "icon"
    map[25] = "stopserver"
    map[26] = "status"
    map[27] = "unionidx"
    map[28] = "cityidx"
    map[29] = "diam"
    map[30] = "lev"
    map[31] = "levpos"
    map[32] = "buildings"
    map[0] = "cmd"
    map["levidx"] = 36
    map["cityidx"] = 28
    map["val2idx"] = 39
    map["uidx"] = 17
    map["city"] = 44
    map["statuspos"] = 34
    map["pidx"] = 35
    map["levpos"] = 31
    map["logout"] = 15
    map[40] = "val3idx"
    map["val4idx"] = 41
    map["stopserver"] = 25
    map["player"] = 20
    map["name"] = 13
    map["attrididx"] = 42
    map["posidx"] = 43
    map[42] = "attrididx"
    map["session"] = 22
    map["pos"] = 33
    map["__session__"] = 1
    map[33] = "pos"
    map[34] = "statuspos"
    map["systime"] = 21
    map[36] = "levidx"
    map[37] = "validx"
    map[38] = "cidxidx"
    map[39] = "val2idx"
    map["lev"] = 30
    map[41] = "val4idx"
    map["login"] = 16
    map[43] = "posidx"
    map[44] = "city"
    map["val3idx"] = 40
    map["cidxidx"] = 38
    map["unionidx"] = 27
    map["idx"] = 12
    map["status"] = 26
    map["__currIndex__"] = 45
    map[35] = "pidx"
    map["validx"] = 37
    map["code"] = 11
    map["msg"] = 10
    map["icon"] = 24
    map["retInfor"] = 2
    map["diam"] = 29
    map["deviceID"] = 19
    map["channel"] = 18
    map["release"] = 14
    map["buildings"] = 32
    map["cmd"] = 0
    map["regist"] = 23
    

    KeyCodeProtocol.getKeyCode = function(key)
        local val = map[key]
        if val == nil then
            map[key] = map.__currIndex__
            map[map.__currIndex__] = key
            map.__currIndex__ = map.__currIndex__ + 1
        end
        val = map[key]
        return val;
    end
    return KeyCodeProtocol
end