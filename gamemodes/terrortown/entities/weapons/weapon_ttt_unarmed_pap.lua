AddCSLuaFile()
SWEP.HoldType = "fist"

if CLIENT then
    SWEP.PrintName = "Fists"
    SWEP.Slot = 5
    SWEP.ViewModelFOV = 10
end

SWEP.Base = "weapon_tttbase"
SWEP.ViewModel = "models/weapons/c_arms.mdl"
SWEP.WorldModel = "models/weapons/w_crowbar.mdl"
SWEP.UseHands = true
SWEP.Primary.Damage = 30
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.Kind = WEAPON_UNARMED

SWEP.InLoadoutFor = {ROLE_INNOCENT, ROLE_TRAITOR, ROLE_DETECTIVE}

SWEP.AllowDelete = false
SWEP.AllowDrop = false
SWEP.NoSights = true
local swingSound = Sound("Weapon_Crowbar.Single")

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

function SWEP:GetClass()
    return "weapon_ttt_unarmed_pap"
end

function SWEP:OnDrop()
    self:Remove()
end

function SWEP:ShouldDropOnDie()
    return false
end

function SWEP:PrimaryAttack()
    local owner = self:GetOwner()

    if IsValid(owner) and owner:IsPlayer() then
        owner:SetAnimation(PLAYER_ATTACK1)
        self:EmitSound(swingSound)

        local animations = {ACT_VM_SWINGMISS, ACT_VM_SWINGHARD, ACT_VM_SWINGHIT}

        self:SendWeaponAnim(animations[math.random(1, #animations)])
    end
end

function SWEP:SecondaryAttack()
end

function SWEP:Reload()
end

function SWEP:Deploy()
    return true
end

function SWEP:Holster()
    return true
end