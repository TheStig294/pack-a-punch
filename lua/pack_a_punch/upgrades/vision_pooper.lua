local UPGRADE = {}
UPGRADE.id = "vision_pooper"
UPGRADE.class = "ttt_amaterasu"
UPGRADE.name = "Vision Pooper"
UPGRADE.desc = "Poops the victim's vision instead"

function UPGRADE:Apply(SWEP)
    -- Overrride the amatratsu think hook to modify the messages sent to players and to track who has been affected by an upgraded amatrasu
    hook.Add("Think", "AmatThink", function()
        if CLIENT then return end

        for _, owner in pairs(player.GetAll()) do
            -- Check for weapon being equipped
            local wep = owner:GetWeapon(self.class)
            if not IsValid(wep) or wep.PAPDoneVisionPooper then return end
            -- Check for valid victim being looked at
            local victim = owner:GetEyeTrace().Entity
            if not IsValid(victim) or not victim:IsPlayer() then return end
            -- Apply amatratsu effects
            victim:Ignite(1000, 1)
            victim:SetNWBool("amatBurning", true)
            local ownerMsg = "You have set " .. victim:Nick() .. " on fire using Amaterasu, your vision has blurred."
            local victimMsg = "You've been spotted by the Amaterasu. Get a team mate to extinguish you."

            -- Who's vision is affected is dependent on if the amatrasu was upgraded or not
            if wep.PAPUpgrade then
                ownerMsg = "You have set " .. victim:Nick() .. " on fire using an *upgraded* Amaterasu. Your vision is unaffected!"
                victimMsg = "You've been spotted by an *upgraded* Amaterasu. Your vision is blured!\nGet a team mate to extinguish you."
                net.Start("AmaterasuToggle")
                net.WriteEntity(owner)
                net.WriteBool(false)
                net.WriteBool(false)
                net.Send(owner)

                timer.Simple(0.1, function()
                    net.Start("AmaterasuToggle")
                    net.WriteEntity(victim)
                    net.WriteBool(false)
                    net.WriteBool(true)
                    net.Send(victim)
                end)
            else
                net.Start("AmaterasuToggle")
                net.WriteEntity(owner)
                net.WriteBool(false)
                net.WriteBool(true)
                net.Send(owner)
            end

            owner:PrintMessage(HUD_PRINTTALK, ownerMsg)
            victim:PrintMessage(HUD_PRINTTALK, victimMsg)
            wep.PAPDoneVisionPooper = true
            wep:Remove()
        end
    end)
end

TTTPAP:Register(UPGRADE)