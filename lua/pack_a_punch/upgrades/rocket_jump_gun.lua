local UPGRADE = {}
UPGRADE.id = "rocket_jump_gun"
UPGRADE.class = "weapon_ttt_jumpgun"
UPGRADE.name = "Rocket Jump Gun"
UPGRADE.desc = "Massively increased jump power!\nRight-click to use on someone else!"

function UPGRADE:Apply(SWEP)
    self:SetClip(SWEP, 6)
    SWEP.Primary.Automatic = false
    SWEP.Primary.Delay = 0.5
    SWEP.Primary.Recoil = 5
    SWEP.Secondary.Automatic = false
    SWEP.Secondary.Delay = 0.5

    function SWEP:LaunchPlayerViewpunch(ply)
        ply:ViewPunch(Angle(math.Rand(-0.2, -0.1) * self.Primary.Recoil, math.Rand(-0.1, 0.1) * self.Primary.Recoil, 0))
    end

    function SWEP:LaunchPlayer(ply)
        if not IsPlayer(ply) then return end
        ply:SetVelocity(ply:GetForward() * -1000)
        self:LaunchPlayerViewpunch(ply)

        if SERVER and IsFirstTimePredicted() then
            ply:EmitSound("weapons/physcannon/superphys_launch" .. math.random(1, 4) .. ".wav")
        end
    end

    function SWEP:PrimaryAttack()
        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
        self:LaunchPlayer(self:GetOwner())
    end

    function SWEP:SecondaryAttack()
        if not self:CanSecondaryAttack() then return end
        self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        self:LaunchPlayer(owner:GetEyeTrace().Entity)
        self:LaunchPlayerViewpunch(owner)
        self:TakePrimaryAmmo(1)
        local effect = EffectData()
        effect:SetEntity(owner)
        effect:SetOrigin(owner:GetShootPos())
        util.Effect("PhyscannonImpact", effect, true, true)

        if SERVER and IsFirstTimePredicted() then
            owner:EmitSound("weapons/physcannon/superphys_launch" .. math.random(1, 4) .. ".wav")
        end
    end
end
-- TTTPAP:Register(UPGRADE)