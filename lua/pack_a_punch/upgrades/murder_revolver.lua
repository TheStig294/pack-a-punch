local UPGRADE = {}
UPGRADE.id = "murder_revolver"
UPGRADE.class = "weapon_ttt_randomatrevolver"
UPGRADE.name = "Murder Revolver"
UPGRADE.desc = "Allows you to reload-cancel"

function UPGRADE:Apply(SWEP)
    SWEP.Primary.Delay = 2.25
end

TTTPAP:Register(UPGRADE)