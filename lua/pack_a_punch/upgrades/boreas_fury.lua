local UPGRADE = {}
UPGRADE.id = "boreas_fury"
UPGRADE.class = "tfa_staff_wind"
UPGRADE.name = "Boreas' Fury"
UPGRADE.desc = "Hold left-click: Charged attack\nRight-click: Melee attack"
UPGRADE.newClass = "tfa_staff_wind_ult"
UPGRADE.noCamo = true

function UPGRADE:Apply(SWEP)
    local owner = SWEP:GetOwner()
    owner:SetAmmo(0, "Thumper")

    timer.Simple(0.1, function()
        SWEP:SetClip1(SWEP.Primary.ClipSize)
    end)
end

TTTPAP:Register(UPGRADE)