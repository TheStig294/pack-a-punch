local UPGRADE = {}
UPGRADE.id = "randomat_diy_kit"
UPGRADE.class = "weapon_ttt_randomat"
UPGRADE.name = "Randomat DIY Kit"
UPGRADE.desc = nil
local makeRandomatInstalled
local malRandomatInstalled
local randomat2Installed

if SERVER then
    makeRandomatInstalled = Randomat and Randomat.Events and Randomat.Events.make
    malRandomatInstalled = ConVarExists("ttt_randomat_allow_client_list")
    randomat2Installed = Randomat and Randomat.SilentTriggerEvent and Randomat.Events and Randomat.Events.choose

    if makeRandomatInstalled then
        SetGlobalString("TTTPAPRandomatUpgradeDesc", "Make a randomat instead!")
    elseif malRandomatInstalled then
        SetGlobalString("TTTPAPRandomatUpgradeDesc", "Choose a randomat instead!")
    elseif randomat2Installed then
        SetGlobalString("TTTPAPRandomatUpgradeDesc", "Choose a randomat instead!")
    else
        SetGlobalString("TTTPAPRandomatUpgradeDesc", "Triggers 5 randomats!")
    end
end

function UPGRADE:Apply(SWEP)
    if CLIENT then
        self.desc = GetGlobalString("TTTPAPRandomatUpgradeDesc")
    end

    if SERVER then
        if makeRandomatInstalled then
            -- If "Make a Randomat!" event is available, use that instead. We also know the randomat base must be using Mal's if this event is available so we're good from here
            SWEP.EventId = "make"
        elseif malRandomatInstalled then
            -- Now if Mal's randomat is installed but the "Make a Randomat!" event is not available, then just use the default property values as-is
            SWEP.EventId = "choose"
            SWEP.EventSilent = true
        elseif randomat2Installed then
            -- If Mal's randomat is not available, but "Choose an Event!" is, then assume that base randomat 2.0 is being used, so we need to override the PrimaryAttack() hook
            function SWEP:PrimaryAttack()
                if IsFirstTimePredicted() then
                    local owner = self:GetOwner()
                    Randomat:SilentTriggerEvent("choose", owner)
                    DamageLog("RANDOMAT: " .. owner:Nick() .. " [" .. owner:GetRoleString() .. "] used their Randomat")
                    self:SetNextPrimaryFire(CurTime() + 10)
                    self:Remove()
                end
            end
        else
            -- If "Choose an event!" and "Make a randomat!" are not available, then assume Randomat 1.0 is being used, and just trigger 5 random events
            function SWEP:PrimaryAttack()
                if IsFirstTimePredicted() then
                    local owner = self:GetOwner()
                    Randomat:TriggerRandomEvent(owner)

                    timer.Create("TTTPAPRandomat1.0RandomEvents" .. owner:SteamID64(), 5, 4, function()
                        if IsValid(owner) then
                            Randomat:TriggerRandomEvent(owner)
                        end
                    end)

                    DamageLog("RANDOMAT: " .. owner:Nick() .. " [" .. owner:GetRoleString() .. "] used their Randomat")
                    self:SetNextPrimaryFire(CurTime() + 10)
                    self:Remove()
                end
            end
        end
    end
end

TTTPAP:Register(UPGRADE)