TTT_PAP_UPGRADES = TTT_PAP_UPGRADES or {}

local deviceTimeCvar = CreateConVar("ttt_pap_mad_scientist_device_time", "2", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds to use upgraded zombification device", 0, 60)

local class = "weapon_mad_zombificator"
TTT_PAP_CONVARS[class] = {}

table.insert(TTT_PAP_CONVARS[class], {
    name = "ttt_pap_mad_scientist_device_time",
    type = "float",
    decimal = 1
})

TTT_PAP_UPGRADES.weapon_mad_zombificator = {
    name = "Muhahahaha!",
    desc = "Make evil laughs, takes less time to use!",
    func = function(SWEP)
        if SERVER then
            SWEP.DeviceTimeConVar = deviceTimeCvar

            hook.Add("TTTMadScientistZombifyBegin", "TTTPAPMadScientistDevice", function(owner, ply)
                owner:EmitSound("ttt_pack_a_punch/mad_scientist_device/laugh" .. math.random(1, 7) .. ".mp3")
            end)
        end
    end
}