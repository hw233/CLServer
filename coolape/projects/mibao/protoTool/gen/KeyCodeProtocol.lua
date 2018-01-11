do
    local KeyCodeProtocol = {}
    KeyCodeProtocol.map = {}
    local map = KeyCodeProtocol.map
    map[1] = "retInfor"
    map[0] = "cmd"
    map["newData"] = 25
    map["msg"] = 10
    map["userId"] = 18
    map["cmd"] = 0
    map[10] = "msg"
    map[11] = "code"
    map[12] = "id"
    map[13] = "ver"
    map["__currIndex__"] = 26
    map[15] = "lev"
    map[16] = "logout"
    map[17] = "login"
    map[18] = "userId"
    map[19] = "password"
    map[20] = "userInfor"
    map["logout"] = 16
    map[22] = "syndata"
    map[23] = "data"
    map[24] = "newVer"
    map[25] = "newData"
    map["name"] = 14
    map["syndata"] = 22
    map["__session__"] = -1
    map["code"] = 11
    map["data"] = 23
    map["lev"] = 15
    map["login"] = 17
    map["newVer"] = 24
    map["id"] = 12
    map["ver"] = 13
    map[14] = "name"
    map["password"] = 19
    map["userInfor"] = 20
    map["sysTime"] = 21
    map[21] = "sysTime"
    map["retInfor"] = 1
    map[-1] = "__session__"
    

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