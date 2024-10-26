AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ttt_basegrenade_proj"
ENT.Model = Model("models/jenssons/props/redmatter.mdl")

function ENT:Initialize()
   self.BaseClass.Initialize(self)
   self.Sound = CreateSound(self, "ttt_pack_a_punch/white_matter_bomb/siren.mp3")
   self.Sound:SetSoundLevel(85)
   self.Sound:Play()
   self:SetPAPCamo()
end

function ENT:OnRemove()
   self.Sound:Stop()
end

function ENT:Explode(tr)
   if SERVER then
      self:SetNoDraw(true)
      self:SetSolid(SOLID_NONE)

      -- pull out of the surface
      if tr.Fraction ~= 1.0 then
         self:SetPos(tr.HitPos + tr.HitNormal * 0.6)
      end

      local pos = self:GetPos()
      local bh = ents.Create("ttt_pap_whiteblackhole")
      bh:SetPos(pos)
      bh:SetSpawner(self:GetThrower())
      bh:Spawn()
      self:SetDetonateExact(0)
      self:Remove()
   else
      self:SetDetonateExact(0)
   end
end