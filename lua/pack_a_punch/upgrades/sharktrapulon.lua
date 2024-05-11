local UPGRADE = {}
UPGRADE.id = "sharktrapulon"
UPGRADE.class = "weapon_sharkulonsummoner"
UPGRADE.name = "Sharktrapulon"
UPGRADE.desc = "Drops shark traps instead!"

UPGRADE.convars = {
    {
        name = "pap_sharktrapulon_trap_spawn_delay",
        type = "int"
    },
    {
        name = "pap_sharktrapulon_trap_despawn_delay",
        type = "int"
    }
}

local trapSpawnDelayCvar = CreateConVar("pap_sharktrapulon_trap_spawn_delay", 3, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Secs between spawning shark traps", 1, 60)

local trapDespawnDelayCvar = CreateConVar("pap_sharktrapulon_trap_despawn_delay", 20, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Secs between despawning shark traps", 1, 60)

-- If the shark trap isn't installed then this upgrade doesn't work
function UPGRADE:Condition()
    return scripted_ents.Get("ttt_shark_trap") ~= nil
end

function UPGRADE:Apply(SWEP)
    if CLIENT then return end

    self:AddToHook(SWEP, "PrimaryAttack", function()
        -- Grab the sharkulon NPC off of the SWEP, after it spawns it
        local sharkulon = SWEP.shark
        local owner = SWEP:GetOwner()
        if not IsValid(sharkulon) or not IsValid(owner) then return end
        -- Set the PAP camo on the sharkulon body, its turret, and disable the turret
        sharkulon.npc.move:SetMaterial(TTTPAP.camo)
        sharkulon.npc:SetMaterial(TTTPAP.camo)
        sharkulon.npc:SetSaveValue("spawnflags", 256)
        -- Quadruple the health because the sharkulon is coded to stay in front of the player when its turret is disabled
        local newHealth = sharkulon.npc.move:Health() * 4
        sharkulon.npc.move:SetHealth(newHealth)
        sharkulon.npc.move:SetMaxHealth(newHealth)
        -- Spawn shark traps underneath it while it is alive
        local timername = "PAPSharktrapulon" .. sharkulon:EntIndex()

        timer.Create(timername, trapSpawnDelayCvar:GetInt(), 0, function()
            if not IsValid(sharkulon) then
                timer.Remove(timername)

                return
            end

            -- Drop *upgraded* shark traps because why not?
            local pos = sharkulon:GetPos()
            pos.z = pos.z - 20
            local sharkTrap = ents.Create("ttt_pap_left_shark_trap")
            -- The upgraded shark trap needs an Owner property set to determine the attacker
            sharkTrap.Owner = owner
            sharkTrap:SetMaterial(TTTPAP.camo)
            sharkTrap:SetPos(pos)
            sharkTrap:Spawn()
            sharkTrap:PhysWake()

            -- Remove the spawned shark traps after a delay
            timer.Simple(trapDespawnDelayCvar:GetInt(), function()
                if IsValid(sharkTrap) then
                    sharkTrap:Remove()
                end
            end)
        end)
    end)
end

TTTPAP:Register(UPGRADE)