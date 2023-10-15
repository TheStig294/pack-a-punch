local UPGRADE = {}
UPGRADE.id = "perk_extra_jugg_passive"
UPGRADE.class = "ttt_perk_juggernog"
UPGRADE.name = "Extra Jugg"
UPGRADE.desc = "+1 extra health boost!"

function UPGRADE:Apply(SWEP)
    local owner = SWEP:GetOwner()

    timer.Simple(3.2, function()
        if IsValid(owner) and GetRoundState() == ROUND_ACTIVE then
            owner:SetHealth(owner:Health() * 1.5)
        end
    end)
end

TTTPAP:Register(UPGRADE)