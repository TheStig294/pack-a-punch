local UPGRADE = {}
UPGRADE.id = "nice_pistol"
UPGRADE.class = "weapon_ttt_pistol_randomat"
UPGRADE.name = "Nice Pistol"
UPGRADE.desc = "Nice ammo count..."

function UPGRADE:Apply(SWEP)
    SWEP.Primary.ClipSize = 69

    timer.Simple(0.1, function()
        SWEP:SetClip1(69)
    end)
end

TTTPAP:Register(UPGRADE)