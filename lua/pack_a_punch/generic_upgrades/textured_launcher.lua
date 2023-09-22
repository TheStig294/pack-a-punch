local UPGRADE = {}
UPGRADE.id = "textured_launcher"
UPGRADE.class = "weapon_hp_glauncher"
UPGRADE.name = "Textured Launcher"

local multCvar = CreateConVar("pap_textured_launcher_ammo", "1.5", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Ammo multiplier", 1, 5)

UPGRADE.desc = "Is now textured, x" .. multCvar:GetFloat() .. " ammo"

UPGRADE.convars = {
    {
        name = "pap_textured_launcher_ammo",
        type = "int"
    }
}

UPGRADE.ammoMult = multCvar:GetFloat()
TTTPAP:Register(UPGRADE)