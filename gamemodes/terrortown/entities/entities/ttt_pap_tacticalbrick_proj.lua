AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ttt_tacticalbrick_proj"
ENT.DamageMin = 10000
ENT.DamageMax = 10000
ENT.RemoveOnNextCollide = false
ENT.ThrowsCvar = GetConVar("pap_giant_brick_throws")
ENT.Explode = nil

function ENT:Initialize()
    self.BaseClass.Initialize(self)
    self:SetPAPCamo()
    self:SetModelScale(20, 0.0001)
    self:Activate()
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