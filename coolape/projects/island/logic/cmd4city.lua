require("dbcity")
require("DBUtl")

cmd4city = {}

---@type dbcity
local myself

cmd4city.CMD = {
    new = function (uidx)
        local idx = DBUtl.nextVal("city")
        myself = dbcity.instanse(idx)
        local d = {}

        d.idx = idx
        d.name= "new city"
        d.pidx = uidx
        d.pos = 0
        d.status = 1
        d.lev = 1
        myself:init(d)
        return myself
    end,
    get = function (idx)
        if myself == nil then
            myself = dbcity.instanse(idx)
        end
        if myself:isEmpty() then
            return nil
        end
        return myself
    end,
}

return cmd4city
