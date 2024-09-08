local UPGRADE = {}
UPGRADE.id = "spacetime_manipulator"
UPGRADE.class = "weapons_ttt_time_manipulator"
UPGRADE.name = "Spacetime Manipulator"
UPGRADE.desc = "Unlimited ammo and no cooldown!\nBut be careful not to use it too much... (Reset on drop or reload)"

UPGRADE.convars = {
    {
        name = "pap_spacetime_manipulator_overuse_count",
        type = "int"
    },
    {
        name = "pap_spacetime_manipulator_overuse_min",
        type = "float"
    },
    {
        name = "pap_spacetime_manipulator_overuse_max",
        type = "float"
    },
}

local overuseCountCvar = CreateConVar("pap_spacetime_manipulator_overuse_count", 15, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "No. of uses until 'overuse' triggers", 1, 50)

local minTimeCvar = CreateConVar("pap_spacetime_manipulator_overuse_min", 0.2, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Min random overuse time scale", 0.001, 1)

local maxTimeCvar = CreateConVar("pap_spacetime_manipulator_overuse_max", 2.2, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Max random overuse time scale", 1, 5)

function UPGRADE:Apply(SWEP)
    SWEP.PAPUseCount = 0

    timer.Simple(0, function()
        SWEP.ClipSize = -1
        SWEP:SetClip1(-1)
    end)

    function SWEP:PrimaryAttack()
        if CLIENT then return end

        if IsFirstTimePredicted() then
            self:GetOwner():ChatPrint("Slowed down time!")
        end

        game.SetTimeScale(GetConVar("tm_slowdown"):GetFloat())
        self:HandleOveruse()
    end

    function SWEP:SecondaryAttack()
        if CLIENT then return end

        if IsFirstTimePredicted() then
            self:GetOwner():ChatPrint("Sped up time!")
        end

        game.SetTimeScale(GetConVar("tm_speedup"):GetFloat())
        self:HandleOveruse()
    end

    function SWEP:Reload()
        if SERVER then
            local owner = self:GetOwner()

            if not self.PAPReloadMessageCooldown and IsValid(owner) then
                self.PAPReloadMessageCooldown = true
                owner:ChatPrint("Reset time!")

                timer.Create("TTTPAPSpaceTimeManipulatorReload" .. self:EntIndex(), 0.5, 1, function()
                    if IsValid(self) then
                        self.PAPReloadMessageCooldown = false
                    end
                end)
            end

            game.SetTimeScale(1)
        end
    end

    function SWEP:OnRemove()
        self:Reload()
    end

    function SWEP:PreDrop()
        self:Reload()
    end

    if SERVER then
        function SWEP:HandleOveruse()
            self.PAPUseCount = self.PAPUseCount + 1

            if self.PAPUseCount > overuseCountCvar:GetInt() then
                self.PAPOverused = true
                PrintMessage(HUD_PRINTTALK, "Time is BROKEN!\nSomeone overused an upgraded time manipulator!")
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

                -- Randomly change time scale every 20 seconds (realtime)
                -- We only want one of these timers running at a time, so don't make the timer name unique
                local function ChangeBrokenTimeScale()
                    local scale = math.Rand(minTimeCvar:GetFloat(), maxTimeCvar:GetFloat())
                    scale = math.Round(scale, 1)

                    if scale < game.GetTimeScale() then
                        PrintMessage(HUD_PRINTTALK, "Slowed down time! x" .. scale)
                    else
                        PrintMessage(HUD_PRINTTALK, "Sped up time! x" .. scale)
                    end

                    game.SetTimeScale(scale)
                    -- Recursion away!
                    timer.Create("TTTPAPTimeWarperOveruse", scale * 20, 1, ChangeBrokenTimeScale)
                end

                -- The first time change will always be x1, since the weapon is removed by overuse, which resets the timescale to 1
                timer.Create("TTTPAPTimeWarperOveruse", 20, 1, ChangeBrokenTimeScale)
                self:Remove()
            end
        end
    end
end

function UPGRADE:Reset()
    if SERVER then
        timer.Remove("TTTPAPTimeWarperOveruse")
        game.SetTimeScale(1)
    end
end

TTTPAP:Register(UPGRADE)