local UPGRADE = {}
UPGRADE.id = "all_stats_up"
UPGRADE.class = nil
UPGRADE.name = nil
UPGRADE.desc = "All stats up!"

local firerateCvar = CreateConVar("pap_all_stats_up_firerate", "1.1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Firerate multiplier", 1, 10)

local damageCvar = CreateConVar("pap_all_stats_up_damage", "1.1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Damage multiplier", 1, 10)

local spreadCvar = CreateConVar("pap_all_stats_up_spread", "1.3", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Spread multiplier", 1, 10)

local ammoCvar = CreateConVar("pap_all_stats_up_ammo", "1.2", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Ammo multiplier", 1, 10)

local recoilCvar = CreateConVar("pap_all_stats_up_recoil", "0.75", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Recoil multiplier", 0, 1)

UPGRADE.convars = {
    {
        name = "pap_all_stats_up_firerate",
        type = "float",
        decimals = 1
    },
    {
        name = "pap_all_stats_up_damage",
        type = "float",
        decimals = 1
    },
    {
        name = "pap_all_stats_up_spread",
        type = "float",
        decimals = 1
    },
    {
        name = "pap_all_stats_up_ammo",
        type = "float",
        decimals = 1
    },
    {
        name = "pap_all_stats_up_recoil",
        type = "float",
        decimals = 1
    },
}

UPGRADE.firerateMult = firerateCvar:GetFloat()
UPGRADE.damageMult = damageCvar:GetFloat()
UPGRADE.spreadMult = spreadCvar:GetFloat()
UPGRADE.ammoMult = ammoCvar:GetFloat()
UPGRADE.recoilMult = recoilCvar:GetFloat()
TTTPAP:Register(UPGRADE)