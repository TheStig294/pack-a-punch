local UPGRADE = {}
UPGRADE.id = "insurance_detonator"
UPGRADE.class = "weapon_ttt_randomatdetonator"
UPGRADE.name = "Insurance Detonator"
UPGRADE.desc = "Detonates the player who has your detonator!"

function UPGRADE:Apply(SWEP)
    if CLIENT then return end
    local owner = SWEP:GetOwner()
    if not IsValid(owner) then return end

    for _, ply in player.Iterator() do
        if not self:IsAlive(ply) then continue end
        local det = ply:GetWeapon("weapon_ttt_randomatdetonator")

        if IsValid(det) and det.Target == owner then
            SWEP.Target = ply
            break
        end
    end

    -- If no-one has your detonator, you just blow yourself up lol
    if not IsValid(SWEP.Target) then
        -- I mean... you have the detonator for the player who has your detonator... yourself!
        SWEP.Target = owner
    end
end

TTTPAP:Register(UPGRADE)