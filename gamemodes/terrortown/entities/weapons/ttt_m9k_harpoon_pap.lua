AddCSLuaFile()
SWEP.Base = "ttt_m9k_harpoon"
SWEP.CanBuy = {}
SWEP.Primary.ClipSize = 3
SWEP.Primary.ClipMax = 3
SWEP.Primary.DefaultClip = 3
SWEP.Thrown = false
SWEP.PAPNoCamo = true
SWEP.PAPDesc = "Throw 3 harpoons at once!"
SWEP.PrintName = "Triple Poon"

function SWEP:Initialize()
    self.BaseClass.Initialize(self)

    timer.Simple(0.1, function()
        self:SetClip1(3)
    end)

    if CLIENT then
        self.VElements.harpoon.material = TTTPAP.camo
        self.WElements.WHarpoon.material = TTTPAP.camo
    end
end

if SERVER then
    function SWEP:CreateArrow(aType, owner)
        if not IsValid(owner) then
            owner = self:GetOwner()
        end

        if not IsValid(owner) or not IsValid(self) then return end
        local ent = ents.Create("m9k_thrown_harpoon")
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
        ent:SetMaterial(TTTPAP.camo)
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

        timer.Create("PAPHarpoonThrow", 0.1, self:Clip1(), function()
            self:ThrowTripleHarpoonShot(owner)
        end)
    end
end