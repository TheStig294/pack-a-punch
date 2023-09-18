local UPGRADE = {}
UPGRADE.id = "platinum_gun_custom_roles"
UPGRADE.class = "weapon_ttt_nrgoldengun"
UPGRADE.name = "Platinum Gun"
UPGRADE.desc = "Shoot a bad guy: Get to shoot again\nDon't shoot a bad guy: One of them gets an extra life!"

function UPGRADE:Apply(SWEP)
    if SERVER then
        util.AddNetworkString("TTTPAPPlatinumGunEquipment")
    end

    local function IsBaddie(ply)
        return (ply.IsTraitorTeam and ply:IsTraitorTeam()) or (ply:GetRole() == ROLE_TRAITOR) or (ply.IsIndependentTeam and ply:IsIndependentTeam()) or (ply.IsMonsterTeam and ply:IsMonsterTeam())
    end

    SWEP.PAPOldPrimaryAttack = SWEP.PrimaryAttack

    function SWEP:PrimaryAttack()
        if SERVER and IsFirstTimePredicted() and self:Clip1() > 0 then
        local owner = self:GetOwner()
        local ent = owner:GetEyeTrace().Entity

        if not UPGRADE:IsPlayer(ent) then
            owner:ChatPrint("Didn't shoot a bad guy! One of them just got an extra life!")
        
            for _, ply in ipairs(UPGRADE:GetAlivePlayers()) do
                if IsBaddie(ply) then
                    ply.PAPPlatinumGunExtraLife = true
                    ply:PrintMessage(HUD_PRINTCENTER, "You got an extra life! Someone whiffed with the Platinum Gun!")
                    ply:PrintMessage(HUD_PRINTTALK, "You got an extra life! Someone whiffed with the Platinum Gun!")
                    break
                end
            end
        end
    end

        SWEP.PAPOldPrimaryAttack(self)
    end

    SWEP.PAPOldOnPlayerAttacked = SWEP.OnPlayerAttacked

    function SWEP:OnPlayerAttacked(ply)
        if SERVER then
        local attacker = self:GetOwner()

         -- Shooting platinum gun
         if IsBaddie(ply) then
             attacker:ChatPrint("Shot a bad guy! You can shoot again")
        
             timer.Simple(0.1, function()
                 self:SetClip1(1)
             end)
         else
             attacker:ChatPrint("Didn't shoot a bad guy! One of them just got an extra life!")
        
             for _, p in ipairs(UPGRADE:GetAlivePlayers()) do
                 if IsBaddie(p) then
                     p.PAPPlatinumGunExtraLife = true
                     p:PrintMessage(HUD_PRINTCENTER, "You got an extra life! Someone whiffed with the Platinum Gun!")
                     p:PrintMessage(HUD_PRINTTALK, "You got an extra life! Someone whiffed with the Platinum Gun!")
                     break
                 end
             end
         end
        end
        
         self.PAPOldOnPlayerAttacked(self, ply)
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
                net.Start("TTTPAPPlatinumGunEquipment")
                net.WriteUInt(ply.equipment_items, 32)
                net.Send(ply)

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
    end)

    if CLIENT then
        net.Receive("TTTPAPPlatinumGunEquipment", function()
            local items = net.ReadUInt(32)
            LocalPlayer().equipment_items = items
        end)
    end
end

function UPGRADE:Reset()
    for _, ply in ipairs(player.GetAll()) do
        ply.PAPPlatinumGunExtraLife = nil
    end
end

TTTPAP:Register(UPGRADE)