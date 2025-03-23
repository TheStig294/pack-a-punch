local UPGRADE = {}
UPGRADE.id = "all_stats_up"
UPGRADE.class = nil
UPGRADE.name = nil
UPGRADE.desc = "All stats up!"

local firerateCvar = CreateConVar("pap_all_stats_up_firerate_mult", "1.3", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Firerate multiplier", 1, 5)

local damageCvar = CreateConVar("pap_all_stats_up_damage_mult", "1.1", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Damage multiplier", 1, 5)

local spreadCvar = CreateConVar("pap_all_stats_up_spread_mult", "0.5", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Spread multiplier", 1, 5)

local ammoCvar = CreateConVar("pap_all_stats_up_ammo_mult", "1.5", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Ammo multiplier", 1, 5)

local recoilCvar = CreateConVar("pap_all_stats_up_recoil_mult", "0.5", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Recoil multiplier", 0, 1)

UPGRADE.convars = {
    {
        name = "pap_all_stats_up_firerate_mult",
        type = "float",
        decimals = 1
    },
    {
        name = "pap_all_stats_up_damage_mult",
        type = "float",
        decimals = 1
    },
    {
        name = "pap_all_stats_up_spread_mult",
        type = "float",
        decimals = 1
    },
    {
        name = "pap_all_stats_up_ammo_mult",
        type = "float",
        decimals = 1
    },
    {
        name = "pap_all_stats_up_recoil_mult",
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