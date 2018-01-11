do
    local KeyCodeProtocol = {}
    KeyCodeProtocol.map = {}
    local map = KeyCodeProtocol.map
    map[1] = "__session__"
    map[2] = "retInfor"
    map[10] = "msg"
    map[11] = "code"
    map[12] = "id"
    map[13] = "name"
    map[14] = "lev"
    map[15] = "city"
    map[16] = "isNew"
    map["__session__"] = 1
    map["code"] = 11
    map["__currIndex__"] = 26
    map["msg"] = 10
    map["isNew"] = 16
    map["retInfor"] = 2
    map["cmd"] = 0
    map["userId"] = 19
    map["city"] = 15
    map["sysTime"] = 22
    map[20] = "password"
    map["cityList"] = 24
    map["logout"] = 23
    map[24] = "cityList"
    map[23] = "logout"
    map[17] = "ver"
    map[18] = "login"
    map[19] = "userId"
    map["id"] = 12
    map[21] = "userInfor"
    map[22] = "sysTime"
    map["currCity"] = 25
    map["ver"] = 17
    map[25] = "currCity"
    map["name"] = 13
    map["userInfor"] = 21
    map[0] = "cmd"
    map["password"] = 20
    map["lev"] = 14
    map["login"] = 18
    

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