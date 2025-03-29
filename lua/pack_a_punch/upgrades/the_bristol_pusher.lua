local UPGRADE = {}
UPGRADE.id = "the_bristol_pusher"
UPGRADE.class = "pusher_swep"
UPGRADE.name = "The Bristol Pusher"
UPGRADE.desc = "Truly embody the pusher himself...\nDeals extra damage!"

UPGRADE.convars = {
    {
        name = "pap_brewis_ginley_extra_damage",
        type = "int"
    }
}

local damageCvar = CreateConVar("pap_brewis_ginley_extra_damage", "75", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Extra damage dealt", 1, 200)

local lewisModel = "models/bradyjharty/yogscast/lewis.mdl"
local lewisModelInstalled = util.IsValidModel(lewisModel)

function UPGRADE:Apply(SWEP)
    local function PlayLewisSound(ply)
        if not ply.TTTPAPTheBristolPusherCooldown then
            ply:EmitSound("pusher/pusher_" .. math.random(1, 10) .. ".mp3")
            ply.TTTPAPTheBristolPusherCooldown = true

            timer.Simple(3, function()
                ply.TTTPAPTheBristolPusherCooldown = nil
            end)
        end
    end

    local function SetLewisMode(ply, setMode)
        if SERVER and IsValid(ply) then
            if setMode then
                -- Change the player's model
                if lewisModelInstalled then
                    ply.TTTPAPTheBristolPusherModel = ply.TTTPAPTheBristolPusherModel or ply:GetModel()
                    self:SetModel(ply, lewisModel)
                    ply:SetupHands()
                end

                -- And play Lewis quotes...
                PlayLewisSound(ply)
                local timerName = "TTTPAPTheBristolPusherSounds" .. ply:SteamID64()

                timer.Create(timerName, 10, 0, function()
                    if not IsValid(ply) then
                        timer.Remove(timerName)

                        return
                    end

                    PlayLewisSound(ply)
                end)
            else
                if lewisModelInstalled and ply.TTTPAPTheBristolPusherModel then
                    self:SetModel(ply, ply.TTTPAPTheBristolPusherModel)
                    ply:SetupHands()
                    ply.TTTPAPTheBristolPusherModel = nil
                end

                timer.Remove("TTTPAPTheBristolPusherSounds" .. ply:SteamID64())
            end
        end
    end

    -- Keep track of the owner, since the owner from self:GetOwner() is NULL when SWEP:OnRemove() is called on the server
    SWEP.PAPOwner = SWEP:GetOwner()
    SetLewisMode(SWEP.PAPOwner, true)

    self:AddToHook(SWEP, "Deploy", function()
        SetLewisMode(SWEP.PAPOwner, true)
    end)

    function SWEP:Holster()
        SetLewisMode(self.PAPOwner, false)

        return true
    end

    function SWEP:PreDrop()
        SetLewisMode(self.PAPOwner, false)
    end

    function SWEP:OnRemove()
        SetLewisMode(self.PAPOwner, false)
    end

    -- Extra damage
    local DMG_PUSHER = 2853

    self:AddHook("EntityTakeDamage", function(victim, dmg)
        if not IsPlayer(victim) then return end
        local attacker = dmg:GetAttacker()
        if not IsPlayer(attacker) then return end
        local inflictor = attacker:GetActiveWeapon()
        if not IsValid(inflictor) or not self:IsUpgraded(inflictor) or dmg:GetDamageCustom() == DMG_PUSHER then return end

        timer.Simple(0.1, function()
            if not IsValid(victim) or not IsValid(victim.PushRagdoll) then return end

            victim.TTTPAPBrewisGinleyDamage = {
                attacker = attacker,
                inflictor = inflictor
            }

            -- Player makes a sound on pushing someone as well
            PlayLewisSound(attacker)
        end)
    end)

    -- The pusher weapon resets the player's health if they take damage while being pushed, so we have to wait until the player gets back up to deal damage
    self:AddHook("PlayerSpawn", function(ply)
        timer.Simple(0, function()
            if ply.TTTPAPBrewisGinleyDamage then
                local inflictor = ply.TTTPAPBrewisGinleyDamage.inflictor
                local attacker = ply.TTTPAPBrewisGinleyDamage.attacker
                local extraDmg = DamageInfo()
                extraDmg:SetDamage(damageCvar:GetInt())
                extraDmg:SetDamageType(DMG_CLUB)
                -- Use the weapon, else the weapon owner, else the victim
                extraDmg:SetInflictor(IsValid(inflictor) and inflictor or IsValid(attacker) and attacker or victim)
                -- Use the weapon owner, else the victim
                extraDmg:SetAttacker(IsValid(attacker) and attacker or victim)
                extraDmg:SetDamageCustom(DMG_PUSHER)
                ply:TakeDamageInfo(extraDmg)
                ply.TTTPAPBrewisGinleyDamage = nil
            end
        end)
    end)
end

function UPGRADE:Reset()
    for _, ply in player.Iterator() do
        ply.TTTPAPBrewisGinleyDamage = nil
    end
end

TTTPAP:Register(UPGRADE)