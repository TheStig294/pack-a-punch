local UPGRADE = {}
UPGRADE.id = "vr_infinity"
UPGRADE.class = "tfa_vr11"
UPGRADE.name = "VR-Infinity"
UPGRADE.desc = "Unlimited ammo!"
UPGRADE.noSound = true

function UPGRADE:Apply(SWEP)
    SWEP.PAPOldPrimaryAttack = SWEP.PrimaryAttack

    function SWEP:PrimaryAttack()
        self:PAPOldPrimaryAttack()
        self:SetClip1(self.Primary.ClipSize)
    end
end

TTTPAP:Register(UPGRADE)