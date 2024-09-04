local UPGRADE = {}
UPGRADE.id = "sharxcalibur"
UPGRADE.class = "weapon_shark_idol"
UPGRADE.name = "Sharxcalibur"
UPGRADE.desc = "More damage, more range, more sword than shark!"
UPGRADE.newClass = "weapon_sharxcalibur"
UPGRADE.noCamo = true

function UPGRADE:Condition(SWEP)
    -- If we're just checking the buy menu icon, this weapon is always upgradeable
    if not IsValid(SWEP) then return true end
    -- If the weapon is bought and valid, make sure it isn't in the process of being used before letting it be upgraded
    -- (Else it could be used twice, which typically PaP upgrades don't allow, unless that is the upgrade in of itself)
    local owner = SWEP:GetOwner()

    return not IsValid(owner) or not owner:GetNWBool("bonInv")
end

TTTPAP:Register(UPGRADE)