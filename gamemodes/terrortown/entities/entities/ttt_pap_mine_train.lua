AddCSLuaFile()
ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.PrintName = "Train"

function ENT:Initialize()
    self:SetModel("models/props_trainstation/train001.mdl")
    self:SetMoveType(MOVETYPE_NOCLIP)
    self:SetSolid(SOLID_NONE)
    self.Dist = 0
end

function ENT:Think()
    local time = CurTime()
    self.time = self.time or time
    local deltaTime = time - self.time
    self.time = time
    self.runTime = self.runTime or deltaTime
    local position = self:GetPos()
    local ang = self:GetAngles()
    ang:RotateAroundAxis(ang:Up(), 2)
    local forward = ang:Right() * 1000 * deltaTime
    self.Dist = self.Dist + forward:Length()

    if self.Dist > 4000 and SERVER then
        self:Remove()

        return
    end

    self.startPos = self.startPos or position
    self:SetPos(position + forward)
end