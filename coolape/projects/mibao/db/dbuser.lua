require("class")
local skynet = require "skynet"

-- 用户表
dbuser = class("dbuser")

dbuser.name = "user"

function dbuser:ctor(v)
    self.__name__ = "user"    -- 表名
    self.__isNew__ = true    -- 新建数据，说明mysql表里没有数据
    self.uid = ""    -- 用户id
    self.password = ""    -- 用户密码
    self.crtTime = ""    -- 创建时间
    self.lastEnTime = ""    -- 最后登陆时间
    self.statu = 0    -- 状态
end

function dbuser:init(data)
    self.uid = data.uid    -- 用户id
    self.password = data.password    -- 用户密码
    self.crtTime = data.crtTime    -- 创建时间
    self.lastEnTime = data.lastEnTime    -- 最后登陆时间
    self.statu = data.statu    -- 状态
end

function dbuser:insertSql()
    local sql = "INSERT INTO `user` (`uid`,`password`,`crtTime`,`lastEnTime`,`statu`)"
    .. " VALUES ("
    .. "'" .. (self.uid and self.uid or "") .. "'" .. ","
    .. "'" .. (self.password and self.password or "") .. "'" .. ","
    .. "'" .. (self.crtTime and self.crtTime or "") .. "'" .. ","
    .. "'" .. (self.lastEnTime and self.lastEnTime or "") .. "'" .. ","
    .. (self.statu and self.statu or 0)
    .. ");"
    return sql
end

function dbuser:updateSql()
    local sql = "UPDATE user SET "..
    "`uid`='" .. (self.uid and self.uid or "") .. "'" .. ","
    .. "`password`='" .. (self.password and self.password or "") .. "'" .. ","
    .. "`crtTime`='" .. (self.crtTime and self.crtTime or "") .. "'" .. ","
    .. "`lastEnTime`='" .. (self.lastEnTime and self.lastEnTime or "") .. "'" .. ","
    .. "`statu`=" .. (self.statu and self.statu or 0)
    .. "WHERE " .. "`uid`='" .. (self.uid and self.uid or "") .. "'" .. " AND " .. "`password`='" .. (self.password and self.password or "") .. "'" .. ";"
    return sql
end

function dbuser:delSql()
    local sql = "DELETE FROM user WHERE ".. "`uid`='" .. (self.uid and self.uid or "") .. "'" .. " AND " .. "`password`='" .. (self.password and self.password or "") .. "'" .. ";"
    return sql
end

function dbuser:toSql()
    if self.__isNew__ then
        return self:insertSql()
    else
        return self:updateSql()
    end
end

function dbuser:toMap()
    local m = {}
    m.name = dbuser.name;
    m.data = {}
    m.design = user;

end

function dbuser.querySql(uid, password)
    return "SELECT * FROM user WHERE " .. "`uid`='" .. (uid and uid or "") .. "'" .. " AND " .. "`password`='" .. (password and password or "") .. "'" .. ";"
end

function dbuser.instanse(uid, password)
    local key = uid .. "_" .. password
    if key == "" then
        error("the key is null", 0)
    end
    ---@type dbuser
    local obj = skynet.call("CLDB", "lua", "get", dbuser.name, key)
    if obj == nil then
        local d = skynet.call("CLMySQL", "lua", "exesql", dbuser.querySql(uid,password))
        obj = dbuser.new()
        if d and #d > 0 then
            if #d == 1 then
                d = d[1]
            else
                error("get data is more than one! count==" .. #d .. "lua==dbuser")
            end
            -- 取得mysql表里的数据
            obj:init(d)
            obj.__isNew__ = false
            skynet.call("CLDB", "lua", "set", dbuser.name, key, obj)
        else
            -- 没有数据
            obj.__isNew__ = true
        end
    else
        obj.__isNew__ = false
        skynet.call("CLDB", "lua", "removetimeout", dbuser.name, key)
    end
    return obj
end

------------------------------------
return dbuser
