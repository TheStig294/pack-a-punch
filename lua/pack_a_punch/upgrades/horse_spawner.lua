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
    end)

    -- Force players to get on the horse as soon as it spawns
    self:AddHook("StartCommand", function(ply, cmd)
        if IsValid(ply:GetNWEntity("mount")) then
            cmd:AddKey(IN_DUCK)

            -- Disable T-Posing while on a horse
            if SERVER and ply:GetNWBool("T-Posing") then
                ply:SetNWBool("T-Posing", false)
                ply:PrintMessage(HUD_PRINTCENTER, "You can't T-Pose on a horse")
            end
        end

        if not ply.TTTPAPHorseSpawnerAutoUseKey then return end
        ply.TTTPAPHorseSpawnerAutoUseKey = nil
        cmd:AddKey(IN_USE)
    end)
end

function UPGRADE:Reset()
    for _, ply in player.Iterator() do
        ply.TTTPAPHorseSpawnerUsed = nil
        ply.TTTPAPHorseSpawnerAutoUseKey = nil
    end
end

TTTPAP:Register(UPGRADE)