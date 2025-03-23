local UPGRADE = {}
UPGRADE.id = "player_mimic_spawner"
UPGRADE.class = "weapon_ttt_minic"
UPGRADE.name = "Player Mimic Spawner"
UPGRADE.desc = "Spawns hostile player-mimics!\nThey shoot anyone on sight!"

UPGRADE.convars = {
    {
        name = "pap_player_mimic_spawner_mimics_per_player",
        type = "float",
        decimals = 1
    }
}

local multCvar = CreateConVar("pap_player_mimic_spawner_mimics_per_player", "1", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "No. of mimics spawned per player", 0.1, 3)

function UPGRADE:Apply(SWEP)
    function SWEP:SpawnMimics()
        local players = player.GetAll()
        local playerCount = #players
        local playerIndex = 1
        -- Try to spawn as many mimics as there are players, times the multipler, rounded up
        local mimicCap = math.ceil(playerCount * multCvar:GetFloat())
        local mimicCount = 0

        for _, ent in RandomPairs(ents.FindByClass("info_player_*")) do
            -- Try to find player spawn points
            local pos = ent:GetPos()
            -- Spawning the mimic NPC in its place
            local ply = players[playerIndex]
            local mimic = ents.Create("npc_combine")
            mimic:SetPos(pos)
            mimic:SetModel(ply:GetModel())
            mimic:Spawn()
            mimic:Activate()
            mimic:SetHealth(100)
            mimic:SetMaxHealth(100)
            -- Find the player's current weapon, and give it to the mimic
            local wep = ply:GetActiveWeapon()
            local wepClass = "weapon_ttt_m16"

            -- Only give mimics standard floor weapons, else just give them an M16
            if IsValid(wep) and wep.Kind and (wep.Kind == WEAPON_PISTOL or wep.Kind == WEAPON_HEAVY) then
                wepClass = WEPS.GetClass(wep)
            end

            -- Give the weapon and ammo
            local mimicWep = mimic:Give(wepClass)
            mimic:SelectWeapon(wepClass)
            mimicWep:SetClip1(10000)
            -- Check if enough mimics are spawned
            mimicCount = mimicCount + 1
            if mimicCount >= mimicCap then break end
            -- Otherwise move to the next player to mimic
            playerIndex = playerIndex + 1

            if playerIndex > playerCount then
                playerIndex = 1
            end
        end

        return mimicCount
    end

    function SWEP:PrimaryAttack()
        if CLIENT then return end
        local mimicCount = self:SpawnMimics()
        local owner = self:GetOwner()
        self:Remove()

        if IsValid(owner) then
            -- Try to only warn players on the same team as the owner that mimics have been spawned
            -- (What the base weapon tries to do)
            if owner.IsSameTeam then
                for _, ply in player.Iterator() do
                    if ply:IsSameTeam(owner) then
                        ply:ChatPrint(mimicCount .. " player-mimics spawned!")
                    end
                end
            else
                for _, ply in player.Iterator() do
                    if ply:GetRole() == ROLE_TRAITOR or (ply.IsTraitorTeam and ply:IsTraitorTeam()) or ply == owner then
                        ply:ChatPrint(mimicCount .. " player-mimics spawned!")
                    end
                end
            end

            owner:ConCommand("lastinv")
        end

        -- If we failed to find any player spawn points, give them the regular mimic spawner, and a credit back
        timer.Simple(0.1, function()
            if mimicCount == 0 then
                owner:AddCredits(1)
                owner:Give("weapon_ttt_minic")
                owner:ChatPrint("No valid player spawns, your mimic spawner and credit has been refunded!")
            end
        end)
    end
end

TTTPAP:Register(UPGRADE)