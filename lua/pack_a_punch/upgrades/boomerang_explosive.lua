local UPGRADE = {}
UPGRADE.id = "boomerang_explosive"
UPGRADE.class = "weapon_ttt_boomerang"
UPGRADE.name = "Explosive Boomerang"
UPGRADE.desc = "Boomerang explodes on touch!"
UPGRADE.noCamo = true

function UPGRADE:Apply(SWEP)
    if CLIENT and SWEP.VElements and SWEP.WElements then
        SWEP.VElements.boomerang.material = TTTPAP.camo
        SWEP.WElements.boomerang.material = TTTPAP.camo
    end

    timer.Simple(0.1, function()
        SWEP:SetClip1(-1)
    end)

    -- Return-throw only, one-shot non-return throw is overriden by this
    function SWEP:PrimaryAttack()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
        local Pos = owner:GetShootPos()
        local trace = owner:GetEyeTrace()
        local targetPos = trace.HitPos

        if trace.HitWorld and Pos:Distance(targetPos) < 2000 then
            targetPos = targetPos - (Pos - targetPos):GetNormalized() * 10
        else
            targetPos = Pos + owner:GetAimVector() * 2000
        end

        targetPos = Pos + owner:GetAimVector() * 2000
        self:EmitSound("weapons/slam/throw.wav")

        if SERVER then
            local boomerang = ents.Create("ttt_pap_boomerang_explosive")
            boomerang:SetAngles(Angle(20, 0, 90))
            boomerang:SetPos(owner:GetShootPos())
            boomerang:SetOwner(owner)
            boomerang:SetPhysicsAttacker(owner, 10)
            boomerang:SetNWVector("targetPos", targetPos)
            boomerang:Spawn()
            boomerang:Activate()
            boomerang.Hits = self.Hits
            boomerang.LastVelocity = owner:GetAimVector()
            boomerang.Damage = self.Primary.Damage
            boomerang.PAPUpgrade = UPGRADE
            print(boomerang.PAPUpgrade.id, "aaaaaaaaaaaaaa")
            local phys = boomerang:GetPhysicsObject()
            phys:SetVelocity(owner:GetAimVector():GetNormalized() * 10)
            phys:AddAngleVelocity(Vector(0, -10, 0))
            self:Remove()
        end
    end

    -- Normal return throw is disabled
    function SWEP:SecondaryAttack()
    end
end

TTTPAP:Register(UPGRADE)