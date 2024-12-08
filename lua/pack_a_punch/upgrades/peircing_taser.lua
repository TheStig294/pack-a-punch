local UPGRADE = {}
UPGRADE.id = "peircing_taser"
UPGRADE.class = "weapon_taser_derens"
UPGRADE.name = "Peircing Taser"
UPGRADE.desc = "Can peirce through players!"

function UPGRADE:Apply(SWEP)
    if CLIENT then return end
    local taserRange = 300
    local attackWidth = 10

    self:AddToHook(SWEP, "PrimaryAttack", function()
        local owner = SWEP:GetOwner()

        -- For some reason a regular util.TraceLine() just wouldn't filter non-player entities
        -- even though I was using MASK_NPCWORLDSTATIC, it was still acting like I was using MASK_SHOT (default)...
        -- This does mean that the taser now is an AOE, but ¯\_(ツ)_/¯ it's small enough it's basically like a bit of lag compensation anyway
        local tr = util.TraceHull({
            start = owner:GetShootPos(),
            endpos = owner:GetShootPos() + (owner:GetAimVector() * taserRange),
            filter = owner,
            mins = Vector(-attackWidth, -attackWidth, -attackWidth),
            maxs = Vector(attackWidth, attackWidth, attackWidth),
            mask = MASK_NPCWORLDSTATIC
        })

        -- Use the exact same damage object values as the base weapon uses
        local dmg = DamageInfo()
        dmg:SetAttacker(owner)
        dmg:SetDamage(SWEP.Primary.Damage)
        dmg:SetDamageType(DMG_BULLET)
        dmg:SetDamageForce(owner:EyeAngles():Forward() * 1)
        dmg:SetInflictor(SWEP)

        for _, ent in ipairs(ents.FindAlongRay(tr.StartPos, tr.HitPos)) do
            if not IsPlayer(ent) or ent == owner then continue end
            ent:TakeDamageInfo(dmg)
        end
    end)
end

TTTPAP:Register(UPGRADE)