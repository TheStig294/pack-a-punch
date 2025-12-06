local UPGRADE = {}
UPGRADE.id = "death_stare"
UPGRADE.class = "ttt_amaterasu"
UPGRADE.name = "Death Stare"
UPGRADE.desc = "Always kills, doesn't affect your vision!"

function UPGRADE:OnPurchase(SWEP)
    SWEP.TTTPAPDeathStareDisabled = true
end

function UPGRADE:Apply(SWEP)
    SWEP.TTTPAPDeathStareDisabled = false

    -- Override the Amaterasu think hook to modify the messages sent to players and to track who has been affected by an upgraded Amaterasu
    hook.Add("Think", "AmatThink", function()
        if CLIENT then return end

        for _, owner in player.Iterator() do
            -- Don't trigger the amaterasu if a player doesn't have it, nor while it's being upgraded!
            local wep = owner:GetWeapon(self.class)
            if not IsValid(wep) or wep.TTTPAPDeathStareDisabled then return end
            -- Check for valid victim being looked at, add some lag compensation because why not!
            owner:LagCompensation(true)
            local victim = owner:GetEyeTrace().Entity
            owner:LagCompensation(false)
            if not IsValid(victim) or not victim:IsPlayer() then return end
            -- Apply Amaterasu effects
            victim:Ignite(1000, 1)
            local ownerMsg = "You have set " .. victim:Nick() .. " on fire using Amaterasu, your vision has blurred."
            local victimMsg = "You've been spotted by the Amaterasu. Get a team mate to extinguish you."
            local isUpgraded = self:IsUpgraded(wep)

            if isUpgraded then
                ownerMsg = "You have set " .. victim:Nick() .. " on fire using an UPGRADED Amaterasu, your vision has been spared!"
                victimMsg = "You've been spotted by an upgraded Amaterasu! You CANNOT be extinguished and will die!"
                local timername = "TTTPAPDeathStareKillTimer" .. victim:SteamID64()

                timer.Create(timername, 1, 5, function()
                    if not IsValid(victim) or not victim:Alive() or victim:IsSpec() then
                        timer.Remove(timername)

                        return
                    end

                    local repsLeft = timer.RepsLeft(timername)

                    if repsLeft == 0 then
                        victim:Kill()
                    else
                        local inflictor = IsValid(owner) and owner or victim
                        local dmg = DamageInfo()
                        dmg:SetDamageType(DMG_CLUB)
                        dmg:SetDamage(10)
                        dmg:SetAttacker(inflictor)
                        dmg:SetInflictor(inflictor)
                        victim:TakeDamageInfo(dmg)
                        local dmg2 = DamageInfo()
                        dmg2:SetDamageType(DMG_BURN)
                        dmg2:SetDamage(20)
                        dmg2:SetAttacker(inflictor)
                        dmg2:SetInflictor(inflictor)
                        victim:TakeDamageInfo(dmg2)
                    end
                end)
            end

            net.Start("AmaterasuToggle")
            net.WriteEntity(owner)
            net.WriteBool(false)
            net.WriteBool(not isUpgraded)
            net.Send(owner)
            owner:PrintMessage(HUD_PRINTTALK, ownerMsg)
            victim:PrintMessage(HUD_PRINTTALK, victimMsg)
            wep:Remove()
        end
    end)
end

TTTPAP:Register(UPGRADE)