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
    map[28] = "serverid"
    map[29] = "setEnterServer"
    map[30] = "sidx"
    map[31] = "uidx"
    map[32] = "getServerInfor"
    map[0] = "cmd"
    map["channceid"] = 18
    map["msg"] = 10
    map["userId"] = 21
    map["status"] = 15
    map["deviceID"] = 26
    map["iosVer"] = 38
    map["list"] = 12
    map["server"] = 33
    map["isnew"] = 34
    map["appid"] = 17
    map["getServers"] = 16
    map["loginAccount"] = 37
    map["androidVer"] = 39
    map[33] = "server"
    map[34] = "isnew"
    map["code"] = 11
    map[36] = "registAccount"
    map[37] = "loginAccount"
    map[38] = "iosVer"
    map[39] = "androidVer"
    map[40] = "loginAccountChannel"
    map["name"] = 14
    map["sidx"] = 30
    map["registAccount"] = 36
    map["serverid"] = 28
    map["userInfor"] = 23
    map["__session__"] = 1
    map["idx"] = 13
    map["__currIndex__"] = 41
    map["servers"] = 19
    map["retInfor"] = 2
    map[35] = "systime"
    map["setEnterServer"] = 29
    map["uidx"] = 31
    map["regist"] = 24
    map["password"] = 22
    map["systime"] = 35
    map["getServerInfor"] = 32
    map["channel"] = 25
    map["deviceInfor"] = 27
    map["cmd"] = 0
    map["login"] = 20
    map["loginAccountChannel"] = 40
    

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