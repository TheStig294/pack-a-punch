local UPGRADE = {}
UPGRADE.id = "banana_bus"
UPGRADE.class = "weapon_banana"
UPGRADE.name = "Banana Bus"
UPGRADE.desc = "Spawns a deadly bus where it explodes,\ndriving around killing any player it touches"

function UPGRADE:Apply(SWEP)
    function SWEP:PrimaryAttack()
        if CLIENT then return end
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        local crate = ents.Create("ttt_pap_banana_bomb")
        if not IsValid(crate) then return end
        local aimVector = owner:GetAimVector()
        crate:SetPos(owner:GetShootPos() + aimVector * 30)
        crate:Spawn()
        crate:Activate()
        crate.PAPOwner = owner
        self:SendWeaponAnim(ACT_VM_THROW)
        local phys = crate:GetPhysicsObject()

        if IsValid(phys) then
            phys:ApplyForceCenter(owner:GetAimVector() * math.Rand(500, 800) * phys:GetMass() * 2)
        end

        self:Remove()
        owner:ConCommand("lastinv")
    end

    function SWEP:SecondaryAttack()
    end
end

TTTPAP:Register(UPGRADE)