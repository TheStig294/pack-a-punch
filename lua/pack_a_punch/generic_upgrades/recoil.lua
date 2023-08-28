local UPGRADE = {}
UPGRADE.id = "recoil"
UPGRADE.class = nil
UPGRADE.name = nil
UPGRADE.desc = "10x less recoil!"

local multCvar = CreateConVar("ttt_pap_recoil_multiplier", "1.5", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Recoil multiplier", 0, 1)

UPGRADE.convars = {
    {
        name = "ttt_pap_recoil_multiplier",
        type = "float",
        decimals = 1
    }
}

UPGRADE.recoilMult = multCvar:GetFloat()
TTTPAP:Register(UPGRADE)