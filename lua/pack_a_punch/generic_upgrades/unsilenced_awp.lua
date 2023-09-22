local UPGRADE = {}
UPGRADE.id = "unsilenced_awp"
UPGRADE.class = "weapon_ttt_awp"
UPGRADE.name = "Unsilenced AWP"
UPGRADE.desc = "x2 ammo, unsilenced"

local multCvar = CreateConVar("pap_unsilenced_awp_ammo", "2", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Ammo multiplier", 1, 10)

UPGRADE.convars = {
    {
        name = "pap_ammo_multiplier",
        type = "int"
    }
}

UPGRADE.ammoMult = multCvar:GetFloat()
TTTPAP:Register(UPGRADE)