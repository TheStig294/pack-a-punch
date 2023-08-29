local UPGRADE = {}
UPGRADE.id = "recoil"
UPGRADE.class = nil
UPGRADE.name = nil
UPGRADE.desc = "10x less recoil!"

local multCvar = CreateConVar("pap_recoil_multiplier", "0.1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Recoil multiplier", 0, 1)

UPGRADE.convars = {
    {
        name = "pap_recoil_multiplier",
        type = "float",
        decimals = 1
    }
}

UPGRADE.recoilMult = multCvar:GetFloat()
TTTPAP:Register(UPGRADE)