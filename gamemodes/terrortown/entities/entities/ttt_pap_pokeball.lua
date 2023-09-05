AddCSLuaFile()
ENT.Base = "base_anim"
ENT.AutomaticFrameAdvance = true
ENT.PrintName = "Pokeball"

function ENT:Initialize()
   if SERVER then
      self:SetModel("models/ttt_pack_a_punch/pokeball/pokeball.mdl")
      self:PhysicsInit(SOLID_VPHYSICS)
      self:SetUseType(SIMPLE_USE)
   end
end

function ENT:Think()
   if SERVER then
      self:NextThink(CurTime())

      return true
   end
end
-- -- Play the open animation
-- self:ResetSequence("open") 
-- -- Stop the open animation
-- self:ResetSequence("idle") 