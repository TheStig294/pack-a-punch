local UPGRADE = {}
UPGRADE.id = "triple_hwapoon"
UPGRADE.class = "weapon_ttt_hwapoon"
UPGRADE.name = "Triple Poon"
UPGRADE.desc = "Throw 3 hwapoons at once!"

function UPGRADE:Apply(SWEP)
    self:SetClip(SWEP, 3)
    SWEP.Thrown = false

    if SERVER then
        function SWEP:CreateArrow(aType, owner)
            if not IsValid(owner) then
                owner = self:GetOwner()
            end

            if not IsValid(owner) or not IsValid(self) then return end
            local ent = ents.Create("hwapoon_arrow")
            if not IsValid(ent) then return end
            ent.Owner = owner
            ent.Arrowtype = aType
            ent.Inflictor = self
            ent:SetOwner(owner)
            local eyeang = owner:GetAimVector():Angle()
            local right = eyeang:Right()
            local up = eyeang:Up()
            local posOffset = 9 - self:Clip1() * 9
            ent:SetPos(owner:GetShootPos() + right * posOffset - up * 3)
            ent:SetAngles(owner:GetAngles())
            ent:SetPhysicsAttacker(owner)
            ent:SetPAPCamo()
            ent:Spawn()
            local phys = ent:GetPhysicsObject()

            if IsValid(phys) then
                local fanDegrees = 8
                local aimOffset = fanDegrees - self:Clip1() * fanDegrees
                local aimVector = owner:GetAimVector()
                aimVector:Rotate(Angle(0, aimOffset, 0))
                phys:SetVelocity(aimVector * 1750)
            end
        end

        function SWEP:ThrowTripleHarpoonShot(owner)
            if not IsValid(owner) then return end
            self:TakePrimaryAmmo(1)
            self:CreateArrow("normal", owner, self)
            self:SendWeaponAnim(ACT_VM_DRAW)
            owner:EmitSound("weapons/crossbow/bolt_fly4.wav", 100, 100)
            owner:EmitSound("hwapoon" .. math.random(5) .. ".wav", 100, 100)
            owner:ViewPunch(Angle(math.Rand(-0.2, -0.1) * 10, math.Rand(-0.1, 0.1) * 10, 0))

            if self:Clip1() <= 0 then
                self:Remove()
            end
        end

        function SWEP:PrimaryAttack()
            if self.Thrown then return end
            self.Thrown = true
            local owner = self:GetOwner()
            self:ThrowTripleHarpoonShot(owner)

            timer.Create("PAPHarpoonThrow" .. self:EntIndex(), 0.1, self:Clip1(), function()
                self:ThrowTripleHarpoonShot(owner)
            end)
        end
    end
end

TTTPAP:Register(UPGRADE)