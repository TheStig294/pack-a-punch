local UPGRADE = {}
UPGRADE.id = "fast_bike"
UPGRADE.class = "weapon_ttt_bike"
UPGRADE.name = "Fast Bike"
UPGRADE.desc = "Move fast while riding!"

UPGRADE.convars = {
    {
        name = "pap_fast_bike_speed_mult",
        type = "int"
    }
}

local speedMultCvar = CreateConVar("pap_fast_bike_speed_mult", "2", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Speed multiplier", 1, 5)

function UPGRADE:Apply(SWEP)
    if CLIENT then return end

    -- Applying the camo to the thrown bike entity
    function SWEP:PrimaryAttack()
        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
        self:EmitSound("weapons/traitor_bike/bike_bell.wav")
        self:SendWeaponAnim(ACT_VM_MISSCENTER)

        if SERVER then
            local ply = self:GetOwner()
            if not IsValid(ply) then return end
            ply:SetAnimation(PLAYER_ATTACK1)
            local ang = ply:EyeAngles()

            if ang.p < 90 then
                ang.p = -10 + ang.p * ((90 + 10) / 90)
            else
                ang.p = 360 - ang.p
                ang.p = -10 + ang.p * -((90 + 10) / 90)
            end

            local vel = math.Clamp((90 - ang.p) * 5.5, 550, 800)
            local vfw = ang:Forward()
            local vrt = ang:Right()
            local src = ply:GetPos() + (ply:Crouching() and ply:GetViewOffsetDucked() or ply:GetViewOffset())
            src = src + (vfw * 1) + (vrt * 3)
            local thr = (vfw * vel + ply:GetVelocity()) * 5
            local bike_ang = Angle(-28, 0, 0) + ang
            bike_ang:RotateAroundAxis(bike_ang:Right(), -90)
            local bike = ents.Create("ttt_bike_proj")
            if not IsValid(bike) then return end
            bike:SetPos(src)
            bike:SetAngles(bike_ang)
            bike:Spawn()
            bike.Damage = self.Primary.Damage
            bike:SetOwner(ply)
            bike:SetPAPCamo()
            local phys = bike:GetPhysicsObject()

            if IsValid(phys) then
                phys:SetVelocity(thr)
                phys:AddAngleVelocity(Vector(0, 1500, 0))
                phys:Wake()
            end

            self:Remove()
        end
    end

    -- Playing the bike music and giving the player a speed boost
    function SWEP:ApplyBoost()
        local owner = self:GetOwner()

        if IsValid(owner) then
            self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
            self.PAPFastBikeOldSpeed = owner:GetLaggedMovementValue()
            owner:SetLaggedMovementValue(self.PAPFastBikeOldSpeed * speedMultCvar:GetInt())
        end
    end

    -- Removing the music and speed boost
    function SWEP:RemoveBoost()
        local owner = self:GetOwner()

        if IsValid(owner) then
            owner:SetLaggedMovementValue(self.PAPFastBikeOldSpeed)
        end
    end

    -- Apply on receiving the weapon
    SWEP:ApplyBoost()
    -- Remove on removing the weapon
    SWEP.PAPOldOnRemove = SWEP.OnRemove

    function SWEP:OnRemove()
        self:RemoveBoost()

        return self:PAPOldOnRemove()
    end

    -- Remove on swapping to another weapon
    SWEP.PAPOldHolster = SWEP.Holster

    function SWEP:Holster()
        self:RemoveBoost()

        return self:PAPOldHolster()
    end

    -- Apply on bringing out the weapon again
    SWEP.PAPOldDeploy = SWEP.Deploy

    function SWEP:Deploy()
        self:ApplyBoost()

        return self:PAPOldDeploy()
    end
end

TTTPAP:Register(UPGRADE)