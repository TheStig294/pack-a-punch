AddCSLuaFile()
SWEP.HoldType = "pistol"

if CLIENT then
    SWEP.PrintName = "Pokeball"
    SWEP.Slot = 6
    SWEP.ViewModelFOV = 54
    SWEP.ViewModelFlip = false
    SWEP.Icon = ""
end

SWEP.Base = "weapon_tttbase"
SWEP.Primary.Ammo = "AirboatGun"
SWEP.Primary.Recoil = 0
SWEP.Primary.Damage = 0
SWEP.Primary.Delay = 1.0
SWEP.Primary.Cone = 0.01
SWEP.Primary.ClipSize = -1
SWEP.Primary.Automatic = false
SWEP.Primary.DefaultClip = -1
SWEP.Primary.ClipMax = -1
SWEP.Kind = WEAPON_EQUIP
SWEP.UseHands = true
SWEP.ViewModel = Model("models/weapons/c_357.mdl")
SWEP.WorldModel = Model("models/ttt_pack_a_punch/pokeball/pokeball.mdl")

function SWEP:PrimaryAttack()
    if CLIENT then return end
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    -- if not self:CanPrimaryAttack() then return end
    -- self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    local TraceResult = owner:GetEyeTrace()
    local pokeball = ents.Create("ttt_pap_pokeball")
    pokeball:SetPos(TraceResult.HitPos + Vector(0, 0, 25))
    pokeball:Spawn()
end

function SWEP:SecondaryAttack()
end