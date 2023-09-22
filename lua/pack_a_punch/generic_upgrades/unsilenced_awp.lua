local UPGRADE = {}
UPGRADE.id = "unsilenced_awp"
UPGRADE.class = "weapon_ttt_awp"
UPGRADE.name = "Unsilenced AWP"

local multCvar = CreateConVar("pap_unsilenced_awp_ammo", "2", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Ammo multiplier", 1, 10)

UPGRADE.desc = "x" .. multCvar:GetInt() .. " ammo, unsilenced"

UPGRADE.convars = {
    {
        name = "pap_unsilenced_awp_ammo",
        type = "int"
    }
}

UPGRADE.ammoMult = multCvar:GetInt()
TTTPAP:Register(UPGRADE)