local UPGRADE = {}
UPGRADE.id = "self_pack_a_punch"
UPGRADE.class = "weapon_ttt_unarmed"
UPGRADE.name = "Self-Pack-a-Punch"
UPGRADE.desc = "You pack-a-punched yourself!\nSpeed, jump and health boost!"

UPGRADE.convars = {
    {
        name = "pap_self_pack_a_punch_speed",
        type = "float",
        decimals = 1
    },
    {
        name = "pap_self_pack_a_punch_jump",
        type = "float",
        decimals = 1
    },
    {
        name = "pap_self_pack_a_punch_health",
        type = "float",
        decimals = 1
    }
}

local speedMult = CreateConVar("pap_self_pack_a_punch_speed", "1.2", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Speed multiplier", 1, 5)

local jumpMult = CreateConVar("pap_self_pack_a_punch_jump", "1.5", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Jump height multiplier", 1, 5)

local healthMult = CreateConVar("pap_self_pack_a_punch_health", "1.2", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Health multiplier", 1, 5)

function UPGRADE:Apply(SWEP)
    local speedScale = speedMult:GetFloat()
    local jumpScale = jumpMult:GetFloat()
    local healthScale = healthMult:GetFloat()
    SWEP:SetHoldType(SWEP.HoldType)

    timer.Simple(0.1, function()
        -- Extra check just in case someone can get the split-second timing just right to smuggle the upgrade buffs into the next round
        if not IsValid(SWEP) or GetRoundState() == ROUND_PREP then return end
        local owner = SWEP:GetOwner()

        if self:IsPlayer(owner) then
            SWEP.HolsterPAPOwner = owner
            SWEP.PAPHolsterOldStats = {}
            SWEP.PAPHolsterOldStats.jump = owner:GetJumpPower()
            SWEP.PAPHolsterOldStats.health = owner:GetMaxHealth()
            SWEP.PAPHolsterOldStats.movement = owner:GetLaggedMovementValue()
            owner:SetPAPCamo()
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

        if IsValid(owner) then
            owner:SetMaterial("")

            if self.PAPHolsterOldStats then
                owner:SetJumpPower(self.PAPHolsterOldStats.jump or 200)
                owner:SetHealth(owner:Health() / owner:GetMaxHealth() * self.PAPHolsterOldStats.health or 100)
            end

            if SERVER then
                owner:ChatPrint("Your pack-a-punch buff has been removed")

                if self.PAPHolsterOldStats then
                    owner:SetMaxHealth(self.PAPHolsterOldStats.health or 100)
                    owner:SetLaggedMovementValue(self.PAPHolsterOldStats.movement or 1)
                end
            end
        end
    end

    function SWEP:ShouldDrawViewModel()
        return false
    end
end

function UPGRADE:Reset()
    if SERVER then
        for _, ply in ipairs(player.GetAll()) do
            local holstered = ply:GetWeapon("weapon_ttt_unarmed")

            if IsValid(holstered) and self:IsUpgraded(holstered) then
                holstered:Remove()
                ply:Give("weapon_ttt_unarmed")
            end
        end
    end
end

TTTPAP:Register(UPGRADE)