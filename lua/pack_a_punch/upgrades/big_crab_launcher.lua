local UPGRADE = {}
UPGRADE.id = "big_crab_launcher"
UPGRADE.class = "weapon_ttt_headlauncher"
UPGRADE.name = "Big Crab Launcher"
UPGRADE.desc = "Spawns 1 big crab launcher!\nLauncher deals direct damage, spawns many poison headcrabs"
UPGRADE.ammoMult = 1 / 3

UPGRADE.convars = {
    {
        name = "pap_big_crab_launcher_health",
        type = "int"
    },
    {
        name = "pap_big_crab_launcher_crab_count",
        type = "int"
    },
    {
        name = "pap_big_crab_launcher_damage",
        type = "int"
    },
    {
        name = "pap_big_crab_launcher_damage_radius",
        type = "int"
    }
}

local healthCvar = CreateConVar("pap_big_crab_launcher_health", 100, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Health upgraded headcrabs have", 1, 500)

local crabCountCvar = CreateConVar("pap_big_crab_launcher_crab_count", 18, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Number of headcrabs spawned", 1, 30)

local damageCvar = CreateConVar("pap_big_crab_launcher_damage", 30, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Damage direct launcher hit deals", 0, 100)

local damageRadiusCvar = CreateConVar("pap_big_crab_launcher_damage_radius", 150, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "AOE range of direct launcher damage", 0, 500)

local oldHealthValue

function UPGRADE:Apply(SWEP)
    -- Poison headcrab health is controlled by a hl2 convar
    oldHealthValue = GetConVar("sk_headcrab_poison_health"):GetInt()
    RunConsoleCommand("sk_headcrab_poison_health", healthCvar:GetInt())
    local ShootSoundFail = Sound("WallHealth.Deny")
    local YawIncrement = 20
    local PitchIncrement = 10

    function SWEP:PrimaryAttack()
        local owner = self:GetOwner()
        self:SetNextPrimaryFire(CurTime() + 1)
        local tr = owner:GetEyeTrace()
        local aBaseAngle = tr.HitNormal:Angle()
        local aBasePos = tr.HitPos
        local bScanning = true
        local iPitch = 10
        local iYaw = -180
        local iLoopLimit = 0
        local iProcessedTotal = 0
        local tValidHits = {}

        while bScanning and iLoopLimit < 500 do
            iYaw = iYaw + YawIncrement
            iProcessedTotal = iProcessedTotal + 1

            if iYaw >= 180 then
                iYaw = -180
                iPitch = iPitch - PitchIncrement
            end

            local tLoop = util.QuickTrace(aBasePos, (aBaseAngle + Angle(iPitch, iYaw, 0)):Forward() * 40000)

            if tLoop.HitSky then
                table.insert(tValidHits, tLoop)
            end

            if iPitch <= -80 then
                bScanning = false
            end

            iLoopLimit = iLoopLimit + 1
        end

        local iHits = table.Count(tValidHits)

        if iHits > 0 then
            self:SetNWBool("Used", true)
            self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)

            if SERVER then
                owner:SetAnimation(PLAYER_ATTACK1)
                local iRand = math.random(3, iHits)
                local tRand = tValidHits[iRand]
                local rocket = ents.Create("env_headcrabcanister")
                rocket:SetPos(aBasePos)
                rocket:SetAngles((tRand.HitPos - tRand.StartPos):Angle())
                rocket:SetKeyValue("HeadcrabType", 2)
                rocket:SetKeyValue("HeadcrabCount", crabCountCvar:GetInt())
                rocket:SetKeyValue("FlightSpeed", 2000)
                rocket:SetKeyValue("FlightTime", 2.5)
                rocket:SetKeyValue("Damage", damageCvar:GetInt())
                rocket:SetKeyValue("DamageRadius", damageRadiusCvar:GetInt())
                rocket:SetKeyValue("SmokeLifetime", 3)
                rocket:SetKeyValue("StartingHeight", 1000)
                rocket:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
                rocket:SetKeyValue("spawnflags", 8192)
                rocket:Spawn()
                rocket:SetModelScale(2, 0.0001)
                rocket:Activate()
                rocket:SetMaterial(TTTPAP.camo)
                rocket:Input("FireCanister", owner, owner)
                self:TakePrimaryAmmo(1)

                if SERVER and self:Clip1() <= 0 then
                    self:Remove()

                    timer.Simple(0.1, function()
                        owner:ConCommand("lastinv")
                    end)
                end
            end
        else
            self:EmitSound(ShootSoundFail)
        end
    end

    -- Continually find and upgrade the spawned crabs
    timer.Create("TTTPAPBigCrabLauncherFindCrabs", 0.5, 120, function()
        for _, crab in ipairs(ents.FindByClass("npc_headcrab_poison")) do
            local own = crab:GetOwner()

            if IsValid(own) and own:GetClass() == "env_headcrabcanister" then
                crab:SetMaterial(TTTPAP.camo)
                crab:SetModelScale(2, 0.0001)
                crab.TTTPAPBigCrabLauncher = true
            end
        end
    end)

    self:AddHook("EntityTakeDamage", function(ent, dmg)
        local inflictor = dmg:GetInflictor()

        if IsValid(inflictor) and inflictor.TTTPAPBigCrabLauncher then
            dmg:SetDamageType(DMG_SLASH)
        end
    end)

    -- If a yogs playermodel is installed, play the "crabs are people" sounds!
    local yogsModels = {"models/bradyjharty/yogscast/lankychu.mdl", "models/bradyjharty/yogscast/breeh.mdl", "models/bradyjharty/yogscast/breeh2.mdl", "models/bradyjharty/yogscast/lewis.mdl", "models/bradyjharty/yogscast/sharky.mdl"}

    local yogsModelInstalled = false

    for _, model in ipairs(yogsModels) do
        if util.IsValidModel(model) then
            yogsModelInstalled = true
            break
        end
    end

    if yogsModelInstalled then
        -- Replace scream sound with "crabs are people" sound lol
        self:AddHook("EntityEmitSound", function(data)
            local crab = data.Entity

            if IsValid(crab) and crab.TTTPAPBigCrabLauncher then
                -- Poison headcrabs have 3 separate scream sounds that trigger when attacking a player, so these first 2 sounds only play when a crab attacks
                if string.StartsWith(data.SoundName, "npc/headcrab_poison/ph_scream") then
                    local randomNum = math.random(2)

                    if math.random() < 0.3 then
                        for i = 1, 3 do
                            crab:EmitSound("ttt_pack_a_punch/big_crab_launcher/crab" .. randomNum .. ".mp3")
                        end
                    end

                    return false
                elseif string.StartsWith(data.SoundName, "npc/headcrab_poison/ph_pain") then
                    -- Disable the headcrab hurt sound, and make more crabs are people sounds instead lol
                    if math.random() < 0.3 then
                        local randomNum = math.random(3, 11)

                        for i = 1, 3 do
                            crab:EmitSound("ttt_pack_a_punch/big_crab_launcher/crab" .. randomNum .. ".mp3")
                        end
                    end

                    return false
                end
            end
        end)
    end
end

function UPGRADE:Reset()
    timer.Remove("TTTPAPBigCrabLauncherFindCrabs")
    RunConsoleCommand("sk_headcrab_poison_health", oldHealthValue or 35)
end

TTTPAP:Register(UPGRADE)