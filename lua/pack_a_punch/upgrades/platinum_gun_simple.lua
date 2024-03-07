local UPGRADE = {}
UPGRADE.id = "platinum_gun_simple"
UPGRADE.class = "weapon_ttt_powerdeagle"
UPGRADE.name = "Platinum Gun"
UPGRADE.desc = "Shoot a bad guy: Get to shoot again\nDon't shoot a bad guy: One of them gets an extra life!"

function UPGRADE:Apply(SWEP)
    local function IsBaddie(ply)
        return (ply.IsTraitorTeam and ply:IsTraitorTeam()) or (ply:GetRole() == ROLE_TRAITOR) or (ply.IsIndependentTeam and ply:IsIndependentTeam()) or (ply.IsMonsterTeam and ply:IsMonsterTeam())
    end

    self:AddHook("DoPlayerDeath", function(ply, attacker, dmg)
        -- Extra life respawn
        if ply.PAPPlatinumGunExtraLife then
            ply.PAPPlatinumGunExtraLife = false
            local credits = ply:GetCredits()
            local items = ply:GetEquipmentItems()
            local weps = ply:GetWeapons()

            for i, wep in ipairs(weps) do
                weps[i] = wep:GetClass()
            end

            local ammo = ply:GetAmmo()

            timer.Simple(1, function()
                -- Don't respawn the player if they die as the round restarts
                if GetRoundState() == ROUND_PREP then return end
                ply:PrintMessage(HUD_PRINTCENTER, "Your extra life saved you!")
                ply:PrintMessage(HUD_PRINTTALK, "Your extra life saved you!")
                ply:SpawnForRound(true)
                -- Credits
                ply:SetCredits(credits)
                -- Equipment
                ply.equipment_items = items
                ply:SendEquipment()

                -- Weapons
                for _, wep in ipairs(weps) do
                    ply:Give(wep)
                end

                -- Ammo
                for ammoID, ammoCount in pairs(ammo) do
                    ply:GiveAmmo(ammoCount, ammoID, true)
                end
            end)
        end

        -- Shooting platinum gun
        if (not self:IsPlayer(ply)) or (not self:IsPlayer(attacker)) then return end
        local inflictor = dmg:GetInflictor()

        if self:IsPlayer(inflictor) then
            inflictor = inflictor:GetActiveWeapon()
        end

        if not IsValid(inflictor) or inflictor:GetClass() ~= self.class or not inflictor.PAPUpgrade then return end

        if IsBaddie(ply) then
            attacker:ChatPrint("Killed a bad guy! You can shoot again")

            timer.Simple(0.1, function()
                inflictor:SetClip1(1)
            end)
        else
            attacker:ChatPrint("Didn't shoot a bad guy! One of them just got an extra life!")

            for _, p in ipairs(self:GetAlivePlayers()) do
                if IsBaddie(p) then
                    p.PAPPlatinumGunExtraLife = true
                    p:PrintMessage(HUD_PRINTCENTER, "You got an extra life! Someone whiffed with the Platinum Gun!")
                    p:PrintMessage(HUD_PRINTTALK, "You got an extra life! Someone whiffed with the Platinum Gun!")
                    break
                end
            end
        end
    end)
end

function UPGRADE:Reset()
    for _, ply in ipairs(player.GetAll()) do
        ply.PAPPlatinumGunExtraLife = nil
    end
end

TTTPAP:Register(UPGRADE)