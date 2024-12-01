local UPGRADE = {}
UPGRADE.id = "rocket_jump_gun"
UPGRADE.class = "weapon_ttt_jumpgun"
UPGRADE.name = "Rocket Jump Gun"
UPGRADE.desc = "Massively increased push power!\nRight-click to use on someone else!"

function UPGRADE:Apply(SWEP)
    self:SetClip(SWEP, 3)
    SWEP.Primary.Automatic = false
    SWEP.Primary.Delay = 0.5
    SWEP.Secondary.Automatic = false
    SWEP.Secondary.Delay = 0.5

    function SWEP:PrimaryAttack()
        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
        local owner = self:GetOwner()
        owner:SetVelocity(owner:GetForward() * -1000)
        self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)

        if SERVER and IsFirstTimePredicted() then
            owner:EmitSound("weapons/physcannon/superphys_launch" .. math.random(1, 4) .. ".wav")
        end
    end

    function SWEP:SecondaryAttack()
        if not self:CanPrimaryAttack() then return end
        self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)
        local owner = self:GetOwner()
        local victim = owner:GetEyeTrace().Entity
        if not UPGRADE:IsAlivePlayer(victim) then return end
        victim:SetVelocity(victim:GetUp() * 1000)
        self:TakePrimaryAmmo(1)
        self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)

        if SERVER and IsFirstTimePredicted() then
            local randomNum = math.random(1, 4)
            owner:EmitSound("weapons/physcannon/superphys_launch" .. randomNum .. ".wav")
            victim:EmitSound("weapons/physcannon/superphys_launch" .. randomNum .. ".wav")
        end
    end
end

TTTPAP:Register(UPGRADE)