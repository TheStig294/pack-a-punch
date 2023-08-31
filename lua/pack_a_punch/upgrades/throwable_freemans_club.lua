local UPGRADE = {}
UPGRADE.id = "throwable_freemans_club"
UPGRADE.class = "weapon_kil_crowbar"
UPGRADE.name = "Throwable Freeman's Club"
UPGRADE.desc = "x2 swing speed, first throw kills in 1-shot,\nthen reverts to an ordinary killer crowbar"
UPGRADE.firerateMult = 2

function UPGRADE:Apply(SWEP)
    function SWEP:Throw()
        if not SERVER then return end
        self:ShootEffects()
        self.BaseClass.ShootEffects(self)
        self:SendWeaponAnim(ACT_VM_THROW)
        self.CanFire = false
        local ent = ents.Create("ttt_kil_crowbar")
        ent:SetDamage(10000)
        ent:SetMaterial(TTTPAP.camo)
        local owner = self:GetOwner()
        ent:SetOwner(owner)
        ent:SetPos(owner:EyePos() + owner:GetAimVector() * 16)
        ent:SetAngles(owner:EyeAngles())
        ent:Spawn()
        local phys = ent:GetPhysicsObject()
        phys:ApplyForceCenter(owner:GetAimVector():GetNormalized() * 1300)
        self:Remove()
    end
end

TTTPAP:Register(UPGRADE)