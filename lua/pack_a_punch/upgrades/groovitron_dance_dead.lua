local UPGRADE = {}
UPGRADE.id = "groovitron_dance_dead"
UPGRADE.class = "dancedead"
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