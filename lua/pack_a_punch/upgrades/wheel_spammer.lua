local UPGRADE = {}
UPGRADE.id = "wheel_spammer"
UPGRADE.class = "weapon_whl_spinner"
UPGRADE.name = "Wheel Spammer"
UPGRADE.desc = "No cooldown, spin the wheel faster!"
local OGWheelTime

function UPGRADE:Apply(SWEP)
    if SERVER then
        local wheelTimeCvar = GetConVar("ttt_wheelboy_wheel_time")
        OGWheelTime = wheelTimeCvar:GetInt()
        wheelTimeCvar:SetInt(3)
    end

    self:AddToHook(SWEP, "PrimaryAttack", function()
        local owner = SWEP:GetOwner()
        if not IsValid(owner) then return end
        owner:SetNWInt("WheelBoyNextSpinTime", CurTime())
    end)
end

function UPGRADE:Reset()
    if SERVER then
        RunConsoleCommand("ttt_wheelboy_wheel_time", OGWheelTime)
    end
end

TTTPAP:Register(UPGRADE)