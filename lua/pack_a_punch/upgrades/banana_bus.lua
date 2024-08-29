local UPGRADE = {}
UPGRADE.id = "banana_bus"
UPGRADE.class = "weapon_banana"
UPGRADE.name = "Banana Bus"
UPGRADE.desc = "Spawns a deadly bus where it explodes,\ndriving through walls, killing any player it touches"

UPGRADE.convars = {
    {
        name = "pap_banana_bus_speed",
        type = "float",
        decimals = 1
    }
}

function UPGRADE:Apply(SWEP)
    function SWEP:PrimaryAttack()
        if CLIENT then return end
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        local bananaBunch = ents.Create("ttt_pap_banana_bomb")
        if not IsValid(bananaBunch) then return end
        local aimVector = owner:GetAimVector()
        bananaBunch:SetPos(owner:GetShootPos() + aimVector * 30)
        bananaBunch.PAPOwner = owner
        bananaBunch:Spawn()
        bananaBunch:Activate()
        self:SendWeaponAnim(ACT_VM_THROW)
        local phys = bananaBunch:GetPhysicsObject()

        if IsValid(phys) then
            phys:ApplyForceCenter(owner:GetAimVector() * math.Rand(500, 800) * phys:GetMass() * 2)
        end

        self:Remove()
        owner:ConCommand("lastinv")
    end

    function SWEP:SecondaryAttack()
    end

    function SWEP:DrawHUD()
    end
end

TTTPAP:Register(UPGRADE)