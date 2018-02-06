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
    map["retInfor"] = 2
    map["systime"] = 21
    map["__session__"] = 1
    map["msg"] = 10
    map["uidx"] = 17
    map[19] = "deviceID"
    map["deviceID"] = 19
    map[0] = "cmd"
    map["login"] = 16
    map[21] = "systime"
    map[24] = "icon"
    map["player"] = 20
    map["icon"] = 24
    map["__currIndex__"] = 26
    map["idx"] = 12
    map[17] = "uidx"
    map[18] = "channel"
    map["regist"] = 23
    map[20] = "player"
    map["logout"] = 15
    map[22] = "session"
    map[23] = "regist"
    map["stopserver"] = 25
    map[25] = "stopserver"
    map["name"] = 13
    map["channel"] = 18
    map["release"] = 14
    map["code"] = 11
    map["session"] = 22
    map["cmd"] = 0
    

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