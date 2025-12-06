local UPGRADE = {}
UPGRADE.id = "auto_uno_reverse"
UPGRADE.class = "weapon_unoreverse"
UPGRADE.name = "Auto UNO Reverse"
UPGRADE.desc = "Activates automatically while held!"

function UPGRADE:Apply(SWEP)
    self:AddHook("EntityTakeDamage", function(victim, _)
        if not IsValid(victim) or not victim:IsPlayer() then return end
        local wep = victim:GetActiveWeapon(self.class)
        if not self:IsValidUpgrade(wep) then return end
        victim:SelectWeapon(self.class)
        wep:PrimaryAttack()
        wep:CallOnClient("PrimaryAttack")
    end)
end

TTTPAP:Register(UPGRADE)