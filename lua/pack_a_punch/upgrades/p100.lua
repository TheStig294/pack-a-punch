local UPGRADE = {}
UPGRADE.id = "p100"
UPGRADE.class = "weapon_ttt_p90"
UPGRADE.name = "P100"
UPGRADE.desc = "100 clip size + ammo refill!"

function UPGRADE:Apply(SWEP)
    self:SetClip(SWEP, 100)
end

TTTPAP:Register(UPGRADE)