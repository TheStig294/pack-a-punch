local UPGRADE = {}
UPGRADE.id = "self_pack_a_punch"
UPGRADE.class = "weapon_ttt_unarmed"
UPGRADE.name = "Self-Pack-a-Punch"
UPGRADE.desc = "You pack-a-punched yourself!\nSpeed, jump and health boost!"

UPGRADE.convars = {
    {
        name = "pap_self_pack_a_punch_speed",
        type = float,
        decimals = 1
    },
    {
        name = "pap_self_pack_a_punch_jump",
        type = float,
        decimals = 1
    },
    {
        name = "pap_self_pack_a_punch_health",
        type = float,
        decimals = 1
    }
}

local speedMult = CreateConVar("pap_self_pack_a_punch_speed", "1.2", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Speed multiplier", 1, 5)

local jumpMult = CreateConVar("pap_self_pack_a_punch_jump", "1.5", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Jump height multiplier", 1, 5)

local healthMult = CreateConVar("pap_self_pack_a_punch_health", "1.2", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Health multiplier", 1, 5)

local speedScale = speedMult:GetFloat()
local jumpScale = jumpMult:GetFloat()
local healthScale = healthMult:GetFloat()

function UPGRADE:Apply(SWEP)
    self:SetHoldType(self.HoldType)

    timer.Simple(0.1, function()
        local owner = self:GetOwner()

        if IsValid(owner) and owner:IsPlayer() then
            self.HolsterPAPOwner = owner
            owner:SetMaterial(TTTPAP.camo)
            owner:SetFOV(0)
            owner:SetFOV(owner:GetFOV() * speedScale)
            owner:SetJumpPower(owner:GetJumpPower() * jumpScale)
            owner:SetHealth(owner:Health() * healthScale)

            if SERVER then
                owner:SetMaxHealth(owner:GetMaxHealth() * healthScale)
                owner:SetLaggedMovementValue(owner:GetLaggedMovementValue() * speedScale)
            end
        end
    end)

    function SWEP:OnRemove()
        local owner = self.HolsterPAPOwner
    
        if IsValid(owner) and owner:IsPlayer() then
            owner:SetMaterial("")
            owner:SetFOV(0)
            owner:SetJumpPower(owner:GetJumpPower() / jumpScale)
            owner:SetHealth(owner:Health() / healthScale)
    
            if SERVER then
                owner:ChatPrint("Your pack-a-punch buff has been removed")
                owner:SetMaxHealth(owner:GetMaxHealth() / healthScale)
                owner:SetLaggedMovementValue(owner:GetLaggedMovementValue() / speedScale)
            end
        end
    end
end

function UPGRADE:Reset()
    if SERVER then
        for _, ply in ipairs(player.GetAll()) do
            if ply:HasWeapon("weapon_ttt_unarmed") then
                ply:StripWeapon("weapon_ttt_unarmed")
                ply:Give("weapon_ttt_unarmed")
            end
        end
    end
end

TTTPAP:Register(UPGRADE)