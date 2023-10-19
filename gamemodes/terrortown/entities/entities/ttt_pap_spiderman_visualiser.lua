AddCSLuaFile()
ENT.Base = "ttt_cse_proj"
ENT.Type = "anim"
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.SpidermanMaterial = Material("ttt_pack_a_punch/spiderman_visualiser/spiderman.png")

function ENT:Initialize()
    self:SetSolid(SOLID_VPHYSICS)

    if SERVER then
        self:SetMaxHealth(50)
        self:SetExplodeTime(CurTime() + 1)
    end

    self:SetHealth(50)
end

function ENT:Draw()
    cam.Start3D2D(self:GetPos(), self:GetAngles() + Angle(0, 90, 90), 0.1)
    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(self.SpidermanMaterial)
    surface.DrawTexturedRect(-256, -512, 512, 512)
    cam.End3D2D()
    cam.Start3D2D(self:GetPos(), self:GetAngles() + Angle(0, -90, 90), 0.1)
    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(self.SpidermanMaterial)
    surface.DrawTexturedRect(-256, -512, 512, 512)
    cam.End3D2D()
end