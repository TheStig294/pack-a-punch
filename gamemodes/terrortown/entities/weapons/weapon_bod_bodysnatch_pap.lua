SWEP.Base = "weapon_bod_bodysnatch"
SWEP.PrintName = "Quick Bodysnatcher"
SWEP.PAPDesc = "Takes less time to use!"

if SERVER then
    SWEP.DeviceTimeConVar = CreateConVar("ttt_pap_bodysnatcher_device_time", "2.5", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds to use bodysnatcher", 0, 60)
end

local class = "weapon_bod_bodysnatch_pap"
TTT_PAP_CONVARS[class] = {}

table.insert(TTT_PAP_CONVARS[class], {
    name = "ttt_pap_bodysnatcher_device_time",
    type = "float",
    decimal = 1
})