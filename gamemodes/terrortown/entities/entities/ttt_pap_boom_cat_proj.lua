AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ttt_boom_cat_proj"

function ENT:Initialize()
   self:SetPAPCamo()

   return self.BaseClass.Initialize(self)
end

function ENT:Explode(tr)
   if SERVER then
      local owner = self:GetOwner()
      local boomCat = ents.Create("ttt_boom_cat")
      boomCat:SetPos(tr.HitPos)
      local angles = owner:GetAngles()
      angles.z = 0
      boomCat:SetAngles(angles)
      boomCat.Thrower = owner
      boomCat.DoRemove = false
      boomCat:Spawn()
      self:Remove()
   end
end