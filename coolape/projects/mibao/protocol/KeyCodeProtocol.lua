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
    map[28] = "uid"
    map[29] = "session"
    map[30] = "platform"
    map[31] = "user"
    map[32] = "time"
    map[0] = "cmd"
    map["__currIndex__"] = 36
    map["newData"] = 25
    map["login"] = 17
    map["userInfor"] = 20
    map["cmd"] = 0
    map["psdInfors"] = 35
    map["machInfor"] = 27
    map["ver"] = 13
    map["time"] = 32
    map["desc"] = 34
    map["name"] = 14
    map["syndata"] = 22
    map["__session__"] = 1
    map["id"] = 12
    map[34] = "desc"
    map["psd"] = 33
    map["uid"] = 28
    map["sysTime"] = 21
    map["session"] = 29
    map["lev"] = 15
    map["platform"] = 30
    map["regist"] = 26
    map["user"] = 31
    map["newVer"] = 24
    map[35] = "psdInfors"
    map["logout"] = 16
    map["retInfor"] = 2
    map["data"] = 23
    map["password"] = 19
    map["userId"] = 18
    map["code"] = 11
    map["msg"] = 10
    map[33] = "psd"
    

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