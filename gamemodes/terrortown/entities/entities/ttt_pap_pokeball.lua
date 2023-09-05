AddCSLuaFile()
ENT.Base = "base_anim"
ENT.Spawnable = true
ENT.AutomaticFrameAdvance = true
ENT.PrintName = "Animation Test"
ENT.Category = "My Entity Category"

-- ENT.Model = "models/ttt_pack_a_punch/pokeball/pokeball.mdl"
function ENT:Initialize()
   -- Only set this stuff on the server, it is networked to clients automatically
   if SERVER then
      self:SetModel("models/ttt_pack_a_punch/pokeball/pokeball.mdl") -- Set the model
      self:PhysicsInit(SOLID_VPHYSICS) -- Initialize physics
      self:SetUseType(SIMPLE_USE) -- Make sure ENT:Use is ran only once per use ( per press of the use button on the entity, by default the E key )
   end
end

function ENT:Think()
   -- Only set this stuff on the server
   if SERVER then
      self:NextThink(CurTime()) -- Set the next think for the serverside hook to be the next frame/tick
      -- Return true to let the game know we want to apply the self:NextThink() call

      return true
   end
end

-- This hook is only available on the server
if SERVER then
   -- If a player uses this entity, play an animation
   function ENT:Use(activator, caller)
      -- If we are not "opened"
      if not self.Opened then
         self:ResetSequence("open") -- Play the open sequence
         self.Opened = true -- We are now opened
      else
         self:ResetSequence("idle") -- Play the close sequence
         self.Opened = false -- We are now closed
      end
   end
end