do
    local KeyCodeProtocol = {}
    KeyCodeProtocol.map = {}
    local map = KeyCodeProtocol.map
    map[1] = "__session__"
    map[2] = "retInfor"
    map[10] = "msg"
    map[11] = "code"
    map[12] = "id"
    map[13] = "ver"
    map[14] = "name"
    map[15] = "lev"
    map[16] = "logout"
    map[17] = "login"
    map[18] = "userId"
    map[19] = "password"
    map[20] = "userInfor"
    map[21] = "sysTime"
    map[22] = "syndata"
    map[23] = "data"
    map[24] = "newVer"
    map[25] = "newData"
    map[26] = "regist"
    map[27] = "machInfor"
    map["sysTime"] = 21
    map["newData"] = 25
    map["code"] = 11
    map["msg"] = 10
    map["data"] = 23
    map["cmd"] = 0
    map["login"] = 17
    map["newVer"] = 24
    map["__currIndex__"] = 28
    map["userId"] = 18
    map["regist"] = 26
    map["id"] = 12
    map["logout"] = 16
    map["machInfor"] = 27
    map[0] = "cmd"
    map["password"] = 19
    map["syndata"] = 22
    map["name"] = 14
    map["userInfor"] = 20
    map["retInfor"] = 2
    map["__session__"] = 1
    map["ver"] = 13
    map["lev"] = 15
    

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