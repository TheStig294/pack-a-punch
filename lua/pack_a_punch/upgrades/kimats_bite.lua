local UPGRADE = {}
UPGRADE.id = "kimats_bite"
UPGRADE.class = "tfa_staff_lightning"
UPGRADE.name = "Kimat's Bite"
UPGRADE.desc = "Hold left-click: Charged attack\nRight-click: Melee attack"
UPGRADE.newClass = "tfa_staff_lightning_ult"
UPGRADE.noCamo = true

function UPGRADE:Apply(SWEP)
    local owner = SWEP:GetOwner()
    owner:SetAmmo(0, "CombineCannon")

    timer.Simple(0.1, function()
        SWEP:SetClip1(SWEP.Primary.ClipSize)
    end)
end

TTTPAP:Register(UPGRADE)