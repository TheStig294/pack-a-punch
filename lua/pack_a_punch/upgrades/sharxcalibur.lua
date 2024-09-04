local UPGRADE = {}
UPGRADE.id = "sharxcalibur"
UPGRADE.class = "weapon_shark_idol"
UPGRADE.name = "Sharxcalibur"
UPGRADE.desc = "More damage, more range, more sword than shark!"
UPGRADE.newClass = "weapon_sharxcalibur"
UPGRADE.noCamo = true

function UPGRADE:Condition(SWEP)
    local owner = SWEP:GetOwner()

    return not IsValid(owner) or not owner:GetNWBool("bonInv")
end

TTTPAP:Register(UPGRADE)