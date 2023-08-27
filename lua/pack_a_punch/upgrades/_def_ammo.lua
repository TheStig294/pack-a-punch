local UPGRADE = {}
UPGRADE.id = "_def_ammo"
UPGRADE.class = nil
UPGRADE.name = nil
UPGRADE.desc = "1.5x ammo increase!"

local multCvar = CreateConVar("ttt_pap__def_ammo_multiplier", "1.5", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Ammo multiplier", 1, 10)

UPGRADE.convars = {
    {
        name = "ttt_pap__def_ammo_multiplier",
        type = "float",
        decimals = 1
    }
}

UPGRADE.ammoMult = multCvar:GetFloat()
TTTPAP:Register(UPGRADE)