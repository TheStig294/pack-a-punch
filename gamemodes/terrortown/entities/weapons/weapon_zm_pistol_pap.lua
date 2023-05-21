AddCSLuaFile()
SWEP.HoldType = "pistol"

if CLIENT then
    SWEP.PrintName = "4-Shot Mustang"
    SWEP.Slot = 1
    SWEP.ViewModelFlip = false
    SWEP.ViewModelFOV = 54
    SWEP.Icon = "vgui/ttt/icon_pistol"
    SWEP.IconLetter = "u"
end

SWEP.Base = "weapon_tttbase"
SWEP.Kind = WEAPON_PISTOL
SWEP.WeaponID = AMMO_PISTOL
SWEP.Primary.Recoil = 1.5
SWEP.Primary.Damage = 0
SWEP.Primary.Delay = 0.38
SWEP.Primary.Cone = 0.02
SWEP.Primary.ClipSize = 4
SWEP.Primary.Automatic = false
SWEP.Primary.DefaultClip = 4
SWEP.Primary.ClipMax = 4
SWEP.Primary.Ammo = "AirboatGun"
SWEP.Primary.Sound = Sound("Weapon_FiveSeven.Single")
SWEP.AutoSpawnable = false
SWEP.AmmoEnt = nil
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/cstrike/c_pist_fiveseven.mdl"
SWEP.WorldModel = "models/weapons/w_pist_fiveseven.mdl"
SWEP.IronSightsPos = Vector(-5.95, -4, 2.799)
SWEP.IronSightsAng = Vector(0, 0, 0)
SWEP.PAPDesc = "Now a 4-shot grenade launcher!"

function SWEP:Initialize()
    timer.Simple(0.1, function()
        if self:Clip1() > self.Primary.ClipMax then
            self:SetClip1(self.Primary.ClipMax)
        end
    end)
end

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

    local fireNade = ents.Create("ttt_firegrenade_proj")
    fireNade:SetPos(pos)
    fireNade:Spawn()
    fireNade:SetDmg(20)
    fireNade:SetThrower(self:GetOwner())
    fireNade:Explode(tr)
    self:TakePrimaryAmmo(1)
    local owner = self:GetOwner()
    if not IsValid(owner) or owner:IsNPC() or (not owner.ViewPunch) then return end
    owner:ViewPunch(Angle(util.SharedRandom(self:GetClass(), -0.2, -0.1, 0) * self.Primary.Recoil, util.SharedRandom(self:GetClass(), -0.1, 0.1, 1) * self.Primary.Recoil, 0))
end

function SWEP:DryFire(setnext)
    if CLIENT and LocalPlayer() == self:GetOwner() then
        self:EmitSound("Weapon_Pistol.Empty")
    end

    setnext(self, CurTime() + 0.2)
end