local UPGRADE = {}
UPGRADE.id = "perk_extra_jugg_active"
UPGRADE.class = "zombies_perk_juggernog"
UPGRADE.name = "Extra Jugg"
UPGRADE.desc = "+1 extra health boost!"

function UPGRADE:Apply(SWEP)
    SWEP.PAPOldOnDrank = SWEP.OnDrank

    function SWEP:OnDrank()
        -- Just apply the health boost function twice
        self:PAPOldOnDrank()
        self:PAPOldOnDrank()
    end
end

TTTPAP:Register(UPGRADE)