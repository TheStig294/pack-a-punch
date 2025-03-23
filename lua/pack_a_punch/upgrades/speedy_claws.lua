local UPGRADE = {}
UPGRADE.id = "speedy_claws"
UPGRADE.class = "weapon_kra_carry"
UPGRADE.name = "Speedy Claws"
UPGRADE.desc = "Move much faster!"

UPGRADE.convars = {
    {
        name = "pap_speedy_claws_mult",
        type = "int"
    }
}

local speedMultCvar = CreateConVar("pap_speedy_claws_mult", "2", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Speed multiplier", 1, 5)

function UPGRADE:Apply(SWEP)
    if CLIENT then return end
    local owner = SWEP:GetOwner()

    -- Apply speed boost
    if IsValid(owner) then
        SWEP.PAPOldLaggedMovementValue = owner:GetLaggedMovementValue()
        owner:SetLaggedMovementValue(SWEP.PAPOldLaggedMovementValue * speedMultCvar:GetInt())
    end

    -- Remove on removing the weapon
    SWEP.PAPOldOnRemove = SWEP.OnRemove

    function SWEP:OnRemove()
        SWEP:PAPOldOnRemove()
        owner:SetLaggedMovementValue(SWEP.PAPOldLaggedMovementValue)
    end

    -- Remove on swapping to another weapon
    SWEP.PAPOldHolster = SWEP.Holster

    function SWEP:Holster()
        owner:SetLaggedMovementValue(SWEP.PAPOldLaggedMovementValue)

        return SWEP:PAPOldHolster()
    end

    -- Apply on bringing out the weapon again
    SWEP.PAPOldDeploy = SWEP.Deploy

    function SWEP:Deploy()
        owner:SetLaggedMovementValue(SWEP.PAPOldLaggedMovementValue * speedMultCvar:GetInt())

        return SWEP:PAPOldDeploy()
    end
end

TTTPAP:Register(UPGRADE)