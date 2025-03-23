local UPGRADE = {}
UPGRADE.id = "firerate"
UPGRADE.class = nil
UPGRADE.name = nil

local multCvar = CreateConVar("pap_firerate_mult", "1.5", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Firerate multiplier", 1, 5)

UPGRADE.desc = "x" .. math.Round(multCvar:GetFloat(), 1) .. " firerate increase!"

UPGRADE.convars = {
    {
        name = "pap_firerate_mult",
        type = "float",
        decimals = 1
    }
}

UPGRADE.firerateMult = multCvar:GetFloat()
TTTPAP:Register(UPGRADE)