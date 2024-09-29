local UPGRADE = {}
UPGRADE.id = "damage"
UPGRADE.class = nil
UPGRADE.name = nil

local multCvar = CreateConVar("pap_damage_mult", "1.3", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Damage multiplier", 1, 5)

UPGRADE.desc = "x" .. math.Round(multCvar:GetFloat(), 1) .. " damage increase!"

UPGRADE.convars = {
    {
        name = "pap_damage_mult",
        type = "float",
        decimals = 1
    }
}

UPGRADE.damageMult = multCvar:GetFloat()
TTTPAP:Register(UPGRADE)