local UPGRADE = {}
UPGRADE.id = "adv_unsilenced_awp"
UPGRADE.class = "weapon_ttt_awp_advanced_silenced"
UPGRADE.name = "Unsilenced AWP"

local multCvar = CreateConVar("pap_adv_unsilenced_awp_ammo", "2", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Ammo multiplier", 1, 10)

UPGRADE.desc = "x" .. multCvar:GetInt() .. " ammo, unsilenced"

UPGRADE.convars = {
    {
        name = "pap_adv_unsilenced_awp_ammo",
        type = "int"
    }
}

UPGRADE.ammoMult = multCvar:GetInt()
TTTPAP:Register(UPGRADE)