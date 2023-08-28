local UPGRADE = {}
UPGRADE.id = "team_health_changer"
UPGRADE.class = "weapon_tur_changer"
UPGRADE.name = "Team + Health Changer"
UPGRADE.desc = "Also sets you to 100 health!"

function UPGRADE:Apply(SWEP)
    SWEP.PAPOldPrimaryAttack = SWEP.PrimaryAttack

    function SWEP:PrimaryAttack()
        local owner = self:GetOwner()
        SWEP.PAPOldPrimaryAttack(self)

        if SERVER then
            if not IsValid(owner) then return end
            owner:SetMaxHealth(100)
            owner:SetHealth(100)
        end
    end
end

TTTPAP:Register(UPGRADE)