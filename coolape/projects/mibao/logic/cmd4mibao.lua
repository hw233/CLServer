local skynet = require("skynet")
require("Errcode")
---@type CLUtl
local CLUtl = require("CLUtl")
---@type fileEx
local fileEx = require("fileEx")
cmd4mibao = {}

---@type dbuser
local myself = nil;

local basepath = skynet.getenv("projectPath") .. "logic/datas/"

cmd4mibao.CMD = {
    syndata = function(m, fd)
        local uid = m.__session__;
        local file = basepath .. "psdSave_" .. uid .. ".d";
        local bytes = fileEx.readAll(file)
        local new = m.psdInfors;
        local old = {}
        if bytes then
            old = BioUtl.readObject(bytes)
        end
        if new == nil or #new == 0 then
            local ret = {}
            ret.code = Errcode.ok
            return NetProtoMibao.send.syndata(ret, old)
        end

        local map = {}
        for i, v in ipairs(old) do
            map[v.platform] = v
        end

        local cell;
        local cellOld;
        for i = #new, 1 do
            cell = new[i]
            cellOld = map[cell.platform]
            if cellOld then
                if cellOld.time < cell.time then
                    map[cell.platform] = cell;
                end
                table.remove(new, i);
            end
        end

        local result = {}
        for i, v in ipairs(old) do
            table.insert(result, map[v.platform])
        end
        if new then
            for i, v in ipairs(new) do
                table.insert(result, v)
            end
        end

        fileEx.writeAll(file, BioUtl.writeObject(result))
        local ret = {}
        ret.code = Errcode.ok
        return NetProtoMibao.send.syndata(ret, result)
    end,
}

return cmd4mibao
