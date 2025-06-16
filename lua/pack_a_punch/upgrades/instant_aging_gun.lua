local UPGRADE = {}
UPGRADE.id = "instant_aging_gun"
UPGRADE.class = "weapon_pnr_poisongun"
UPGRADE.name = "Instant Aging Gun"
UPGRADE.desc = "Turns someone into an Old Man!"

function UPGRADE:Apply(SWEP)
    self:AddHook("PostEntityFireBullets", function(ent, data)
        if not self:IsPlayer(ent) then return end
        local wep = ent:GetActiveWeapon()

        if self:IsValidUpgrade(wep) then
            local victim = data.Trace.Entity
            if not self:IsPlayer(victim) then return end
            victim:SetRole(ROLE_OLDMAN)

            if SERVER then
                SetRoleHealth(victim)
                SendFullStateUpdate()
            end
        end
    end)
end

TTTPAP:Register(UPGRADE)