local UPGRADE = {}
UPGRADE.id = "soul_powerer"
UPGRADE.class = "weapon_ttt_smg_soulbinding"
UPGRADE.name = "Soul Powerer"

UPGRADE.convars = {
    {
        name = "pap_soul_powerer_extra_abilities",
        type = "int"
    }
}

local extraAbilitiesCvar = CreateConVar("pap_soul_powerer_extra_abilities", "3", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Number of extra abilities", 1, 8)

UPGRADE.desc = "The Soulbound gains " .. extraAbilitiesCvar:GetInt() .. " extra abilities!"
local oldAbilityCount
local maxAbilitiesCvar

function UPGRADE:Apply(SWEP)
    if CLIENT then return end
    maxAbilitiesCvar = maxAbilitiesCvar or GetConVar("ttt_soulbound_max_abilities")

    if not oldAbilityCount then
        oldAbilityCount = maxAbilitiesCvar:GetInt()
    end

    maxAbilitiesCvar:SetInt(maxAbilitiesCvar:GetInt() + extraAbilitiesCvar:GetInt())
end

function UPGRADE:Reset()
    if CLIENT then return end
    maxAbilitiesCvar = maxAbilitiesCvar or GetConVar("ttt_soulbound_max_abilities")

    if oldAbilityCount then
        maxAbilitiesCvar:SetInt(oldAbilityCount)
        oldAbilityCount = nil
    end
end

TTTPAP:Register(UPGRADE)