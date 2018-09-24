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
    map[17] = "uidx"
    map[18] = "channel"
    map[19] = "deviceID"
    map[20] = "player"
    map[21] = "systime"
    map[22] = "session"
    map[23] = "regist"
    map[24] = "icon"
    map[25] = "stopserver"
    map[26] = "status"
    map[27] = "unionidx"
    map[28] = "cityidx"
    map[29] = "diam"
    map[30] = "lev"
    map[31] = "levpos"
    map[32] = "buildings"
    map[33] = "pos"
    map[34] = "statuspos"
    map[35] = "pidx"
    map[36] = "levidx"
    map[37] = "validx"
    map[38] = "cidxidx"
    map[39] = "val2idx"
    map[40] = "val3idx"
    map[41] = "val4idx"
    map[42] = "attrididx"
    map[43] = "posidx"
    map[44] = "city"
    map[45] = "tiles"
    map[46] = "attrid"
    map[47] = "cidx"
    map[48] = "val4"
    map[49] = "val3"
    map[50] = "val2"
    map[51] = "val"
    map[52] = "newBuilding"
    map[53] = "building"
    map[54] = "upLevBuilding"
    map[55] = "getBuilding"
    map[56] = "moveBuilding"
    map[57] = "moveTile"
    map[58] = "tile"
    map[59] = "heart"
    map[60] = "endTime"
    map[61] = "val5"
    map[62] = "startTime"
    map[63] = "state"
    map[64] = "endtime"
    map[65] = "starttime"
    map[66] = "oil"
    map[67] = "gold"
    map[68] = "food"
    map[69] = "onResChg"
    map[70] = "resInfor"
    map[71] = "onBuildingChg"
    map[72] = "onPlayerChg"
    map[73] = "onFinishBuildingUpgrade"
    map[74] = "newTile"
    map[75] = "rmTile"
    map["__currIndex__"] = 76
    map["msg"] = 10
    map["uidx"] = 17
    map["city"] = 44
    map["rmTile"] = 75
    map["moveBuilding"] = 56
    map["state"] = 63
    map["player"] = 20
    map["val2idx"] = 39
    map["moveTile"] = 57
    map["pos"] = 33
    map["stopserver"] = 25
    map["code"] = 11
    map["building"] = 53
    map["status"] = 26
    map["startTime"] = 62
    map["login"] = 16
    map["gold"] = 67
    map["validx"] = 37
    map["starttime"] = 65
    map["tiles"] = 45
    map["food"] = 68
    map["newTile"] = 74
    map["regist"] = 23
    map["val5"] = 61
    map["levpos"] = 31
    map["endtime"] = 64
    map["val3"] = 49
    map["statuspos"] = 34
    map["deviceID"] = 19
    map["resInfor"] = 70
    map["val3idx"] = 40
    map["attrid"] = 46
    map["levidx"] = 36
    map["getBuilding"] = 55
    map["tile"] = 58
    map["logout"] = 15
    map["attrididx"] = 42
    map["name"] = 13
    map["heart"] = 59
    map["cidxidx"] = 38
    map["__session__"] = 1
    map["unionidx"] = 27
    map["release"] = 14
    map["val"] = 51
    map["newBuilding"] = 52
    map["posidx"] = 43
    map["endTime"] = 60
    map["onResChg"] = 69
    map["buildings"] = 32
    map["onBuildingChg"] = 71
    map["retInfor"] = 2
    map["cityidx"] = 28
    map["oil"] = 66
    map["cmd"] = 0
    map["idx"] = 12
    map["icon"] = 24
    map["val4"] = 48
    map[0] = "cmd"
    map["cidx"] = 47
    map["pidx"] = 35
    map["val2"] = 50
    map["onFinishBuildingUpgrade"] = 73
    map["upLevBuilding"] = 54
    map["diam"] = 29
    map["val4idx"] = 41
    map["channel"] = 18
    map["session"] = 22
    map["lev"] = 30
    map["systime"] = 21
    map["onPlayerChg"] = 72
    

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