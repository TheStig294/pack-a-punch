local UPGRADE = {}
UPGRADE.id = "perk_staminmax_passive"
UPGRADE.class = "ttt_perk_staminup"
UPGRADE.name = "Staminmax"
UPGRADE.desc = "Double walk speed"

function UPGRADE:Apply(SWEP)
    local owner = SWEP:GetOwner()

    timer.Simple(3.2, function()
        if IsValid(owner) and GetRoundState() == ROUND_ACTIVE then
            -- This is reset on player spawn by TTT itself
            owner:SetWalkSpeed(owner:GetWalkSpeed() * 2)
        end
    end)
end

TTTPAP:Register(UPGRADE)