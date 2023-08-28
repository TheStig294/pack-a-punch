local UPGRADE = {}
UPGRADE.id = "spread"
UPGRADE.class = nil
UPGRADE.name = nil
UPGRADE.desc = "x2 tighter bullet spread!"

local multCvar = CreateConVar("ttt_pap_spread_multiplier", "1.5", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Spread multiplier", 1, 10)

UPGRADE.convars = {
    {
        name = "ttt_pap_spread_multiplier",
        type = "float",
        decimals = 1
    }
}

UPGRADE.spreadMult = multCvar:GetFloat()
TTTPAP:Register(UPGRADE)