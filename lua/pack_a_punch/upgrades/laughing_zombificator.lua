local UPGRADE = {}
UPGRADE.id = "laughing_zombificator"
UPGRADE.class = "weapon_mad_zombificator"
UPGRADE.name = "Laughing Zombificator"
UPGRADE.desc = "Make evil laughs, takes less time to use!"

UPGRADE.convars = {
    {
        name = "pap_laughing_zombificator_time",
        type = "float",
        decimals = 1
    }
}

local deviceTimeCvar = CreateConVar("pap_laughing_zombificator_time", "2", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds to use", 0, 60)

function UPGRADE:Apply(SWEP)
    if SERVER then
        SWEP.DeviceTimeConVar = deviceTimeCvar

        self:AddHook("TTTMadScientistZombifyBegin", function(owner, _)
            owner:EmitSound("ttt_pack_a_punch/mad_scientist_device/laugh" .. math.random(1, 7) .. ".mp3")
        end)
    end
end

TTTPAP:Register(UPGRADE)