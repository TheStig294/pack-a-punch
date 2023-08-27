-- Default gun stats for PAP
-- By default, weapons get a 1.5 firerate upgrade
-- Unless specified by an upgrade object, or the weapon is not normally found on the ground (SWEP.AutoSpawnable = true)
local UPGRADE = {}
UPGRADE.id = "_default_upgrade"
UPGRADE.class = "_default_upgrade"
UPGRADE.name = nil
UPGRADE.desc = "1.5x firerate increase!"
UPGRADE.firerateMult = 1.5
TTTPAP:Register(UPGRADE)