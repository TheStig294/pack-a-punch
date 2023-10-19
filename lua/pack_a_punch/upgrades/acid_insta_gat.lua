local UPGRADE = {}
UPGRADE.id = "acid_insta_gat"
UPGRADE.class = "tfa_acidgat"
UPGRADE.name = "Insta-gat"
UPGRADE.desc = "Extra ammo + faster reload!"

function UPGRADE:Apply(SWEP)
    -- Is a CoD weapon, so has its own PAP function we can take advantage of, this is not from this mod
    SWEP:OnPaP()

    function SWEP:Reload()
        if self:Clip1() == self.Primary.ClipSize or self:GetOwner():GetAmmoCount(self.Primary.Ammo) <= 0 then return end
        self:DefaultReload(ACT_IDLE)
    end
end

TTTPAP:Register(UPGRADE)