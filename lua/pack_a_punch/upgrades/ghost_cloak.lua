local UPGRADE = {}
UPGRADE.id = "ghost_cloak"
UPGRADE.class = "weapon_ttt_cloak"
UPGRADE.name = "Ghost Cloak"
UPGRADE.desc = "Can walk through players and movable objects!"

function UPGRADE:Apply(SWEP)
    self:AddHook("ShouldCollide", function(ent1, ent2)
        if not ent1:IsWorld() and not ent2:IsWorld() and (ent1.PAPGhostCloakNoCollide or ent2.PAPGhostCloakNoCollide) then return false end
    end)

    local own = SWEP:GetOwner()

    if IsValid(own) then
        own:SetCustomCollisionCheck(true)
        own.PAPGhostCloakNoCollide = true
    end

    SWEP.PAPOldCloak = SWEP.Cloak

    function SWEP:Cloak()
        self:PAPOldCloak()
        local owner = self:GetOwner()

        if IsValid(owner) then
            owner.PAPGhostCloakNoCollide = true
        end
    end

    SWEP.PAPOldUnCloak = SWEP.UnCloak

    function SWEP:UnCloak()
        self:PAPOldUnCloak()
        local owner = self:GetOwner()

        if IsValid(owner) then
            owner.PAPGhostCloakNoCollide = false
        end
    end
end

function UPGRADE:Reset()
    for _, ply in ipairs(player.GetAll()) do
        ply.PAPGhostCloakNoCollide = nil
    end
end

TTTPAP:Register(UPGRADE)