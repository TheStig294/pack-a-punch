AddCSLuaFile()
ENT.Base = "doncmk2_en"
ENT.Type = "anim"
ENT.PrintName = "Big Donconnon"

function ENT:Initialize()
  self.BaseClass.Initialize(self)
  self:SetMaterial(TTT_PAP_CAMO) -- PAP camo, no fire sound

  if SERVER then
    self.Trail = util.SpriteTrail(self, 0, Color(255, 0, 0), false, 500, 0, 3, 1 / 100 * 0.5, "sprites/combineball_trail_red_1") -- New red trail
    self:EmitSound(self.Sound, 0) -- Sound is heard everywhere and is louder
    self:EmitSound(self.Sound, 0)
  end
end

if SERVER then
  function ENT:OnRemove()
    self:EmitSound("ambient/explosions/explode_1.wav")
    self:EmitSound("ambient/explosions/explode_2.wav")
    self:EmitSound("ambient/explosions/explode_3.wav")
    local explode = ents.Create("env_explosion")
    explode:SetPos(self:GetPos())
    explode:SetOwner(self:GetOwner())
    explode:SetKeyValue("iMagnitude", 550)
    explode:SetKeyValue("iRadiusOverride", 550) -- 100 extra explosion range
    explode:Spawn()
    explode:Fire("Explode", 0, 0)
    local tr = util.QuickTrace(self:GetPos(), Vector(0, 0, -1)) -- Leaves fire
    StartFires(self:GetPos(), tr, 20, 40, false, self:GetOwner())
  end
end