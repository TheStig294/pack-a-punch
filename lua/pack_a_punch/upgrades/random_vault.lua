local UPGRADE = {}
UPGRADE.id = "random_vault"
UPGRADE.class = "weapon_ttt_zombievault"
UPGRADE.name = "Random Vault"
UPGRADE.desc = "Auto-spawns random NPCs!"

UPGRADE.convars = {
    {
        name = "pap_random_vault_spawn_delay",
        type = "int"
    }
}

local spawnDelayCvar = CreateConVar("pap_random_vault_spawn_delay", 5, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Secs between changing npcs", 1, 60)

function UPGRADE:Apply(SWEP)
    local throwsound = Sound("Weapon_SLAM.SatchelThrow")
    SWEP.PickedOption = "fast_zom_default"

    function SWEP:SpawnerDrop()
        if SERVER then
            local npcList = self.TypeInfo

            local npcOptions = {"fast_zom_default", "antlion_default", "manhack_default", "npc_monk", "npc_crow", "npc_combine_s", "npc_cscanner", "npc_rollermine", "npc_alyx", "npc_antlionguard", "npc_headcrab_fast", "npc_gman", "npc_kleiner"}

            table.Shuffle(npcOptions)
            local currentIndex = 1
            local ply = self:GetOwner()
            if not IsValid(ply) then return end
            local vsrc = ply:GetShootPos()
            local vang = ply:GetAimVector()
            local vvel = ply:GetVelocity()
            local vthrow = vvel + vang * 125
            local vault = ents.Create("ttt_zombie_vault")

            if IsValid(vault) then
                vault:SetPos(vsrc + vang * 10)
                vault.SpawnInfo = self.TypeInfo[self.PickedOption]
                vault:Spawn()
                vault:SetPlayer(ply)
                vault:PhysWake()
                vault:SetColor(COLOR_WHITE)

                timer.Simple(1, function()
                    if IsValid(ply) and IsValid(vault) then
                        vault:Use(ply)
                    end
                end)

                local timername = "TTTPAPRandomVaultSpawn" .. ply:SteamID64()

                timer.Create(timername, spawnDelayCvar:GetInt(), 0, function()
                    if IsValid(vault) then
                        -- Don't spawn extra npcs if the vault is turned off (good luck with that btw)
                        if not vault.AlreadySpawning then return end
                        local npcClass = npcOptions[currentIndex]

                        if npcClass == "fast_zom_default" or npcClass == "antlion_default" or npcClass == "manhack_default" then
                            vault.SpawnInfo = npcList[npcClass]
                        else
                            local pos = vault:GetPos()
                            pos.z = pos.z + 10
                            local npc = ents.Create(npcClass)
                            npc:SetPos(pos)
                            npc:Spawn()
                            npc:Activate()
                            npc:PhysWake()
                        end

                        currentIndex = currentIndex + 1

                        if currentIndex > #npcOptions then
                            currentIndex = 1
                        end
                    else
                        timer.Remove(timername)
                    end
                end)

                local phys = vault:GetPhysicsObject()

                if IsValid(phys) then
                    phys:SetVelocity(vthrow)
                end

                self:Remove()
                self.Planted = true
            end
        end

        self:EmitSound(throwsound)
    end
end

TTTPAP:Register(UPGRADE)