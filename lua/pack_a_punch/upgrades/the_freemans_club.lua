local UPGRADE = {}
UPGRADE.id = "the_freemans_club"
UPGRADE.class = "weapon_zm_improvised"
UPGRADE.name = "The Freeman's Club"
UPGRADE.desc = "Zero push cooldown, x2 swing speed!"

function UPGRADE:Apply(SWEP)
    SWEP.Primary.Delay = 0.25
    SWEP.Secondary.Delay = 0.5
    local sound_single = Sound("Weapon_Crowbar.Single")

    function SWEP:SecondaryAttack()
        self:SetNextPrimaryFire(CurTime() + self.Secondary.Delay)
        self:SetNextSecondaryFire(CurTime() + 0.1)

        if self:GetOwner().LagCompensation then
            self:GetOwner():LagCompensation(true)
        end

        local tr = self:GetOwner():GetEyeTrace(MASK_SHOT)

        if tr.Hit and IsValid(tr.Entity) and tr.Entity:IsPlayer() and (self:GetOwner():EyePos() - tr.HitPos):Length() < 100 then
            local ply = tr.Entity

            if SERVER and not ply:IsFrozen() then
                local pushvel = tr.Normal * GetConVar("ttt_crowbar_pushforce"):GetFloat() * 8
                -- limit the upward force to prevent launching
                pushvel.z = math.Clamp(pushvel.z, 50, 100)
                ply:SetVelocity(ply:GetVelocity() + pushvel)
                self:GetOwner():SetAnimation(PLAYER_ATTACK1)

                ply.was_pushed = {
                    att = self:GetOwner(),
                    t = CurTime(),
                    wep = self:GetClass()
                }
            end

            self:EmitSound(sound_single)
            self:SendWeaponAnim(ACT_VM_HITCENTER)
            self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)
        end

        if self:GetOwner().LagCompensation then
            self:GetOwner():LagCompensation(false)
        end
    end
end

TTTPAP:Register(UPGRADE)