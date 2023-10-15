local UPGRADE = {}
UPGRADE.id = "perk_speed_life_passive"
UPGRADE.class = "ttt_perk_speedcola"
UPGRADE.name = "Speed Life"
UPGRADE.desc = "Speeds up your life!\n(Increased movement and shoot speed for main gun, if you have one)"

function UPGRADE:Apply(SWEP)
    local owner = SWEP:GetOwner()

    timer.Simple(3.2, function()
        if IsValid(owner) and GetRoundState() == ROUND_ACTIVE then
            -- Speeds up player movement and heavy weapon shoot speed if they have one
            if SERVER then
                owner:SetLaggedMovementValue(owner:GetLaggedMovementValue() * 1.2)
            end

            for _, wep in ipairs(owner:GetWeapons()) do
                if wep.Kind == WEAPON_HEAVY and wep.Primary and isnumber(wep.Primary.Delay) then
                    wep.Primary.Delay = wep.Primary.Delay / 1.2
                    break
                end
            end
        end
    end)
end

TTTPAP:Register(UPGRADE)