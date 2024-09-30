local UPGRADE = {}
UPGRADE.id = "chug_jug_tool"
UPGRADE.class = "weapon_ttt_fortnite_building"
UPGRADE.name = "Chug Jug Tool"

UPGRADE.convars = {
    {
        name = "pap_chug_jug_tool_shield",
        type = "int"
    },
    {
        name = "pap_chug_jug_tool_dmg_resist",
        type = "int"
    }
}

local shieldCvar = CreateConVar("pap_chug_jug_tool_shield", 100, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "No. of shield points", 1, 500)

local dmgResistCvar = CreateConVar("pap_chug_jug_tool_dmg_resist", 10, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "% damage resistance", 0, 100)

UPGRADE.desc = "Gives you a health shield!\nResists " .. dmgResistCvar:GetInt() .. "% of damage, protects from 1-shot deaths!"

function UPGRADE:Apply(SWEP)
    local owner = SWEP:GetOwner()
    local maxShield = shieldCvar:GetInt()
    local dmgResist = dmgResistCvar:GetInt()
    self:SetShield(owner, maxShield, dmgResist)
end

TTTPAP:Register(UPGRADE)