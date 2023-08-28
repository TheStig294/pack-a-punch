local UPGRADE = {}
UPGRADE.id = "gravity_blaster"
UPGRADE.class = "weapon_ttt_push"
UPGRADE.name = "Gravity Blaster"
UPGRADE.desc = "Full-auto push gun! Now has ammo"

function UPGRADE:Apply(SWEP)
    SWEP.Primary.ClipSize = 50
    SWEP.Primary.DefaultClip = 50
    SWEP.Primary.Delay = 0.25
    SWEP.Overheated = false

    timer.Simple(0.2, function()
        self:SetClip1(self.Primary.ClipSize)
    end)

    function SWEP:PrimaryAttack()
        if self.IsCharging or self.Overheated then return end
        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
        self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)
        self:FirePulse(600, 300)
        self:TakePrimaryAmmo(1)

        if self:Clip1() <= 0 then
            self.Overheated = true
            self:EmitSound("weapons/crossbow/bolt_skewer1.wav")
        end
    end

    function SWEP:SecondaryAttack()
    end
end

TTTPAP:Register(UPGRADE)