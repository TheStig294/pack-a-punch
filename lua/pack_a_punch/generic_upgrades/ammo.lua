local UPGRADE = {}
UPGRADE.id = "ammo"
UPGRADE.class = nil
UPGRADE.name = nil

local multCvar = CreateConVar("pap_ammo_mult", "2", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Ammo multiplier", 1, 5)

UPGRADE.desc = "x" .. math.Round(multCvar:GetFloat(), 1) .. " ammo increase!"

UPGRADE.convars = {
    {
        name = "pap_ammo_mult",
        type = "float",
        decimals = 1
    }
}

UPGRADE.ammoMult = multCvar:GetFloat()
TTTPAP:Register(UPGRADE)