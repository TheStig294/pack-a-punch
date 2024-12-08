local UPGRADE = {}
UPGRADE.id = "explosive_cure"
UPGRADE.class = "weapon_qua_fake_cure"
UPGRADE.name = "Explosive Cure"
UPGRADE.desc = "\"Cures\" a player... by exploding them after 5 seconds!"

function UPGRADE:Apply(SWEP)
    local warningSound = Sound("items/medcharge4.wav")

    function SWEP:OnSuccess(ply, _)
        ply:EmitSound(warningSound)
        local owner = self:GetOwner()

        timer.Simple(5, function()
            if not IsValid(ply) then return end
            ply:StopSound(warningSound)
            local explodesound = Sound("c4.explode")
            local pos = ply:GetPos()
            local radius = 400
            local damage = 1000
            local attacker = owner or ply
            util.BlastDamage(ents.Create(UPGRADE.class), attacker, pos, radius, damage)
            local effect = EffectData()
            effect:SetStart(pos)
            effect:SetOrigin(pos)
            effect:SetScale(radius)
            effect:SetRadius(radius)
            effect:SetMagnitude(damage)
            util.Effect("Explosion", effect, true, true)
            sound.Play(explodesound, ply:GetPos(), 60, 150)
            ply:ChatPrint("You just got 'cured'...")

            if IsValid(owner) then
                owner:ChatPrint("That's one way to cure someone...")
            end
        end)
    end
end

TTTPAP:Register(UPGRADE)