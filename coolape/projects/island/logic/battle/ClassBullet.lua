local skynet = require("skynet")
require("public.include")
require("Errcode")
require("dbunit")

---@class ClassBullet:ClassBase 战斗单元
local ClassBullet = class("ClassBullet")

---@param attacker ClassUnit
---@param target ClassUnit
function ClassBullet:fire(id, attacker, target, callback, param)
    self.id = id
    ---@type ClassFleetBattle
    self.battle = attacker.battle
    ---@type DBCFBulletData
    self.attr = cfgUtl.getCfgDataById(id, "DBCFBulletData")
    self.finishCallback = callback
    self.callbackParam = param
    ---@type ClassUnit
    self.attacker = attacker
    ---@type ClassUnit
    self.target = target
    ---@type Vector3
    self.position = target.position

    local dis = Vector3.Distance(attacker.position, target.position)
    local speed = self.attr.Speed / 10
    local sec = dis / speed
    sec = sec * 0.2 -- 再除10是为了调整时间
    if self.timer then
        self.timer.cancel()
    end
    self.timer = timerEx.new(sec, self.onHit, self)
end

function ClassBullet:onHit()
    self.timer = nil
    if self.finishCallback then
        self.finishCallback(self.callbackParam, self)
    end
    self.battle:returnBullet(self)
end

function ClassBullet:clean()
    if self.timer then
        self.timer.cancel()
    end
    self.timer = nil
end

return ClassBullet
