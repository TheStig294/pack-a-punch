local UPGRADE = {}
UPGRADE.id = "damage"
UPGRADE.class = nil
UPGRADE.name = nil
UPGRADE.desc = "1.2x damage increase!"

local multCvar = CreateConVar("ttt_pap_damage_multiplier", "1.2", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Damage multiplier", 1, 10)

UPGRADE.convars = {
    {
        name = "ttt_pap_damage_multiplier",
        type = "float",
        decimals = 1
    }
}

UPGRADE.damageMult = multCvar:GetFloat()
TTTPAP:Register(UPGRADE)