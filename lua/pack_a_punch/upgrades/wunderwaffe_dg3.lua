local UPGRADE = {}
UPGRADE.id = "wunderwaffe_dg3"
UPGRADE.class = "tfa_wunderwaffe"
UPGRADE.name = "Wunderwaffe DG-3"
UPGRADE.desc = "Arcs lightning between nearby players!"

UPGRADE.convars = {
    {
        name = "pap_wunderwaffe_dg3_arc_range",
        type = "int"
    }
}

local rangeCvar = CreateConVar("pap_wunderwaffe_dg3_arc_range", 150, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "AOE range of arc lightning", 1, 1000)

function UPGRADE:Apply(SWEP)
    -- Is a CoD weapon, so has its own PAP function we can take advantage of, this is not from this mod
    SWEP:OnPaP()
    SWEP.PAPOldPrimaryAttack = SWEP.PrimaryAttack
    local owner = SWEP:GetOwner()
    owner:SetAmmo(0, "CombineCannon")

    function SWEP:OwnerChanged()
        owner = self:GetOwner()
    end

    function SWEP:PrimaryAttack(old)
        self:PAPOldPrimaryAttack(old)
        local orb

        for _, ent in ipairs(ents.FindByClass("obj_wunderwaffe_proj")) do
            if ent.Owner == owner then
                orb = ent
                break
            end
        end

        if not IsValid(orb) then return end
        orb.Range = rangeCvar:GetInt()
        -- Distance is squared for cheap maths
        orb.Range = orb.Range * orb.Range

        function orb:FindNearestEntity(pos)
            local nearestPlayer
            local nearestDist

            for _, ply in pairs(player.GetAll()) do
                if UPGRADE:IsAlive(ply) and ply ~= self.Owner then
                    local newDist = ply:GetPos():DistToSqr(pos)

                    if newDist < self.Range and ((not nearestDist) or newDist < nearestDist) then
                        nearestPlayer = ply
                        nearestDist = ply:GetPos():DistToSqr(pos)
                    end
                end
            end

            return nearestPlayer
        end

        function orb:FindNearestEntityCheap(pos)
            return self:FindNearestEntity(pos)
        end
    end
end

TTTPAP:Register(UPGRADE)