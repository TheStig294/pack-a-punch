local UPGRADE = {}
UPGRADE.id = "ranged_cure"
UPGRADE.class = "weapon_doc_cure"
UPGRADE.name = "Ranged Cure"
UPGRADE.desc = "Unlimited uses, works from far away!"

function UPGRADE:Apply(SWEP)
    SWEP.SingleUse = false

    function SWEP:GetTarget(primary)
        local owner = self:GetOwner()

        if primary then
            local tr = owner:GetEyeTrace()
            local target = tr.Entity

            if IsValid(target) then
                target:EmitSound("items/nvg_on.wav", 75, math.random(98, 102), 1)

                if not target.TTTPAPRangedCure then
                    target:PrintMessage(HUD_PRINTCENTER, "You are being cured!")
                    target:PrintMessage(HUD_PRINTTALK, "You are being cured!")
                    target.TTTPAPRangedCure = true
                end
            end

            return target, tr.PhysicsBone
        end

        return owner, nil
    end
end

function UPGRADE:Reset()
    for _, ply in player.Iterator() do
        ply.TTTPAPRangedCure = nil
    end
end

TTTPAP:Register(UPGRADE)