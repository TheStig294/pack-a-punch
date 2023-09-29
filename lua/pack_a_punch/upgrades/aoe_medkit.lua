local UPGRADE = {}
UPGRADE.id = "aoe_medkit"
UPGRADE.class = "weapon_ttt_medkit"
UPGRADE.name = "AOE Medkit"
UPGRADE.desc = "Heals you more at once, and other players around you!"

UPGRADE.convars = {
    {
        name = "pap_aoe_medkit_heal_mult",
        type = "float",
        decimals = 1
    }
}

local healMultCvar = CreateConVar("pap_aoe_medkit_heal_mult", 1.5, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Extra healing mutiplier", 0.1, 10)

UPGRADE.ammoMult = healMultCvar:GetFloat()

function UPGRADE:Apply(SWEP)
    SWEP.HealAmount = SWEP.HealAmount * healMultCvar:GetFloat()
    SWEP.MaxAmmo = SWEP.MaxAmmo * healMultCvar:GetFloat()

    function SWEP:SecondaryAttack()
        if CLIENT then return end
        local owner = self:GetOwner()

        for _, ply in ipairs(ents.FindInSphere(self:GetPos(), 200)) do
            if not UPGRADE:IsPlayer(ply) then continue end
            self.PAPTakeAmmo = true

            if self:Clip1() >= self.HealAmount and ply:Health() < ply:GetMaxHealth() then
                if self.PAPTakeAmmo then
                    self:TakePrimaryAmmo(self.HealAmount)
                end

                self.PAPTakeAmmo = false
                self.HealAmount = math.min(ply:GetMaxHealth() - ply:Health(), self.HealAmount)
                ply:SetHealth(math.min(ply:GetMaxHealth(), ply:Health() + self.HealAmount))
                ply:EmitSound("items/smallmedkit1.wav")
                self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
                self:SetNextSecondaryFire(CurTime() + self:SequenceDuration() + 0.5)
                owner:SetAnimation(PLAYER_ATTACK1)

                timer.Create("weapon_idle" .. self:EntIndex(), self:SequenceDuration(), 1, function()
                    if IsValid(self) then
                        self:SendWeaponAnim(ACT_VM_IDLE)
                    end
                end)
            else
                owner:EmitSound("items/medshotno1.wav")
                self:SetNextSecondaryFire(CurTime() + 1)
            end
        end
    end
end

TTTPAP:Register(UPGRADE)