local UPGRADE = {}
UPGRADE.id = "ok47_golden"
UPGRADE.class = "weapon_ttt_ak47gold"
UPGRADE.name = "OK-47"
UPGRADE.desc = "While held, basic sources of damage you deal heal instead!"

function UPGRADE:Apply(SWEP)
    self:AddHook("EntityTakeDamage", function(ent, dmg)
        if CLIENT or not IsValid(SWEP) then return end
        local attacker = dmg:GetAttacker()
        if not self:IsPlayer(attacker) then return end
        local wep = attacker:GetActiveWeapon()

        if self:IsUpgraded(wep) then
            ent:SetHealth(math.min(ent:GetMaxHealth(), ent:Health() + dmg:GetDamage()))

            return true
        end
    end)
end

TTTPAP:Register(UPGRADE)