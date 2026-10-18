local UPGRADE = {}
UPGRADE.id = "horse_spawner"
UPGRADE.class = "ttt_weapon_lasso"
UPGRADE.name = "Horse Spawner"
UPGRADE.desc = "Right-click to spawn a rideable horse!\nDrop it to share it around!"

function UPGRADE:Condition()
    return scripted_ents.Get("npc_horse")
end

function UPGRADE:Apply(SWEP)
    self:AddToHook(SWEP, "SecondaryAttack", function()
        local owner = SWEP:GetOwner()
        if not IsValid(owner) then return end
        if owner.TTTPAPHorseSpawnerUsed then return end
        owner.TTTPAPHorseSpawnerUsed = true
        owner.TTTPAPHorseSpawnerAutoUseKey = true
        if CLIENT then return end
        local horse = ents.Create("npc_horse")
        horse:SetPos(owner:GetPos())
        horse:Spawn()
        owner:ChatPrint("Press 'E' while looking up to get off")
        -- Disable third person if a player gets off their horse
        horse.OldDismount = horse.Dismount

        function horse:Dismount()
            local ply = self:GetOwner()

            if IsValid(ply) then
                UPGRADE:SetThirdPerson(ply, false)
                ply.TTTPAPHorseSpawnerThirdPersonCooldown = false
                ply.TTTPAPHorseSpawnerThirdPerson = false
            end

            self:OldDismount()
        end
    end)

    self:AddHook("StartCommand", function(ply, cmd)
        if IsValid(ply:GetNWEntity("mount")) then
            -- Force players to crouch while on the horse to make them look like they're in a riding pose
            cmd:AddKey(IN_DUCK)

            -- Disable T-Posing while on a horse
            if ply:GetNWBool("T-Posing") then
                -- Instead, set them to third person without T-Posing
                if not ply.TTTPAPHorseSpawnerThirdPersonCooldown then
                    ply.TTTPAPHorseSpawnerThirdPersonCooldown = true
                    ply.TTTPAPHorseSpawnerThirdPerson = not ply.TTTPAPHorseSpawnerThirdPerson
                    self:SetThirdPerson(ply, ply.TTTPAPHorseSpawnerThirdPerson)

                    timer.Create("TTTPAPHorseSpawnerThirdPersonCooldown" .. ply:SteamID64(), 1, 1, function()
                        if not IsValid(ply) then return end
                        ply.TTTPAPHorseSpawnerThirdPersonCooldown = false
                    end)
                end

                -- The client doesn't get a chance to see the NWBool has changed before it's reset,
                -- so we need to set a tiny delay so the client still sees it,
                -- and the third-person view hook actually gets set on the client
                timer.Simple(0.1, function()
                    ply:SetNWBool("T-Posing", false)
                end)
            end
        end

        -- Force players to get on the horse as soon as it spawns
        if not ply.TTTPAPHorseSpawnerAutoUseKey then return end
        ply.TTTPAPHorseSpawnerAutoUseKey = nil
        cmd:AddKey(IN_USE)
    end)
end

function UPGRADE:Reset()
    for _, ply in player.Iterator() do
        ply.TTTPAPHorseSpawnerUsed = nil
        ply.TTTPAPHorseSpawnerAutoUseKey = nil
        ply.TTTPAPHorseSpawnerThirdPerson = nil
        ply.TTTPAPHorseSpawnerThirdPersonCooldown = nil
    end
end

TTTPAP:Register(UPGRADE)