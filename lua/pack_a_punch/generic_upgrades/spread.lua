local UPGRADE = {}
UPGRADE.id = "spread"
UPGRADE.class = nil
UPGRADE.name = nil

local multCvar = CreateConVar("pap_spread_mult", "0.1", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Spread multiplier", 1, 5)

UPGRADE.desc = "x" .. math.Round(1 / multCvar:GetFloat()) .. " tighter bullet spread!"

UPGRADE.convars = {
    {
        name = "pap_spread_mult",
        type = "float",
        decimals = 1
    }
}

UPGRADE.spreadMult = multCvar:GetFloat()
TTTPAP:Register(UPGRADE)