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
    map[33] = "server"
    map[34] = "isnew"
    map[35] = "systime"
    map[36] = "registAccount"
    map[37] = "loginAccount"
    map[38] = "iosVer"
    map[39] = "androidVer"
    map[40] = "loginAccountChannel"
    map[41] = "port"
    map[42] = "host"
    map["registAccount"] = 36
    map["servers"] = 19
    map["msg"] = 10
    map["userId"] = 21
    map["deviceInfor"] = 27
    map["deviceID"] = 26
    map["sidx"] = 30
    map["list"] = 12
    map["server"] = 33
    map["isnew"] = 34
    map["__currIndex__"] = 43
    map["appid"] = 17
    map["getServers"] = 16
    map["loginAccount"] = 37
    map["status"] = 15
    map["androidVer"] = 39
    map["systime"] = 35
    map["port"] = 41
    map["loginAccountChannel"] = 40
    map["serverid"] = 28
    map[0] = "cmd"
    map["channel"] = 25
    map["idx"] = 13
    map["host"] = 42
    map["__session__"] = 1
    map["getServerInfor"] = 32
    map["code"] = 11
    map["setEnterServer"] = 29
    map["cmd"] = 0
    map["channceid"] = 18
    map["password"] = 22
    map["iosVer"] = 38
    map["uidx"] = 31
    map["userInfor"] = 23
    map["login"] = 20
    map["retInfor"] = 2
    map["name"] = 14
    map["regist"] = 24
    

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