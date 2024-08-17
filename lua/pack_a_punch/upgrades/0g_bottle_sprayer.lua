local UPGRADE = {}
UPGRADE.id = "0g_bottle_sprayer"
UPGRADE.class = "weapon_ttt_anthrax"
UPGRADE.name = "0G Bottle Sprayer"
UPGRADE.desc = "Traitors are immune, x2 bottles\nbottles and crate aren't affected by gravity"

function UPGRADE:Apply(SWEP)
    function SWEP:ThrowCrate(force)
        if CLIENT then return end
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        local crate = ents.Create("ttt_pap_anthrax")
        if not IsValid(crate) then return end
        local aimVector = owner:GetAimVector()
        crate:SetPos(owner:GetShootPos() + aimVector * 30)
        crate:Spawn()
        crate:Activate()
        crate.PAPOwner = owner
        self:SendWeaponAnim(ACT_VM_THROW)
        local phys = crate:GetPhysicsObject()

        if IsValid(phys) then
            phys:ApplyForceCenter(aimVector * phys:GetMass() * force)
        end

        self:Remove()
        owner:ConCommand("lastinv")
    end

    function SWEP:PrimaryAttack()
        self:ThrowCrate(1500)
    end

    function SWEP:SecondaryAttack()
        self:ThrowCrate(200)
    end
end

TTTPAP:Register(UPGRADE)