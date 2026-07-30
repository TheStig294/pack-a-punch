AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ttt_tacticalbrick_proj"

local damageCvar = CreateConVar("pap_giant_brick_damage", "200", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Damage of the brick", 0, 200)

function ENT:Initialize()
    self.BaseClass.Initialize(self)
    self:SetPAPCamo()
    self:SetModelScale(20, 0.0001)
    self:Activate()
    self.ThrowsCvar = GetConVar("pap_giant_brick_throws")
    self.DamageMin = damageCvar:GetFloat()
    self.DamageMax = self.DamageMin
    if CLIENT then return end
    local thrower = self:GetThrower()

    if IsValid(thrower) then
        thrower.PAPGiantBrickThrows = thrower.PAPGiantBrickThrows or 0
        thrower.PAPGiantBrickThrows = thrower.PAPGiantBrickThrows + 1

        if thrower.PAPGiantBrickThrows >= self.ThrowsCvar:GetInt() then
            self.RemoveOnNextCollide = self.ThrowsCvar:GetInt() ~= 0
        end
    end
end

function ENT:PhysicsCollide(data, phys)
    if self.RemoveOnNextCollide then
        local pos = self:GetPos()
        self:EmitSound("ambient/explosions/explode_3.wav")
        local explode = ents.Create("env_explosion")
        explode:SetPos(pos)
        explode:SetOwner(self:GetThrower())
        explode:SetKeyValue("iMagnitude", 100)
        explode:SetKeyValue("iRadiusOverride", 100)
        explode:Spawn()
        explode:Fire("Explode")
        self:Remove()
    else
        return self.BaseClass.PhysicsCollide(self, data, phys)
    end
end