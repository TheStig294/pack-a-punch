local UPGRADE = {}
UPGRADE.id = "remote_thruster"
UPGRADE.class = "weapon_ttt_rocket_thruster"
UPGRADE.name = "Remote Thruster"
UPGRADE.desc = "Launches other players instead!"

function UPGRADE:Apply(SWEP)
    function SWEP:RocketJump()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        self:EmitSound(self.ShootSound)
        self:ShootEffects()
        self:TakePrimaryAmmo(1)
        local TraceResult = owner:GetEyeTrace()
        local ent = TraceResult.Entity

        if IsValid(ent) then
            ent:EmitSound(self.ShootSound)
            ent:SetGroundEntity(NULL)
            ent:SetVelocity(Vector(0, 0, 500))
        else
            self:ShootBullet(0, 1, 0, self.Primary.Ammo, 0, 1)
        end
    end
end

TTTPAP:Register(UPGRADE)