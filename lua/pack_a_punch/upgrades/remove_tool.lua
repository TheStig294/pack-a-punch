local UPGRADE = {}
UPGRADE.id = "remove_tool"
UPGRADE.class = "terror_fulton"
UPGRADE.name = "Remove Tool"
UPGRADE.desc = "Removes any prop you shoot,\nshooting a player removes the gun!"
UPGRADE.newClass = "ttt_pap_remove_tool"
UPGRADE.noSound = true
UPGRADE.noCamo = true
TTTPAP:Register(UPGRADE)