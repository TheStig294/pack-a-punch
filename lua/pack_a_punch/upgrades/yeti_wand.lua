local UPGRADE = {}
UPGRADE.id = "yeti_wand"
UPGRADE.class = "weapon_yeti_club"
UPGRADE.name = "Yeti Wand"
UPGRADE.desc = "No projectile cooldown"

function UPGRADE:Apply(SWEP)
    SWEP.Secondary.Delay = SWEP.Secondary.Delay / 10
end

TTTPAP:Register(UPGRADE)