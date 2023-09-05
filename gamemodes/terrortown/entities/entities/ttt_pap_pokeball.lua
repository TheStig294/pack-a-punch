AddCSLuaFile()
ENT.Base = "base_anim"
ENT.PrintName = "Pokeball"
ENT.AutomaticFrameAdvance = true
ENT.ThrowStrength = 1000
ENT.ThrowDist = 100

function ENT:Initialize()
   if SERVER then
      self:SetModel("models/ttt_pack_a_punch/pokeball/pokeball.mdl")
      self:PhysicsInit(SOLID_VPHYSICS)
      self:SetUseType(SIMPLE_USE)
      self:PhysWake()
      local owner = self.Thrower

      if IsValid(owner) then
         self:SetPos(owner:EyePos() + owner:GetAimVector() * self.ThrowDist)
         self:SetAngles(owner:EyeAngles())
         local physObj = self:GetPhysicsObject()
         physObj:SetVelocity(self:GetForward() * self.ThrowStrength)
      end
   end
end

function ENT:Think()
   if SERVER then
      self:NextThink(CurTime())

      return true
   end
end
-- -- This hook is only available on the server
-- if SERVER then
--    function ENT:Use(activator)
--       if IsValid(activator) and activator:IsPlayer() then
--          local SWEP = activator:Give("weapon_mhl_badge")
--          timer.Simple(0.1, function()
--             local UPGRADE = TTTPAP.upgrades.weapon_mhl_badge.pokeball
--             UPGRADE.noDesc = true
--             TTTPAP:ApplyUpgrade(SWEP, UPGRADE)
--             self:Remove()
--          end)
--       end
--    end
-- end
-- -- Play the open animation
-- self:ResetSequence("open") 
-- -- Stop the open animation
-- self:ResetSequence("idle") 