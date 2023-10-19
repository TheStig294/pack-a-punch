local UPGRADE = {}
UPGRADE.id = "player_launcher"
UPGRADE.class = "corpselauncher"
UPGRADE.name = "Player Launcher"
UPGRADE.desc = "Works on living players instead!"

UPGRADE.convars = {
    {
        name = "pap_player_launcher_auto_release_secs",
        type = "int"
    }
}

local autoReleaseCvar = CreateConVar("pap_player_launcher_auto_release_secs", 20, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds until players auto-release", 0, 60)

function UPGRADE:Apply(SWEP)
    -- Range is in source units squared, so 10000 = 100 range
    SWEP.PickupRange = 10000
    SWEP.Primary.ClipSize = 2
    SWEP.Primary.ClipMax = 2
    SWEP.Primary.Ammo = "AirboatGun"
    SWEP.DrawAmmo = true

    timer.Simple(0.1, function()
        SWEP:SetClip1(2)
    end)

    SWEP.PAPOwner = SWEP:GetOwner()
    SWEP.AutoReleaseSecs = autoReleaseCvar:GetInt()

    -- Update the owner and set the captured player to spectate the player launcher if the owner dies or otherwise drops the player launcher
    function SWEP:OwnerChanged()
        self.PAPOwner = self:GetOwner()
        if not IsValid(self.CaughtPly) then return end

        if IsValid(self.PAPOwner) then
            self.CaughtPly:SpectateEntity(self.PAPOwner)
        else
            self.CaughtPly:SpectateEntity(self)
        end
    end

    -- Loads a player in the launcher
    function SWEP:SecondaryAttack()
        if CLIENT then return end

        -- Don't try to catch a player if one is already caught
        if IsValid(self.CaughtPly) then
            self.PAPOwner:PrintMessage(HUD_PRINTCENTER, "Already loaded with " .. self.CaughtPly:Nick())

            return
        end

        local ply = self.PAPOwner:GetEyeTrace().Entity
        -- Only allow valid living players
        if not UPGRADE:IsAlivePlayer(ply) then return end

        -- Enforce maximum pickup range
        if self.PickupRange < ply:GetPos():DistToSqr(self.PAPOwner:GetPos()) then
            self.PAPOwner:PrintMessage(HUD_PRINTCENTER, "Too far away!")

            return
        end

        -- Put the player in the launcher!
        self:EmitSound("Weapon_Crossbow.Reload")
        self.CaughtPly = ply
        ply:Freeze(true)
        ply:Spectate(OBS_MODE_CHASE)
        ply:SpectateEntity(self.PAPOwner)
        ply:DrawViewModel(false)
        ply:DrawWorldModel(false)
        self.PAPOwner:PrintMessage(HUD_PRINTTALK, "You have " .. self.AutoReleaseSecs .. " seconds to fire " .. self.CaughtPly:Nick() .. "!")
        -- Starts a auto-release countdown for the captured player
        local timername = "TTTPAPPlayerLauncherAutoRelease" .. self:EntIndex()

        timer.Create(timername, 1, self.AutoReleaseSecs, function()
            if not IsValid(self) or not IsValid(self.CaughtPly) then
                timer.Remove(timername)
            else
                self.AutoReleaseSecsLeft = timer.RepsLeft(timername)
                self.CaughtPly:PrintMessage(HUD_PRINTCENTER, "Seconds until auto release: " .. self.AutoReleaseSecsLeft)

                if self.AutoReleaseSecsLeft == 0 then
                    self:ReleasePlayer()
                end
            end
        end)
    end

    -- Launches the player!
    function SWEP:PrimaryAttack()
        if CLIENT or not IsFirstTimePredicted() then return end

        if not IsValid(self.CaughtPly) then
            self.PAPOwner:PrintMessage(HUD_PRINTCENTER, "Load a player with right-click first!")
            self:EmitSound("Weapon_SMG1.Empty")

            return
        end

        local rag = ents.Create("ent_corpse_launcher")
        rag.whoslaunched = self.CaughtPly
        rag.PAPPlayerLauncherRagdoll = true
        rag:SetOwner(self.PAPOwner)
        rag:Spawn()
        rag:Activate()
        self.CaughtPly:SpectateEntity(rag)
        self.PAPOwner:EmitSound("Weapon_AR2.Single")
        self.PAPOwner:ViewPunch(Angle(-10, -5, 0))
        self.CaughtPly = nil
        -- Weapon removes itself if ammo is out, shooting a player takes 1 ammo
        self:TakePrimaryAmmo(1)

        if self:Clip1() <= 0 then
            self:Remove()
        end
    end

    -- Respawns the player on the ragdoll once it lands
    self:AddHook("EntityRemoved", function(rag)
        if not IsValid(rag) or not rag.PAPPlayerLauncherRagdoll then return end

        if IsValid(rag.whoslaunched) then
            caughtPly = rag.whoslaunched
            caughtPly:UnSpectate()
            caughtPly:Spawn()
            caughtPly:SetPos(rag:GetPos())
            caughtPly:DrawViewModel(true)
            caughtPly:DrawWorldModel(true)
            caughtPly:Freeze(false)
        end
    end)

    -- Releases the player again if they escaped capture
    function SWEP:ReleasePlayer(skipRemove)
        self:EmitSound("Weapon_AR2.Single")
        if not IsValid(self.CaughtPly) then return end
        self.CaughtPly:UnSpectate()
        self.CaughtPly:Spawn()
        self.CaughtPly:SetPos(self:GetPos())
        self.CaughtPly:DrawViewModel(true)
        self.CaughtPly:DrawWorldModel(true)
        self.CaughtPly:Freeze(false)
        self.CaughtPly = nil
        self:TakePrimaryAmmo(1)

        -- If a player was released automatically and this was the last ammo shot, remove the weapon
        timer.Simple(0.1, function()
            if not skipRemove and IsValid(self) and self:Clip1() <= 0 then
                self.ReleasingPlayer = true
                self:Remove()
            end
        end)
    end

    -- If the player launcher is removed for whatever reason, and there is a player inside, release them
    function SWEP:OnRemove()
        if not self.ReleasingPlayer then return end
        self:ReleasePlayer(true)
    end
end

TTTPAP:Register(UPGRADE)