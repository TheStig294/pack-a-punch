local UPGRADE = {}
UPGRADE.id = "platinum_dragon"
UPGRADE.class = "weapon_ap_golddragon"
UPGRADE.name = "Platinum Dragon"

local multCvar = CreateConVar("pap_platinum_dragon_ammo", "3", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Ammo multiplier", 1, 10)

UPGRADE.desc = "x" .. multCvar:GetInt() .. " ammo"

UPGRADE.convars = {
    {
        name = "pap_platinum_dragon_ammo",
        type = "int"
    }
}

UPGRADE.ammoMult = multCvar:GetInt()
TTTPAP:Register(UPGRADE)