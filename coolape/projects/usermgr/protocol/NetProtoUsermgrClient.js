    var NetProtoUsermgr = {} // 网络协议
    NetProtoUsermgr.__sessionID = 0 // 会话ID
    //==============================
    /*
    * 初始化
    * url:地址
    * beforeCallFunc:请求之前的回调
    * afterCallFunc:请求结束后的回调
    */
    NetProtoUsermgr.init = function(url, beforeCallFunc, afterCallFunc) {
        NetProtoUsermgr.url = url
        NetProtoUsermgr.beforeCallFunc = beforeCallFunc
        NetProtoUsermgr.afterCallFunc = afterCallFunc
    }
    /*
    * 跨域调用
    * url:地址
    * params：参数
    * success：成功回调，（result, status, xhr）
    * error：失败回调，（jqXHR, textStatus, errorThrown）
    */
    NetProtoUsermgr.call = function ( params, callback, httpType) {
        if(!httpType) {
            httpType = "GET"
        }
        if(NetProtoUsermgr.beforeCallFunc) {
            NetProtoUsermgr.beforeCallFunc()
        }
        $.ajax({
            type: httpType,
            url: NetProtoUsermgr.url,
            data: params,
            dataType: 'jsonp',
            crossDomain: true,
            jsonp:'callback',  //Jquery生成验证参数的名称
            success: function(result, status, xhr) { //成功的回调函数,
                if(NetProtoUsermgr.afterCallFunc) {
                    NetProtoUsermgr.afterCallFunc()
                }
                if(!result) {
                    console.log("result nil,cmd=" + params[0])
                } else {
                    if(callback) {
                        var cmd = result[0]
                        if(!cmd) {
                            console.log("get cmd is nil")
                        } else {
                            var dispatch = NetProtoUsermgr.dispatch[cmd]
                            if(!!dispatch) {
                                callback(dispatch.onReceive(result), status, xhr)
                            } else {
                                console.log("get dispatcher is nil")
                            }
                        }
                    }
                }
            },
            error: function(jqXHR, textStatus, errorThrown) {
                if(NetProtoUsermgr.afterCallFunc) {
                    NetProtoUsermgr.afterCallFunc()
                }
                if(callback) {
                    callback(null, textStatus, jqXHR)
                }
                console.log(textStatus + ":" + errorThrown)
            }
        })
    }
    NetProtoUsermgr.setSession = function(ss)
    {
        localStorage.setItem("NetProtoUsermgr.__sessionID", ss)
    }
    NetProtoUsermgr.getSession = function()
    {
        return localStorage.getItem("NetProtoUsermgr.__sessionID")
    }
    NetProtoUsermgr.removeSession = function()
    {
        localStorage.removeItem("NetProtoUsermgr.__sessionID")
    }
    NetProtoUsermgr.dispatch = {}
    //==============================
    // public toMap
    NetProtoUsermgr._toMap = function(stuctobj, m) {
        var ret = {}
        if (!m) { return ret }
        for(k in m) {
            ret[k] = stuctobj.toMap(m[k])
        }
        return ret
    }
    // public toList
    NetProtoUsermgr._toList = function(stuctobj, m) {
        var ret = []
        if (!m) { return ret }
        var count = m.length
        for (var i = 0 i < count i++) {
            ret.push(stuctobj.toMap(m[i]))
        }
        return ret
    }
    // public parse
    NetProtoUsermgr._parseMap = function(stuctobj, m) {
        var ret = {}
        if(!m){ return ret }
        for(k in m) {
            ret[k] = stuctobj.parse(m[k])
        }
        return ret
    }
    // public parse
    NetProtoUsermgr._parseList = function(stuctobj, m) {
        var ret = []
        if(!m){return ret }
        var count = m.length
        for(var i = 0 i < count i++) {
            ret.push(stuctobj.parse(m[i]))
        }
        return ret
    }
  //==================================
  //==================================
    ///@class NetProtoUsermgr.ST_retInfor 返回信息
    ///@field public msg string 返回消息
    ///@field public code number 返回值
    NetProtoUsermgr.ST_retInfor = {
        toMap : function(m) {
            var r = {}
            if(!m) { return r }
            r[10] = m.msg  // 返回消息 string
            r[11] = m.code  // 返回值 int
            return r
        },
        parse : function(m) {
            var r = {}
            if(!m) { return r }
            r.msg = m[10] //  string
            r.code = m[11] //  int
            return r
        },
    }
    ///@class NetProtoUsermgr.ST_server 服务器
    ///@field public idx number id
    ///@field public port number 端口
    ///@field public name string 名称
    ///@field public host string ip地址
    ///@field public iosVer string 客户端ios版本
    ///@field public androidVer string 客户端android版本
    ///@field public isnew useData 新服
    ///@field public status number 状态 1:正常; 2:爆满; 3:维护
    NetProtoUsermgr.ST_server = {
        toMap : function(m) {
            var r = {}
            if(!m) { return r }
            r[12] = m.idx  // id int
            r[15] = m.port  // 端口 int
            r[14] = m.name  // 名称 string
            r[16] = m.host  // ip地址 string
            r[17] = m.iosVer  // 客户端ios版本 string
            r[18] = m.androidVer  // 客户端android版本 string
            r[19] = m.isnew  // 新服 boolean
            r[13] = m.status  // 状态 1:正常; 2:爆满; 3:维护 int
            return r
        },
        parse : function(m) {
            var r = {}
            if(!m) { return r }
            r.idx = m[12] //  int
            r.port = m[15] //  int
            r.name = m[14] //  string
            r.host = m[16] //  string
            r.iosVer = m[17] //  string
            r.androidVer = m[18] //  string
            r.isnew = m[19] //  boolean
            r.status = m[13] //  int
            return r
        },
    }
    ///@class NetProtoUsermgr.ST_userInfor 用户信息
    ///@field public idx number 唯一标识
    NetProtoUsermgr.ST_userInfor = {
        toMap : function(m) {
            var r = {}
            if(!m) { return r }
            r[12] = m.idx  // 唯一标识 int
            return r
        },
        parse : function(m) {
            var r = {}
            if(!m) { return r }
            r.idx = m[12] //  int
            return r
        },
    }
    //==============================
    NetProtoUsermgr.send = {
    // 注册
    registAccount : function(userId, password, email, appid, channel, deviceID, deviceInfor, callback) {
        var ret = {}
        ret[0] = 20
        ret[1] = NetProtoUsermgr.getSession()
        ret[21] = userId // 用户名
        ret[22] = password // 密码
        ret[23] = email // 邮箱
        ret[24] = appid // 应用id
        ret[25] = channel // 渠道号
        ret[26] = deviceID // 机器码
        ret[27] = deviceInfor // 机器信息
        NetProtoUsermgr.call(ret, callback, null)
    },
    // 取得服务器列表
    getServers : function(appid, channel, callback) {
        var ret = {}
        ret[0] = 31
        ret[1] = NetProtoUsermgr.getSession()
        ret[24] = appid // 应用id
        ret[25] = channel // 渠道号
        NetProtoUsermgr.call(ret, callback, null)
    },
    // session是否有效
    isSessionAlived : function(callback) {
        var ret = {}
        ret[0] = 41
        ret[1] = NetProtoUsermgr.getSession()
        NetProtoUsermgr.call(ret, callback, null)
    },
    // 取得服务器信息
    getServerInfor : function(idx, callback) {
        var ret = {}
        ret[0] = 33
        ret[1] = NetProtoUsermgr.getSession()
        ret[12] = idx // 服务器id
        NetProtoUsermgr.call(ret, callback, null)
    },
    // 保存所选服务器
    setEnterServer : function(sidx, uidx, appid, callback) {
        var ret = {}
        ret[0] = 35
        ret[1] = NetProtoUsermgr.getSession()
        ret[36] = sidx // 服务器id
        ret[37] = uidx // 用户id
        ret[24] = appid // 应用id
        NetProtoUsermgr.call(ret, callback, null)
    },
    // 登陆
    loginAccount : function(userId, password, appid, channel, callback) {
        var ret = {}
        ret[0] = 38
        ret[1] = NetProtoUsermgr.getSession()
        ret[21] = userId // 用户名
        ret[22] = password // 密码
        ret[24] = appid // 应用id int
        ret[25] = channel // 渠道号 string
        NetProtoUsermgr.call(ret, callback, null)
    },
    // 渠道登陆
    loginAccountChannel : function(userId, appid, channel, deviceID, deviceInfor, callback) {
        var ret = {}
        ret[0] = 39
        ret[1] = NetProtoUsermgr.getSession()
        ret[21] = userId // 用户名
        ret[24] = appid // 应用id int
        ret[25] = channel // 渠道号 string
        ret[26] = deviceID // 
        ret[27] = deviceInfor // 
        NetProtoUsermgr.call(ret, callback, null)
    },
    }
    //==============================
    NetProtoUsermgr.recive = {
    ///@class NetProtoUsermgr.RC_registAccount
    ///@field public retInfor NetProtoUsermgr.ST_retInfor 返回信息
    ///@field public userInfor NetProtoUsermgr.ST_userInfor 用户信息
    ///@field public serverid  服务器id int
    ///@field public systime  系统时间 long
    ///@field public session  会话id
    registAccount : function(map) {
        var ret = {}
        ret.cmd = "registAccount"
        ret.retInfor = NetProtoUsermgr.ST_retInfor.parse(map[2]) // 返回信息
        ret.userInfor = NetProtoUsermgr.ST_userInfor.parse(map[28]) // 用户信息
        ret.serverid = map[29] // 服务器id int
        ret.systime = map[30] // 系统时间 long
        ret.session = map[40] // 会话id
        return ret
    },
    ///@class NetProtoUsermgr.RC_getServers
    ///@field public retInfor NetProtoUsermgr.ST_retInfor 返回信息
    ///@field public servers NetProtoUsermgr.ST_server Array List 服务器列表
    getServers : function(map) {
        var ret = {}
        ret.cmd = "getServers"
        ret.retInfor = NetProtoUsermgr.ST_retInfor.parse(map[2]) // 返回信息
        ret.servers = NetProtoUsermgr._parseList(NetProtoUsermgr.ST_server, map[32]) // 服务器列表
        return ret
    },
    ///@class NetProtoUsermgr.RC_isSessionAlived
    ///@field public retInfor NetProtoUsermgr.ST_retInfor 返回信息
    isSessionAlived : function(map) {
        var ret = {}
        ret.cmd = "isSessionAlived"
        ret.retInfor = NetProtoUsermgr.ST_retInfor.parse(map[2]) // 返回信息
        return ret
    },
    ///@class NetProtoUsermgr.RC_getServerInfor
    ///@field public retInfor NetProtoUsermgr.ST_retInfor 返回信息
    ///@field public server NetProtoUsermgr.ST_server 服务器信息
    getServerInfor : function(map) {
        var ret = {}
        ret.cmd = "getServerInfor"
        ret.retInfor = NetProtoUsermgr.ST_retInfor.parse(map[2]) // 返回信息
        ret.server = NetProtoUsermgr.ST_server.parse(map[34]) // 服务器信息
        return ret
    },
    ///@class NetProtoUsermgr.RC_setEnterServer
    ///@field public retInfor NetProtoUsermgr.ST_retInfor 返回信息
    setEnterServer : function(map) {
        var ret = {}
        ret.cmd = "setEnterServer"
        ret.retInfor = NetProtoUsermgr.ST_retInfor.parse(map[2]) // 返回信息
        return ret
    },
    ///@class NetProtoUsermgr.RC_loginAccount
    ///@field public retInfor NetProtoUsermgr.ST_retInfor 返回信息
    ///@field public userInfor NetProtoUsermgr.ST_userInfor 用户信息
    ///@field public serverid  服务器id int
    ///@field public systime  系统时间 long
    ///@field public session  会话id
    loginAccount : function(map) {
        var ret = {}
        ret.cmd = "loginAccount"
        ret.retInfor = NetProtoUsermgr.ST_retInfor.parse(map[2]) // 返回信息
        ret.userInfor = NetProtoUsermgr.ST_userInfor.parse(map[28]) // 用户信息
        ret.serverid = map[29] // 服务器id int
        ret.systime = map[30] // 系统时间 long
        ret.session = map[40] // 会话id
        return ret
    },
    ///@class NetProtoUsermgr.RC_loginAccountChannel
    ///@field public retInfor NetProtoUsermgr.ST_retInfor 返回信息
    ///@field public userInfor NetProtoUsermgr.ST_userInfor 用户信息
    ///@field public serverid  服务器id int
    ///@field public systime  系统时间 long
    ///@field public session  会话id
    loginAccountChannel : function(map) {
        var ret = {}
        ret.cmd = "loginAccountChannel"
        ret.retInfor = NetProtoUsermgr.ST_retInfor.parse(map[2]) // 返回信息
        ret.userInfor = NetProtoUsermgr.ST_userInfor.parse(map[28]) // 用户信息
        ret.serverid = map[29] // 服务器id int
        ret.systime = map[30] // 系统时间 long
        ret.session = map[40] // 会话id
        return ret
    },
    }
    //==============================
    NetProtoUsermgr.dispatch[20]={onReceive : NetProtoUsermgr.recive.registAccount, send : NetProtoUsermgr.send.registAccount}
    NetProtoUsermgr.dispatch[31]={onReceive : NetProtoUsermgr.recive.getServers, send : NetProtoUsermgr.send.getServers}
    NetProtoUsermgr.dispatch[41]={onReceive : NetProtoUsermgr.recive.isSessionAlived, send : NetProtoUsermgr.send.isSessionAlived}
    NetProtoUsermgr.dispatch[33]={onReceive : NetProtoUsermgr.recive.getServerInfor, send : NetProtoUsermgr.send.getServerInfor}
    NetProtoUsermgr.dispatch[35]={onReceive : NetProtoUsermgr.recive.setEnterServer, send : NetProtoUsermgr.send.setEnterServer}
    NetProtoUsermgr.dispatch[38]={onReceive : NetProtoUsermgr.recive.loginAccount, send : NetProtoUsermgr.send.loginAccount}
    NetProtoUsermgr.dispatch[39]={onReceive : NetProtoUsermgr.recive.loginAccountChannel, send : NetProtoUsermgr.send.loginAccountChannel}
    //==============================
    NetProtoUsermgr.cmds = {
        registAccount : "registAccount", // 注册,
        getServers : "getServers", // 取得服务器列表,
        isSessionAlived : "isSessionAlived", // session是否有效,
        getServerInfor : "getServerInfor", // 取得服务器信息,
        setEnterServer : "setEnterServer", // 保存所选服务器,
        loginAccount : "loginAccount", // 登陆,
        loginAccountChannel : "loginAccountChannel", // 渠道登陆
    }
    //==============================