local UPGRADE = {}
UPGRADE.id = "kfcenator"
UPGRADE.class = "weapon_ttt_chickenator"
UPGRADE.name = "KFCenator"
UPGRADE.desc = "Shoots KFC instead"
UPGRADE.ammoMult = 3

function UPGRADE:Apply(SWEP)
    function SWEP:PrimaryAttack()
        if not self:CanPrimaryAttack() then return end
        local owner = self:GetOwner()
        self.Attacking = false

        if not self.Attacking then
            self:SetNextPrimaryFire(CurTime() + 1)
            self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
            self.Attacking = true
        end

        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
        owner:SetAnimation(PLAYER_ATTACK1)
        self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
        if not SERVER then return end
        local plrang = owner:EyeAngles()
        local muzzlepos = owner:GetShootPos() + plrang:Right() * -2.5 - plrang:Up() * 7
        local muzzleforward = (util.TraceLine(util.GetPlayerTrace(owner)).HitPos - muzzlepos):GetNormalized()
        local kfc = ents.Create("ttt_kfc")
        kfc:SetPos(muzzlepos + muzzleforward * 5)
        kfc:SetAngles((muzzleforward + VectorRand() * 0.4):Angle())
        kfc:SetOwner(owner)
        kfc:Spawn()
        kfc:Activate()
        local kfcphys = kfc:GetPhysicsObject()

        if kfcphys:IsValid() then
            kfcphys:AddVelocity(muzzleforward * 1100)
            kfcphys:AddAngleVelocity(VectorRand() * 700)
        end

        self:TakePrimaryAmmo(1)
    end
end

TTTPAP:Register(UPGRADE)