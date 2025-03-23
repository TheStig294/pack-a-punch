local UPGRADE = {}
UPGRADE.id = "zombie_spammer"
UPGRADE.class = "weapon_ttt_zombie_pumpkin"
UPGRADE.name = "Zombie Spammer"
UPGRADE.desc = "Spawns a bunch of extra zombies around the map!"

UPGRADE.convars = {
    {
        name = "pap_zombie_spammer_spawn_count",
        type = "int"
    }
}

local spawnNumCvar = CreateConVar("pap_zombie_spammer_spawn_count", "15", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Number of extra zombies to spawn", 1, 30)

function UPGRADE:Apply(SWEP)
    local owner = SWEP:GetOwner()
    if not IsValid(owner) then return end
    owner.TTTPAPZombieSpammer = true

    self:AddHook("TTTZombiePumpkinExplode", function(pumpkin)
        local thrower = pumpkin:GetThrower()
        if not IsValid(thrower) or not thrower.TTTPAPZombieSpammer then return end
        thrower.TTTPAPZombieSpammer = false
        -- Spawning zombies around the map
        local entsTable = ents.GetAll()
        table.Shuffle(entsTable)
        local spawnCount = 0
        local maxSpawnNum = spawnNumCvar:GetInt()

        for _, ent in ipairs(entsTable) do
            if ent.Kind and ent.AutoSpawnable and not IsValid(ent:GetParent()) then
                -- Spawning the zombie
                local npc = pumpkin:SpawnNPC(ent:GetPos(), "npc_fastzombie")
                npc:SetPAPCamo()
                ent:Remove()
                spawnCount = spawnCount + 1
            end

            if spawnCount >= maxSpawnNum then break end
        end
    end)

    self:AddHook("TTTZombiePumpkinThrow", function(pumpkin)
        local thrower = pumpkin:GetThrower()
        if not IsValid(thrower) or not thrower.TTTPAPZombieSpammer then return end
        pumpkin:SetPAPCamo()
    end)

    self:AddHook("TTTZombiePumpkinSpawnZombie", function(pumpkin, zombie)
        local thrower = pumpkin:GetThrower()
        if not IsValid(thrower) or not thrower.TTTPAPZombieSpammer then return end
        zombie:SetPAPCamo()
    end)

    self:AddHook("TTTZombiePumpkinDrawWorldmodel", function(wep, model)
        if IsValid(wep) and self:IsUpgraded(wep) then
            model:SetPAPCamo()
        end
    end)
end

function UPGRADE:Reset()
    for _, ply in player.Iterator() do
        ply.TTTPAPZombieSpammer = false
    end
end

TTTPAP:Register(UPGRADE)