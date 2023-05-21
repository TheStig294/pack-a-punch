AddCSLuaFile()
SWEP.HoldType = "normal"

if CLIENT then
    SWEP.PrintName = "Self-Pack-a-Punch"
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
SWEP.PAPDesc = "You pack-a-punched yourself!\nSpeed, jump and health boost!"
local buffScale = 1.2
local buffScaleJump = 1.5

function SWEP:GetClass()
    return "weapon_ttt_unarmed_pap"
end

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)

    timer.Simple(0.1, function()
        local owner = self:GetOwner()

        if IsValid(owner) and owner:IsPlayer() then
            self.HolsterPAPOwner = owner
            owner:SetMaterial(TTT_PAP_CAMO)
            owner:SetFOV(0)
            owner:SetFOV(owner:GetFOV() * buffScale)
            owner:SetJumpPower(owner:GetJumpPower() * buffScaleJump)
            owner:SetHealth(owner:Health() * buffScale)

            if SERVER then
                owner:SetMaxHealth(owner:GetMaxHealth() * buffScale)
                owner:SetLaggedMovementValue(owner:GetLaggedMovementValue() * buffScale)
            end
        end
    end)
end

if SERVER then
    hook.Add("TTTEndRound", "TTTPAPHolsteredReset", function()
        for _, ply in ipairs(player.GetAll()) do
            if ply:HasWeapon("weapon_ttt_unarmed_pap") then
                ply:StripWeapon("weapon_ttt_unarmed_pap")
                ply:Give("weapon_ttt_unarmed")
            end
        end
    end)
end

function SWEP:OnRemove()
    local owner = self.HolsterPAPOwner

    if IsValid(owner) and owner:IsPlayer() then
        owner:SetMaterial("")
        owner:SetFOV(0)
        owner:SetJumpPower(owner:GetJumpPower() / buffScaleJump)
        owner:SetHealth(owner:Health() / buffScale)

        if SERVER then
            owner:ChatPrint("Your pack-a-punch buff has been removed")
            owner:SetMaxHealth(owner:GetMaxHealth() / buffScale)
            owner:SetLaggedMovementValue(owner:GetLaggedMovementValue() / buffScale)
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

function SWEP:ShouldDrawViewModel()
    return false
end