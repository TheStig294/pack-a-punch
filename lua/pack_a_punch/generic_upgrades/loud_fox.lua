local UPGRADE = {}
UPGRADE.id = "loud_fox"
UPGRADE.class = "weapon_ttt_tmp_s"
UPGRADE.name = "Loud Fox"

local multCvar = CreateConVar("pap_loud_fox_firerate", "1.5", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Firerate multiplier", 1, 5)

UPGRADE.desc = "x" .. multCvar:GetFloat() .. " firerate, unsilenced"

UPGRADE.convars = {
    {
        name = "pap_loud_fox_firerate",
        type = "int"
    }
}

UPGRADE.firerateMult = multCvar:GetFloat()
TTTPAP:Register(UPGRADE)