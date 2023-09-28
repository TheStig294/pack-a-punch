local UPGRADE = {}
UPGRADE.id = "spacetime_hacker"
UPGRADE.class = "manipulator"
UPGRADE.name = "Spacetime Hacker"
UPGRADE.desc = "No cooldown, but be careful not to use it too much..."

UPGRADE.convars = {
    {
        name = "pap_spacetime_hacker_overuse_count",
        type = "int"
    },
    {
        name = "pap_spacetime_hacker_overuse_min",
        type = "int"
    },
    {
        name = "pap_spacetime_hacker_overuse_max",
        type = "int"
    },
}

local overuseCountCvar = CreateConVar("pap_spacetime_hacker_overuse_count", 15, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "No. of uses until 'overuse' triggers", 1, 50)

local minGravityCvar = CreateConVar("pap_spacetime_hacker_overuse_min", -600, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Min random overuse gravity", -1000, 600)

local maxGravityCvar = CreateConVar("pap_spacetime_hacker_overuse_max", 2000, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Max random overuse gravity", -600, 1000)

function UPGRADE:Apply(SWEP)
    SWEP.PAPUseCount = 0
    SWEP.PAPReloadCooldown = false

    function SWEP:PrimaryAttack()
        if CLIENT or not IsFirstTimePredicted() then return end
        PrintMessage(HUD_PRINTTALK, "Gravity is REDUCED!")
        RunConsoleCommand("sv_gravity", "70")
        self:HandleOveruse()
        self:HandleSound()
    end

    function SWEP:SecondaryAttack()
        if CLIENT or not IsFirstTimePredicted() then return end
        PrintMessage(HUD_PRINTTALK, "Gravity is INCREASED!")
        RunConsoleCommand("sv_gravity", "2000")
        self:HandleOveruse()
        self:HandleSound()
    end

    function SWEP:Reload()
        if CLIENT or not IsFirstTimePredicted() or self.PAPReloadCooldown then return end
        self.PAPReloadCooldown = true
        PrintMessage(HUD_PRINTTALK, "Gravity is NORMAL!")
        RunConsoleCommand("sv_gravity", "600")
        self:HandleOveruse()
        self:HandleSound()

        timer.Simple(0.5, function()
            if IsValid(self) then
                self.PAPReloadCooldown = false
            end
        end)
    end

    function SWEP:HandleSound()
        if not self.PAPSoundCooldown and not self.PAPOverused then
            self:GetOwner():EmitSound("warning/gravityChange.wav", 0)
            self.PAPSoundCooldown = true

            timer.Simple(2, function()
                if IsValid(self) then
                    self.PAPSoundCooldown = false
                end
            end)
        end
    end

    function SWEP:HandleOveruse()
        self.PAPUseCount = self.PAPUseCount + 1

        if self.PAPUseCount > overuseCountCvar:GetInt() then
            self.PAPOverused = true
            PrintMessage(HUD_PRINTTALK, "Gravity is BROKEN!\nSomeone overused an upgraded gravity changer!")
            -- Play broken sound and explode the weapon
            self:GetOwner():EmitSound("ttt_pack_a_punch/spacetime_hacker/broken.mp3", 0)
            local explode = ents.Create("env_explosion")
            explode:SetPos(self:GetPos())
            explode:SetOwner(self:GetOwner())
            explode:SetKeyValue("iMagnitude", 50)
            explode:SetKeyValue("iRadiusOverride", 50)
            explode:Spawn()
            explode:Fire("Explode", 0, 0)
            self:EmitSound("ambient/explosions/explode_3.wav")

            -- Kill the player that used the weapon
            if IsValid(self:GetOwner()) then
                local dmg = DamageInfo()
                dmg:SetDamage(10000)
                dmg:SetDamageType(DMG_BLAST)
                dmg:SetAttacker(self:GetOwner())
                dmg:SetInflictor(self)
                self:GetOwner():TakeDamageInfo(dmg)
            end

            -- Randomly change gravity every 20 seconds, by default, with the possibility of negative gravity!
            -- We only want one of these timers running at a time, so don't make the timer name unique
            timer.Create("TTTPAPSpaceTimeHackerOveruse", 20, 0, function()
                RunConsoleCommand("sv_gravity", math.random(minGravityCvar:GetInt(), maxGravityCvar:GetInt()))
            end)

            self:Remove()
        end
    end
end

function UPGRADE:Reset()
    timer.Remove("TTTPAPSpaceTimeHackerOveruse")
    RunConsoleCommand("sv_gravity", "600")
end

TTTPAP:Register(UPGRADE)