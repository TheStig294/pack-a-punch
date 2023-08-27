TTT_PAP_UPGRADES = TTT_PAP_UPGRADES or {}

local badgeTimeCvar = CreateConVar("ttt_pap_deputy_badge_time", "4", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds to use deputy badge", 0, 60)

local class = "weapon_mhl_badge"
TTTPAP.convars[class] = {}

table.insert(TTTPAP.convars[class], {
    name = "ttt_pap_deputy_badge_time",
    type = "float",
    decimals = 1
})

TTT_PAP_UPGRADES.weapon_mhl_badge = {
    name = "Sheriff Badge",
    desc = "Takes less time to use!",
    func = function(SWEP)
        if SERVER then
            SWEP.DeviceTimeConVar = badgeTimeCvar
            SWEP:SetChargeTime(SWEP.DeviceTimeConVar:GetInt())
        end
    end
}