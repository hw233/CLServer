do
    local KeyCodeProtocol = {}
    KeyCodeProtocol.map = {}
    local map = KeyCodeProtocol.map
    map[1] = "__session__"
    map[2] = "retInfor"
    map[10] = "msg"
    map[11] = "code"
    map[12] = "list"
    map[13] = "idx"
    map[14] = "name"
    map[15] = "status"
    map[16] = "getServers"
    map[17] = "appid"
    map[18] = "channceid"
    map[19] = "servers"
    map[20] = "login"
    map[21] = "userId"
    map[22] = "password"
    map[23] = "userInfor"
    map[24] = "regist"
    map[25] = "channel"
    map[26] = "deviceID"
    map[27] = "deviceInfor"
    map[0] = "cmd"
    map["code"] = 11
    map["servers"] = 19
    map["msg"] = 10
    map["userId"] = 21
    map["deviceInfor"] = 27
    map["cmd"] = 0
    map["login"] = 20
    map["list"] = 12
    map["idx"] = 13
    map["regist"] = 24
    map["__session__"] = 1
    map["deviceID"] = 26
    map["channel"] = 25
    map["retInfor"] = 2
    map["password"] = 22
    map["appid"] = 17
    map["getServers"] = 16
    map["userInfor"] = 23
    map["name"] = 14
    map["channceid"] = 18
    map["__currIndex__"] = 28
    map["status"] = 15
    

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