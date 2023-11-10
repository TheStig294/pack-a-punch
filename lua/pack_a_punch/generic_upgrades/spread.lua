local UPGRADE = {}
UPGRADE.id = "spread"
UPGRADE.class = nil
UPGRADE.name = nil

local multCvar = CreateConVar("pap_spread_multiplier", "1.5", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Spread multiplier", 1, 10)

UPGRADE.desc = "x" .. math.Round(multCvar:GetFloat(), 1) .. " tighter bullet spread!"

UPGRADE.convars = {
    {
        name = "pap_spread_multiplier",
        type = "float",
        decimals = 1
    }
}

UPGRADE.spreadMult = multCvar:GetFloat()
TTTPAP:Register(UPGRADE)