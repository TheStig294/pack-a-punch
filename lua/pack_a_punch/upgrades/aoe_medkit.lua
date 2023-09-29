local UPGRADE = {}
UPGRADE.id = "aoe_medkit"
UPGRADE.class = "weapon_ttt_medkit"
UPGRADE.name = "AOE Medkit"
UPGRADE.desc = "Heals you more, and other players around you!"

function UPGRADE:Apply(SWEP)
    SWEP.HealAmount = SWEP.HealAmount * 2

    function SWEP:SecondaryAttack()
        if CLIENT then return end
        local owner = self:GetOwner()
        local need = self.HealAmount

        if IsValid(owner) and self:Clip1() >= need and owner:Health() < owner:GetMaxHealth() then
            self:TakePrimaryAmmo(need)

            for _, ply in ipairs(ents.FindInSphere(self:GetPos(), 200)) do
                if not UPGRADE:IsPlayer(ply) then continue end
                need = math.min(ply:GetMaxHealth() - ply:Health(), self.HealAmount)
                ply:SetHealth(math.min(ply:GetMaxHealth(), ply:Health() + need))
            end

            owner:EmitSound(HealSound)
            self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
            self:SetNextSecondaryFire(CurTime() + self:SequenceDuration() + 0.5)
            owner:SetAnimation(PLAYER_ATTACK1)

            timer.Create("weapon_idle" .. self:EntIndex(), self:SequenceDuration(), 1, function()
                if IsValid(self) then
                    self:SendWeaponAnim(ACT_VM_IDLE)
                end
            end)
        else
            owner:EmitSound(DenySound)
            self:SetNextSecondaryFire(CurTime() + 1)
        end
    end
end

TTTPAP:Register(UPGRADE)