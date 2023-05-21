AddCSLuaFile()
SWEP.HoldType = "normal"

if CLIENT then
    SWEP.PrintName = "Self-PaP"
    SWEP.Slot = 5
    SWEP.ViewModelFOV = 10
end

SWEP.Base = "weapon_tttbase"
SWEP.ViewModel = "models/weapons/v_crowbar.mdl"
SWEP.WorldModel = "models/weapons/w_crowbar.mdl"
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.Kind = WEAPON_UNARMED
SWEP.InLoadoutFor = nil
SWEP.AllowDelete = false
SWEP.AllowDrop = false
SWEP.NoSights = true
SWEP.BuffScale = 1.3

function SWEP:GetClass()
    return "weapon_ttt_unarmed_pap"
end

function SWEP:Initialize()
    local owner = self:GetOwner()

    if IsValid(owner) and owner:IsPlayer() then
        self.HolsterPAPOwner = owner
        owner:ChatPrint("You pack-a-punched yourself!")
        owner:SetMaterial(TTT_PAP_CAMO)
        owner:SetFOV(0)
        owner:SetFOV(owner:GetFOV() * self.BuffScale)
        owner:SetJumpPower(owner:GetJumpPower() * self.BuffScale)
        owner:SetHealth(owner:Health() * self.BuffScale)

        if SERVER then
            owner:SetMaxHealth(owner:GetMaxHealth() * self.BuffScale)
            owner:SetLaggedMovementValue(owner:GetLaggedMovementValue() * self.BuffScale)
        end
    end
end

function SWEP:OnRemove()
    local owner = self.HolsterPAPOwner

    if IsValid(owner) and owner:IsPlayer() then
        owner:ChatPrint("Your pack-a-punch buff has been removed")
        owner:SetMaterial("")
        owner:SetFOV(0)
        owner:SetJumpPower(owner:GetJumpPower() / self.BuffScale)
        owner:SetHealth(owner:Health() / self.BuffScale)

        if SERVER then
            owner:SetMaxHealth(owner:GetMaxHealth() / self.BuffScale)
            owner:SetLaggedMovementValue(owner:GetLaggedMovementValue() / self.BuffScale)
        end
    end
end

function SWEP:OnDrop()
    self:Remove()
end

function SWEP:ShouldDropOnDie()
    return false
end

function SWEP:PrimaryAttack()
end

function SWEP:SecondaryAttack()
end

function SWEP:Reload()
end

function SWEP:Deploy()
    if SERVER and IsValid(self:GetOwner()) then
        self:GetOwner():DrawViewModel(false)
    end

    self:DrawShadow(false)

    return true
end

function SWEP:Holster()
    return true
end

function SWEP:DrawWorldModel()
end

function SWEP:DrawWorldModelTranslucent()
end