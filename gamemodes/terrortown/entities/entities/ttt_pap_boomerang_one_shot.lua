AddCSLuaFile()
ENT.Base = "ent_boomerangclose_randomat"
ENT.Type = "anim"
ENT.PrintName = "1-Shot Boomerang"

function ENT:Initialize()
    self.BaseClass.Initialize(self)
    self:SetPAPCamo()
end