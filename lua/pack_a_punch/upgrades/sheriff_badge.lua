local UPGRADE = {}
UPGRADE.id = "sheriff_badge"
UPGRADE.class = "weapon_mhl_badge"
UPGRADE.name = "Sheriff Badge"
UPGRADE.desc = "Takes less time to use!"

UPGRADE.convars = {
    {
        name = "ttt_pap_deputy_badge_time",
        type = "float",
        decimals = 1
    }
}

local badgeTimeCvar = CreateConVar("ttt_pap_deputy_badge_time", "4", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds to use deputy badge", 0, 60)

function UPGRADE:Apply(SWEP)
    if SERVER then
        SWEP.DeviceTimeConVar = badgeTimeCvar
        SWEP:SetChargeTime(SWEP.DeviceTimeConVar:GetInt())
    end
end

TTTPAP:Register(UPGRADE)