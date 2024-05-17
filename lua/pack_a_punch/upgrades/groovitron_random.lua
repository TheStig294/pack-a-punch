local UPGRADE = {}
UPGRADE.id = "groovitron_random"
UPGRADE.class = "weapon_ttt_dancedead"
UPGRADE.name = "Groovitron"
UPGRADE.desc = "Makes players dance in an AOE!"
UPGRADE.newClass = "ttt_pap_groovitron"
UPGRADE.noCamo = true

UPGRADE.convars = {
    {
        name = "pap_groovitron_duration",
        type = "int"
    },
    {
        name = "pap_groovitron_radius",
        type = "int"
    }
}
-- TTTPAP:Register(UPGRADE)