local UPGRADE = {}
UPGRADE.id = "p100"
UPGRADE.class = "weapon_ttt_p90"
UPGRADE.name = "P100"
UPGRADE.desc = "100 clip size + ammo refill!"

function UPGRADE:Apply(SWEP)
    SWEP.Primary.ClipSize = 100

    timer.Simple(0.1, function()
        SWEP:SetClip1(100)
    end)
end

TTTPAP:Register(UPGRADE)