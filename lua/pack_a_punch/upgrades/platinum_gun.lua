local UPGRADE = {}
UPGRADE.id = "platinum_gun"
UPGRADE.class = "weapon_ttt_powerdeagle"
UPGRADE.name = "Platinum Gun"
UPGRADE.desc = "Shoot a traitor: Get to shoot again\nShoot anything else: A traitor gets an extra life!"

function UPGRADE:Apply(SWEP)
    self:AddHook("EntityFireBullets", function(ply, bullet)
        if not self:IsPlayer(ply) then return end
        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) or wep:GetClass() ~= self.class or not wep.PAPUpgrade then return end

        function bullet:Callback(ent, TraceResult, dmg)
            local victim = TraceResult.Entity
            local missed = false

            if not UPGRADE:IsPlayer(victim) then
                missed = true
            end

            if not missed and (ply.IsTraitorTeam and ply:IsTraitorTeam() or ply:GetRole() == ROLE_TRAITOR or ply.IsIndependentTeam and ply:IsIndependentTeam()) then
                ply:ChatPrint("Killed a traitor! You can shoot again")
            else
                ply:ChatPrint("Didn't kill a traitor! A random traitor just got an extra life!")
            end
        end
    end)
end

TTTPAP:Register(UPGRADE)