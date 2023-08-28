local UPGRADE = {}
UPGRADE.id = "shotgun_dagons_glare"
UPGRADE.class = "weapon_zm_shotgun"
UPGRADE.name = "Dagon's Glare"
UPGRADE.desc = "1.5x ammo, fire rate increase, reload multiple bullets at once!"
UPGRADE.firerateMult = 1.1
UPGRADE.ammoMult = 1.5

function UPGRADE:Apply(SWEP)
    if SERVER then
        function SWEP:PerformReload()
            local ply = self:GetOwner()
            -- prevent normal shooting in between reloads
            self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
            if not ply or ply:GetAmmoCount(self.Primary.Ammo) <= 0 then return end
            if self:Clip1() >= self.Primary.ClipSize then return end
            self:GetOwner():RemoveAmmo(math.min(4, self.Primary.ClipSize - self:Clip1()), self.Primary.Ammo, false)
            self:SetClip1(math.min(self:Clip1() + 4, self.Primary.ClipSize))
            self:SendWeaponAnim(ACT_VM_RELOAD)
            self:SetReloadTimer(CurTime() + self:SequenceDuration())
        end
    end
end

TTTPAP:Register(UPGRADE)