local skynet = require("skynet")
require("public.include")
require("Errcode")
require("dbunit")
local ClassBullet = require "battle.ClassBullet"

---@class ClassUnit:ClassBase 战斗单元
local ClassUnit = class("ClassUnit")

---@param battle ClassFleetBattle
function ClassUnit:init(battle, idx, id, lev, isOffense, gindex, pos)
    self.battle = battle
    self.idx = idx
    self.id = id
    self.lev = lev or 1
    self.isOffense = isOffense
    self.gridIndex = gindex
    self.position = pos
    ---@type DBCFRoleData
    self.attr = cfgUtl.getCfgDataById(id, "DBCFRoleData")
    self.speed = self.attr.MoveSpeed / 100

    self.MaxAttackRange = self.attr.AttackRange / 100
    self.MinAttackRange = self.attr.MinAttackRange / 100

    self.data = {}
    -- 最大血量
    self.data.HP =
        cfgUtl.getGrowingVal(self.attr.HPMin, self.attr.HPMax, self.attr.HPCurve, self.lev / self.attr.MaxLev)
    -- 当前血量
    self.data.curHP = self.data.HP
    -- 伤害值
    self.data.damage =
        cfgUtl.getGrowingVal(
        self.attr.DamageMin,
        self.attr.DamageMax,
        self.attr.DamageCurve,
        self.lev / self.attr.MaxLev
    )
    ---@type ClassUnit
    self.target = nil
    self.isDead = false
    --------------------------------------------------
    -- 移动相关
    self.isMoving = false
    self.from = Vector3.zero
    ---@type Vector3
    self.dis = Vector3.zero
    self.magnitude = 1
    self.curveTime = 0
    --------------------------------------------------
end

function ClassUnit:FixedUpdate()
    if self.isMoving then
        self.curveTime = self.curveTime + self.battle.FixedDeltaTime * self.speed * 10 * self.magnitude
        self.curveTime = self.curveTime > 1 and 1 or self.curveTime
        self.position = self.from + self.dis * self.curveTime
        if self.curveTime >= 1 then
            self:onArrived()
        else
            if self.target then
                local dis = Vector3.Distance(self.position, self.target.position)
                if dis <= self.MaxAttackRange then
                    self:onArrived()
                end
            end
        end
    end
end

function ClassUnit:moveTo(toPos)
    self.from = self.position
    self.dis = toPos - self.from
    local magnitude = self.dis:Magnitude()
    self.magnitude = magnitude <= 0.00001 and 1 or 1 / magnitude
    self.curveTime = 0
    self.isMoving = true
end

function ClassUnit:onArrived()
    self.isMoving = false
end

function ClassUnit:startAttack()
    if self.isDead then
        return
    end
    self:attack()

    if self.attackTimer then
        self.attackTimer.cancel()
    end
    self.attackTimer = nil
    self.attackTimer = timerEx.new(self.attr.AttackSpeedMS / 1000, self.startAttack, self)
end

function ClassUnit:attack()
    if self.isDead or self.battle.isEndBattle or self.isMoving then
        return
    end
    if self.target == nil or self.target.isDead then
        self.target = self.battle:searchTarget(self)
    end

    if self.target then
        local dis = Vector3.Distance(self.position, self.target.position)
        if dis > self.MaxAttackRange then
            ---@type Vector3
            local diff = self.target.position - self.position
            local toPos = self.position + diff:Normalize() * (self.MaxAttackRange + 0.5)

            self.battle:onUnitMoveTo(self)
            self:moveTo(toPos)
        else
            self.battle:onUnitAttack(self)
            self:fire(self.target)
        end
    end
end

---@param target ClassUnit
function ClassUnit:fire(target)
    if target == nil or target.isDead then
        return
    end
    if self.id == 8 then
        -- 毁灭者自爆炸弹
        self:bomb()
    else
        if self.attr.Bullets then
            ---@type ClassBullet
            local bullet = self.battle:borrowBullet()
            bullet:fire(self.attr.Bullets, self, target, self.battle.onBulletHit, self.battle)
        else
            -- 直接扣血
            self.target:onHurt(self:getDamage(self.target), self)
        end
    end
end

---public 自爆
function ClassUnit:bomb()
    -- 取得目标
    local targets = self.battle:getTargetsInRange(self, self.position, self.attr.DamageAffectRang / 100)
    ---@param target ClassUnit
    for i, target in ipairs(targets) do
        target:onHurt(self:getDamage(target), self)
    end

    self:onDead()
end

---@param target ClassUnit
function ClassUnit:getDamage(target)
    if target == nil then
        return 0
    end
    local damage = self.data.damage
    local gid = target.attr.GID
    if self.attr.PreferedTargetType == gid then
        -- 优先攻击目标的伤害加成
        damage = damage * self.attr.PreferedTargetDamageMod
    end
    return math.floor(damage)
end

---public 处理伤害
---@param attacker ClassUnit
function ClassUnit:onHurt(damage, attacker)
    self.battle:onUnitHurt(self, damage)
    self.data.curHP = self.data.curHP - damage
    self.data.curHP = self.data.curHP < 0 and 0 or self.data.curHP
    self.data.curHP = self.data.curHP > self.data.HP and self.data.HP or self.data.curHP
    if self.data.curHP <= 0 then
        self:onDead()
    end
end

function ClassUnit:onDead()
    if self.isDead or self.battle.isEndBattle then
        return
    end
    -- if self.attackTimer then
    --     timerEx.cancel(self.attackTimer)
    -- end
    -- self.attackTimer = nil

    self.isDead = true
    self.battle:onUnitDead(self)
end

function ClassUnit:clean()
    self.isMoving = false
    if self.attackTimer then
        timerEx.cancel(self.attackTimer)
    end
    self.attackTimer = nil
end

return ClassUnit
