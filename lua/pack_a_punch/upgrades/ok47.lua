local UPGRADE = {}
UPGRADE.id = "ok47"
UPGRADE.class = "weapon_ttt_ak47"
UPGRADE.name = "OK-47"
UPGRADE.desc = "Heals instead!"

function UPGRADE:Apply(SWEP)
    SWEP:GetOwner().PAPOk47 = SWEP

    self:AddHook("EntityTakeDamage", function(ent, dmg)
        if CLIENT or not IsValid(SWEP) then return end
        local attacker = dmg:GetAttacker()
        if not self:IsPlayer(attacker) then return end
        local inflictor = attacker:GetActiveWeapon()

        if attacker.PAPOk47 and inflictor == attacker.PAPOk47 then
            ent:SetHealth(math.min(ent:GetMaxHealth(), ent:Health() + dmg:GetDamage()))

            return true
        end
    end)
end

TTTPAP:Register(UPGRADE)