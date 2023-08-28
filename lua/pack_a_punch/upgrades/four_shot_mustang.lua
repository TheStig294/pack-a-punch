local UPGRADE = {}
UPGRADE.id = "four_shot_mustang"
UPGRADE.class = "weapon_zm_pistol"
UPGRADE.name = "4-Shot Mustang"
UPGRADE.desc = "Now an incendiary grenade launcher! (With 4 ammo)"

function UPGRADE:Apply(SWEP)
    SWEP.Primary.DefaultClip = 4
    SWEP.Primary.ClipMax = 4

    timer.Simple(0.1, function()
        if self:Clip1() > self.Primary.ClipMax then
            self:SetClip1(self.Primary.ClipMax)
        end
    end)

    -- Shooting functions largely copied from weapon_cs_base
    function SWEP:PrimaryAttack(worldsnd)
        self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)
        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
        if not self:CanPrimaryAttack() then return end

        if not worldsnd then
            self:EmitSound(self.Primary.Sound, self.Primary.SoundLevel)
        elseif SERVER then
            sound.Play(self.Primary.Sound, self:GetPos(), self.Primary.SoundLevel)
        end

        self:ShootBullet(self.Primary.Damage, self.Primary.Recoil, self.Primary.NumShots, self:GetPrimaryCone())
        -- Spawn some fire as well!
        local tr = self:GetOwner():GetEyeTrace(MASK_SHOT)
        local pos = tr.HitPos

        if IsValid(tr.Entity) then
            pos = tr.Entity:GetPos()
        end

        if SERVER then
            local fireNade = ents.Create("ttt_firegrenade_proj")
            fireNade:SetPos(pos)
            fireNade:Spawn()
            fireNade:SetDmg(20)
            fireNade:SetThrower(self:GetOwner())
            fireNade:Explode(tr)
        end

        self:TakePrimaryAmmo(1)
        local owner = self:GetOwner()
        if not IsValid(owner) or owner:IsNPC() or not owner.ViewPunch then return end
        owner:ViewPunch(Angle(util.SharedRandom(self:GetClass(), -0.2, -0.1, 0) * self.Primary.Recoil, util.SharedRandom(self:GetClass(), -0.1, 0.1, 1) * self.Primary.Recoil, 0))
    end

    function SWEP:DryFire(setnext)
        if CLIENT and LocalPlayer() == self:GetOwner() then
            self:EmitSound("Weapon_Pistol.Empty")
        end

        setnext(self, CurTime() + 0.2)
    end
end

TTTPAP:Register(UPGRADE)