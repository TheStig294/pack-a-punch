local UPGRADE = {}
UPGRADE.id = "recoil"
UPGRADE.class = nil
UPGRADE.name = nil

local multCvar = CreateConVar("pap_recoil_mult", "0.1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Recoil multiplier", 0, 1)

UPGRADE.desc = "x" .. math.Round(1 / multCvar:GetFloat()) .. " less recoil!"

UPGRADE.convars = {
    {
        name = "pap_recoil_mult",
        type = "float",
        decimals = 1
    }
}

UPGRADE.recoilMult = multCvar:GetFloat()
TTTPAP:Register(UPGRADE)