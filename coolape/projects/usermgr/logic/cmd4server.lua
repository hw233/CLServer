local skynet = require("skynet")
require("dbuser")
require("dbuserserver")
require("dbservers")
require("Errcode")
---@type CLUtl
local CLUtl = require("CLUtl")
local DBUtl = require "DBUtl"
require("CLGlobal")
---@type dateEx
local dateEx = require("dateEx")

local NetProto = skynet.getenv("NetProtoName")
local table = table

local cmd4server = {}

cmd4server.CMD = {
    setEnterServer = function(m, fd)
        -- 保存选服
        local uidx = m.uidx
        local sidx = m.sidx
        local appid = m.appid

        if uidx == nil or sidx == nil or appid == nil then
            local ret = {}
            ret.msg = "参数错误！";
            ret.code = Errcode.error
            return skynet.call(NetProto, "lua", "send", "setEnterServer", m, ret)
        end

        ---@type dbuserserver
        local us = dbuserserver.instanse(uidx, appid)
        if us:isEmpty() then
            local data = {}
            data.sidx = sidx
            data.uidx = uidx
            data.appid = appid
            us:init(data, true)
        else
            us:set_sidx(sidx)
        end
        us:release()
        local ret = {}
        ret.msg = nil;
        ret.code = Errcode.ok
        return skynet.call(NetProto, "lua", "send", "setEnterServer", m, ret)
    end,

    getServerInfor = function(m, fd)
        -- 取得服务器信息
        if m.idx == nil then
            local ret = {}
            ret.msg = "参数错误！";
            ret.code = Errcode.error
            return skynet.call(NetProto, "lua", "send", "getServerInfor", m, ret, nil)
        end
        local s = dbservers.instanse(m.idx)
        if s:isEmpty() then
            -- 未找到
            local ret = {}
            ret.msg = "未找到数据";
            ret.code = Errcode.error
            return skynet.call(NetProto, "lua", "send", "getServerInfor", m, ret, nil)
        end
        local ret = {}
        ret.msg = nil
        ret.code = Errcode.ok
        local result = s:value2copy()
        s:release()
        return skynet.call(NetProto, "lua", "send", "getServerInfor", m, ret, result)
    end,

    getServers = function(m, fg)
        -- 取得服务器列表
        local appid = m.appid
        local channel = m.channel
        if appid == nil or channel == nil then
            local ret = {}
            ret.msg = "参数错误！";
            ret.code = Errcode.error
            return skynet.call(NetProto, "lua", "send", "getServers", m, ret, nil)
        end

        local list = dbservers.getListByappid(appid, " idx desc ")

        local ret = {}
        ret.msg = nil
        ret.code = Errcode.ok
        return skynet.call(NetProto, "lua", "send", "getServers", m, ret, list)
    end
}

skynet.start(function()
    skynet.dispatch("lua", function(_, _, command, ...)
        local f = cmd4server.CMD[command]
        skynet.ret(skynet.pack(f(...)))
    end)
end)
