local UPGRADE = {}
UPGRADE.id = "groovitron_dance_dead"
UPGRADE.class = "dancedead"
UPGRADE.name = "Groovitron"
UPGRADE.desc = "Makes players dance in an AOE!\nIf you don't kill them first, they will be freed"
UPGRADE.newClass = "ttt_pap_groovitron"
UPGRADE.noCamo = true
UPGRADE.ammoMult = -1

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

TTTPAP:Register(UPGRADE)