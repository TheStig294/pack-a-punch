local UPGRADE = {}
UPGRADE.id = "ammo"
UPGRADE.class = nil
UPGRADE.name = nil
UPGRADE.desc = "1.5x ammo increase!"

local multCvar = CreateConVar("pap_ammo_multiplier", "1.5", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Ammo multiplier", 1, 10)

UPGRADE.convars = {
    {
        name = "pap_ammo_multiplier",
        type = "float",
        decimals = 1
    }
}

UPGRADE.ammoMult = multCvar:GetFloat()
TTTPAP:Register(UPGRADE)