local UPGRADE = {}
UPGRADE.id = "firerate"
UPGRADE.class = nil
UPGRADE.name = nil
UPGRADE.desc = "1.5x firerate increase!"

local multCvar = CreateConVar("pap_firerate_multiplier", "1.5", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Firerate multiplier", 1, 10)

UPGRADE.convars = {
    {
        name = "pap_firerate_multiplier",
        type = "float",
        decimals = 1
    }
}

UPGRADE.firerateMult = multCvar:GetFloat()
TTTPAP:Register(UPGRADE)