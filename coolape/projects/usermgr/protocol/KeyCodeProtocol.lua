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
    map[13] = "status"
    map[14] = "name"
    map[15] = "port"
    map[16] = "host"
    map[17] = "iosVer"
    map[18] = "androidVer"
    map[19] = "isnew"
    map[20] = "registAccount"
    map[21] = "userId"
    map[22] = "password"
    map[23] = "email"
    map[24] = "appid"
    map[25] = "channel"
    map[26] = "deviceID"
    map[27] = "deviceInfor"
    map[28] = "userInfor"
    map[29] = "serverid"
    map[30] = "systime"
    map[31] = "getServers"
    map[32] = "servers"
    map[33] = "getServerInfor"
    map[34] = "server"
    map[35] = "setEnterServer"
    map[36] = "sidx"
    map[37] = "uidx"
    map[38] = "loginAccount"
    map[39] = "loginAccountChannel"
    map["retInfor"] = 2
    map["msg"] = 10
    map["getServerInfor"] = 33
    map["deviceInfor"] = 27
    map["cmd"] = 0
    map["iosVer"] = 17
    map["servers"] = 32
    map["server"] = 34
    map["isnew"] = 19
    map["appid"] = 24
    map["name"] = 14
    map["loginAccount"] = 38
    map["__session__"] = 1
    map["systime"] = 30
    map["callback"] = 3
    map["port"] = 15
    map["channel"] = 25
    map["serverid"] = 29
    map["host"] = 16
    map["getServers"] = 31
    map["idx"] = 12
    map[0] = "cmd"
    map["__currIndex__"] = 40
    map["status"] = 13
    map["androidVer"] = 18
    map["setEnterServer"] = 35
    map["code"] = 11
    map["email"] = 23
    map["password"] = 22
    map["sidx"] = 36
    map["userId"] = 21
    map["userInfor"] = 28
    map["deviceID"] = 26
    map["registAccount"] = 20
    map["uidx"] = 37
    map["loginAccountChannel"] = 39
    

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