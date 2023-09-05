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
      -- Don't try to catch a player if one is already caught
      if IsValid(self.CaughtPly) then return end
      if not IsValid(ply) or not ply:IsPlayer() then return end
      local owner = self.Thrower
      -- -- Prevent the player from catching themselves lol
      -- if not IsValid(owner) or ply == owner then return end
      -- Try to catch the player!
      self:ResetSequence("open")
      self:EmitSound("ttt_pack_a_punch/pokeball/catch.mp3")
      local physObj = self:GetPhysicsObject()
      if not IsValid(physObj) then return end
      -- Play the capture animation
      physObj:EnableMotion(false)
      ply:Freeze(true)
      ply:SetMaterial("lights/white")
      ply:SetModelScale(0.1, 1)
      self.CaughtPly = ply

      -- Put the player in the pokeball!
      timer.Simple(1, function()
         if not IsValid(physObj) then return end
         physObj:EnableMotion(true)
         self:PhysWake()
         ply:Spectate(OBS_MODE_CHASE)
         ply:SpectateEntity(self)
         ply:DrawViewModel(false)
         ply:DrawWorldModel(false)
      end)

      -- Play the shake sound effect after the ball falls to the ground
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

         if math.random() > captureChancePercent / 100 then
            -- Capture failed!
            self:EmitSound("ttt_pack_a_punch/pokeball/release.mp3")
            ply:UnSpectate()
            ply:Spawn()
            ply:SetPos(self:GetPos())
            ply:DrawViewModel(true)
            ply:DrawWorldModel(true)
            ply:SetModelScale(1, 1)
            ply:SetMaterial("lights/white")
            ply:Freeze(false)

            timer.Simple(1, function()
               if not IsValid(ply) then return end
               ply:SetMaterial("")
            end)

            self:Remove()

            return
         else
            -- Capture success!
            self:EmitSound("ttt_pack_a_punch/pokeball/capture.mp3")
         end
      end)
   end
end