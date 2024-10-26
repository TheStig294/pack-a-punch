local UPGRADE = {}
UPGRADE.id = "guaranteed_ball"
UPGRADE.class = "weapon_ttt_detectiveball"
UPGRADE.name = "Guaranteed Ball"
UPGRADE.desc = "Comes back to you if you miss,\nworks regardless of a player's role!"

function UPGRADE:Apply(SWEP)
    function SWEP:Throw()
        if not SERVER then return end
        self:ShootEffects()
        self.BaseClass.ShootEffects(self)
        self:SendWeaponAnim(ACT_VM_THROW)
        self.CanFire = false
        local ent = ents.Create("ttt_pap_detectiveball")

        timer.Create("BBFireTimer", 1, 1, function()
            self.CanFire = true
            self:SendWeaponAnim(ACT_VM_DRAW)
            self:Remove()
        end)

        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        ent:SetPos(owner:EyePos() + (owner:GetAimVector() * 16))
        ent:SetAngles(owner:EyeAngles())
        ent:Spawn()
        ent.PAPOwner = owner
        ent.PAPUpgrade = UPGRADE
        ent:SetPAPCamo()
        local phys = ent:GetPhysicsObject()

        if not (phys and IsValid(phys)) then
            ent:Remove()

            return
        end

        phys:ApplyForceCenter(owner:GetAimVector():GetNormalized() * 1300)
    end
end

TTTPAP:Register(UPGRADE)