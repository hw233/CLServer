do
    local KeyCodeProtocol = {}
    KeyCodeProtocol.map = {}
    local map = KeyCodeProtocol.map
    map[1] = "__session__"
    map[2] = "retInfor"
    map[3] = "callback"
    map[10] = "msg"
    map[11] = "code"
    map[12] = "idx"
    map[13] = "diam"
    map[14] = "name"
    map[15] = "unionidx"
    map[16] = "cityidx"
    map[17] = "lev"
    map[18] = "status"
    map[19] = "encryptType"
    map[20] = "checkTimeStamp"
    map[21] = "secretKey"
    map[22] = "login"
    map[23] = "uidx"
    map[24] = "channel"
    map[25] = "deviceID"
    map[26] = "isEditMode"
    map[27] = "player"
    map[28] = "systime"
    map[29] = "session"
    map[30] = "heart"
    map[31] = "sendNetCfg"
    map[32] = "netCfg"
    map[0] = "cmd"
    map["secretKey"] = 21
    map["msg"] = 10
    map["cmd"] = 0
    map["__currIndex__"] = 35
    map["encryptType"] = 19
    map["logout"] = 34
    map["player"] = 27
    map["name"] = 14
    map["heart"] = 30
    map["session"] = 29
    map["__session__"] = 1
    map[33] = "onPlayerChg"
    map[34] = "logout"
    map["code"] = 11
    map["callback"] = 3
    map["lev"] = 17
    map["netCfg"] = 32
    map["login"] = 22
    map["checkTimeStamp"] = 20
    map["sendNetCfg"] = 31
    map["idx"] = 12
    map["isEditMode"] = 26
    map["uidx"] = 23
    map["unionidx"] = 15
    map["systime"] = 28
    map["diam"] = 13
    map["onPlayerChg"] = 33
    map["channel"] = 24
    map["cityidx"] = 16
    map["deviceID"] = 25
    map["retInfor"] = 2
    map["status"] = 18
    

    KeyCodeProtocol.getKeyCode = function(key)
        local val = map[key]
        if val == nil then
            map[key] = map.__currIndex__
            map[map.__currIndex__] = key
            map.__currIndex__ = map.__currIndex__ + 1
        end
        val = map[key]
        return val
    end
    return KeyCodeProtocol
end