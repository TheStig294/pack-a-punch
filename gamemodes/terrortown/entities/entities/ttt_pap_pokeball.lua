AddCSLuaFile()
ENT.Base = "base_anim"
ENT.PrintName = "Pokeball"
ENT.AutomaticFrameAdvance = true
ENT.ThrowStrength = 1000
ENT.ThrowDist = 100
ENT.MinCatchChance = 50

function ENT:Initialize()
   if SERVER then
      self:SetModel("models/ttt_pack_a_punch/pokeball/pokeball.mdl")
      self:PhysicsInit(SOLID_VPHYSICS)
      self:SetUseType(SIMPLE_USE)
      self:PhysWake()
      self:SetTrigger(true)
      local owner = self.Thrower

      if IsValid(owner) then
         self:SetPos(owner:EyePos() + owner:GetAimVector() * self.ThrowDist)
         self:SetAngles(owner:EyeAngles())
         local physObj = self:GetPhysicsObject()
         if not IsValid(physObj) then return end
         physObj:SetVelocity(self:GetForward() * self.ThrowStrength)
      end
   end
end

if SERVER then
   function ENT:Use(activator)
      if IsValid(activator) and activator:IsPlayer() then
         local SWEP = activator:Give("weapon_mhl_badge")

         timer.Simple(0.1, function()
            local UPGRADE = TTTPAP.upgrades.weapon_mhl_badge.pokeball
            UPGRADE.noDesc = true
            TTTPAP:ApplyUpgrade(SWEP, UPGRADE)
            self:Remove()
         end)
      end
   end

   function ENT:Think()
      self:NextThink(CurTime())

      return true
   end

   function ENT:StartTouch(ply)
      if IsValid(self.CaughtPly) then return end
      if not IsValid(ply) or not ply:IsPlayer() then return end
      local owner = self.Thrower
      if not IsValid(owner) or ply == owner then return end
      -- Try to catch the player!
      self:ResetSequence("open")
      self:EmitSound("ttt_pack_a_punch/pokeball/catch.mp3")
      local physObj = self:GetPhysicsObject()
      if not IsValid(physObj) then return end
      physObj:EnableMotion(false)
      ply:Freeze(true)
      ply:SetMaterial("lights/white")
      ply:SetColor(COLOR_WHITE)
      ply:SetModelScale(0.1, 1)

      timer.Simple(1, function()
         if not IsValid(physObj) then return end
         physObj:EnableMotion(true)
         self:PhysWake()
         self.CaughtPly = ply
         ply:SetMaterial("")
         ply:SetModelScale(1, 1)
      end)

      timer.Simple(2, function()
         if not IsValid(self) then return end
         self:EmitSound("ttt_pack_a_punch/pokeball/shake.mp3")
      end)

      -- Either release the player and destroy the pokeball,
      -- Or catch the player!
      -- (Chance depending on the player's remaining health)
      timer.Simple(7.375, function()
         if not IsValid(self) then return end
         local captureChancePercent = ply:GetMaxHealth() - math.min(ply:Health(), ply:GetMaxHealth()) + self.MinCatchChance

         -- Capture failed!
         if math.random() > captureChancePercent / 100 then
            self:EmitSound("ttt_pack_a_punch/pokeball/release.mp3")
         else
            -- Capture success!
            self:EmitSound("ttt_pack_a_punch/pokeball/capture.mp3")
         end
      end)
   end
end