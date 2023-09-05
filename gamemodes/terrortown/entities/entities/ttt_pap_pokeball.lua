AddCSLuaFile()
ENT.Base = "base_anim"
ENT.PrintName = "Pokeball"
ENT.AutomaticFrameAdvance = true
ENT.ThrowStrength = 1000
ENT.ThrowDist = 25
ENT.MinCatchChance = 50
ENT.AllowSelfCapture = true
ENT.AllowGlobalPickup = false
ENT.BounceSoundCount = 0
ENT.PickedUpWithPlayer = false

function ENT:Initialize()
   if SERVER then
      self:SetModel("models/ttt_pack_a_punch/pokeball/pokeball.mdl")
      self:SetSolid(SOLID_VPHYSICS)
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

      -- If the SWEP set a caught player, then the pokeball will release them when next thrown
      if IsValid(self.CaughtPly) then
         self.PickedUpWithPlayer = true
      end
   end
end

if SERVER then
   -- Allows the player to pick up the pokeball again to throw the captured player out
   function ENT:Use(activator)
      if not IsValid(activator) or not activator:IsPlayer() then return end
      -- Only allow the pokeball to be picked up if there is a player inside and they are the thrower, unless the thrower caught themselves...
      if not self.AllowGlobalPickup and (not IsValid(self.CaughtPly) or IsValid(self.Thrower) and activator ~= self.Thrower and self.CaughtPly ~= self.Thrower) then return end
      self:GiveSWEP(activator)
   end

   -- Gives the pokeball SWEP to the player
   function ENT:GiveSWEP(ply)
      local SWEP = ply:Give("weapon_mhl_badge")
      -- Move the caught player to spectating the pokeball
      SWEP.CaughtPly = self.CaughtPly

      if IsValid(self.CaughtPly) then
         self.CaughtPly:SpectateEntity(ply)
      end

      self:Remove()

      timer.Simple(0.1, function()
         if not IsValid(SWEP) then return end
         -- Turn the weapon into the pokeball again
         local UPGRADE = TTTPAP.upgrades.weapon_mhl_badge.pokeball
         UPGRADE.noDesc = true
         TTTPAP:ApplyUpgrade(SWEP, UPGRADE)
      end)
   end

   -- Allows the 'self:ResetSequence("open")' call to play the pokeball open animation to work in ENT:StartTouch()
   function ENT:Think()
      self:NextThink(CurTime())

      return true
   end

   -- Catches the player if the pokeball collides with one!
   function ENT:StartTouch(ply)
      -- Don't try to catch a player if one is already caught
      if IsValid(self.CaughtPly) then return end
      if not IsValid(ply) or not ply:IsPlayer() then return end
      local owner = self.Thrower
      -- Prevent the player from catching themselves
      if not self.AllowSelfCapture and (not IsValid(owner) or ply == owner) then return end
      -- Use the in-built function in the Marshal's badge to check if a player is able to be promoted
      local validTarget, validTargetMessage = self:ValidateTarget(ply)

      if not validTarget then
         owner:PrintMessage(HUD_PRINTCENTER, validTargetMessage)
         self:GiveSWEP(owner)

         return
      end

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
            self:ReleasePlayer(true)
         else
            self:CaptureSuccess()
         end
      end)
   end

   -- Applies all of the effects of successfully capturing a player
   function ENT:CaptureSuccess()
      -- Plays a sound and gives off some sparks
      self:EmitSound("ttt_pack_a_punch/pokeball/capture.mp3")
      self:SetMaterial("lights/white")
      local sparks = EffectData()
      sparks:SetMagnitude(5)
      sparks:SetScale(5)
      sparks:SetRadius(5)
      sparks:SetOrigin(self:GetPos())
      util.Effect("Sparks", sparks)

      timer.Simple(0.5, function()
         if not IsValid(self) then return end
         self:SetMaterial("")
      end)
   end

   -- Called whenever the pokeball hits anything, not just players
   function ENT:PhysicsCollide()
      -- Release the caught player!
      if self.PickedUpWithPlayer and IsValid(self.CaughtPly) then
         self:ReleasePlayer(false)
      elseif self.BounceSoundCount < 3 then
         -- Else just play a sound
         self:EmitSound("ttt_pack_a_punch/pokeball/capture.mp3")
         self.BounceSoundCount = self.BounceSoundCount + 1
      end
   end

   -- Releases the player again if they escaped capture, else changes their role!
   function ENT:ReleasePlayer(escapedCapture)
      self:EmitSound("ttt_pack_a_punch/pokeball/release.mp3")
      local caughtPly = self.CaughtPly
      caughtPly:UnSpectate()
      caughtPly:Spawn()
      caughtPly:SetPos(self:GetPos())
      caughtPly:DrawViewModel(true)
      caughtPly:DrawWorldModel(true)
      caughtPly:SetModelScale(1, 1)
      caughtPly:SetMaterial("lights/white")
      caughtPly:Freeze(false)

      -- If the player was released by someone via throwing the pokeball again, change their role!
      if not escapedCapture and IsValid(caughtPly) and IsValid(self.Thrower) then
         self:SetOwner(self.Thrower)
         self:OnSuccess(caughtPly)
      end

      self:Remove()

      timer.Simple(1, function()
         if not IsValid(caughtPly) then return end
         caughtPly:SetMaterial("")
      end)
   end
end