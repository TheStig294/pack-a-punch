local UPGRADE = {}
UPGRADE.id = "malfunctions_pistol"
UPGRADE.class = "weapon_ttt_malfunctionpistol"
UPGRADE.name = "Malfunctions Pistol"
UPGRADE.desc = "Victim continually shoots at random throughout the round"

function UPGRADE:Apply(SWEP)
    local function CreateMalfunctionsTimer(attacker, victimTable)
        -- This function returns the same random value for server and client, and is supposed to be used in shared functions and hooks
        -- Bullet callbacks are shared functions, so I'm using this
        timer.Simple(util.SharedRandom("TTTPAPMalfunctionsPistol", 10, 30, os.time()), function()
            if not IsValid(attacker) then return end
            local victim = victimTable.Entity
            if not IsValid(victim) or not victim.TTTPAPMalfunctionsPistol or not IsValid(victim:GetActiveWeapon()) then return end
            -- Conveniently global function from the Malfunction Pistol
            ForceTargetToShoot(attacker, victimTable)
            -- Recursion away!
            CreateMalfunctionsTimer(attacker, victimTable)
        end)
    end

    self:AddHook("PostEntityFireBullets", function(attacker, data)
        if not attacker:IsPlayer() then return end
        local inflictor = attacker:GetActiveWeapon()
        if not self:IsUpgraded(inflictor) then return end
        local victim = data.Trace.Entity
        if not IsPlayer(victim) then return end
        victim.TTTPAPMalfunctionsPistol = true
        -- Malfunction Pistol function is used in as a bullet callback, hence the .Entity nonsense we have to do here to get it to work
        -- (It's using the trace result from the bullet callback, but the .Entity value is all that it uses so we just give it that here)
        local victimTable = {}
        victimTable.Entity = victim
        CreateMalfunctionsTimer(attacker, victimTable)
    end)

    self:AddHook("PostPlayerDeath", function(ply)
        ply.TTTPAPMalfunctionsPistol = false
    end)
end

function UPGRADE:Reset()
    for _, ply in player.Iterator() do
        ply.TTTPAPMalfunctionsPistol = nil
    end
end

TTTPAP:Register(UPGRADE)