local UPGRADE = {}
UPGRADE.id = "explosive_parasite_cure"
UPGRADE.class = "weapon_qua_fake_cure"
UPGRADE.name = "Parasite Cure"
UPGRADE.desc = "\"Cures\" a player of a parasite,\nby exploding them after 5 seconds!"

function UPGRADE:Apply(SWEP)
    local msg = "That's one way to cure the parasite..."
    local warningSound = Sound("items/medcharge4.wav")

    function SWEP:OnSuccess(ply, _)
        ply:ChatPrint(msg)

        for _, v in pairs(player.GetAll()) do
            if v:GetNWString("ParasiteInfectingTarget", "") == ply:SteamID64() then
                v:ChatPrint(msg)
            end
        end

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
            util.BlastDamage(ply, attacker, pos, radius, damage)
            local effect = EffectData()
            effect:SetStart(pos)
            effect:SetOrigin(pos)
            effect:SetScale(radius)
            effect:SetRadius(radius)
            effect:SetMagnitude(damage)
            util.Effect("Explosion", effect, true, true)
            sound.Play(explodesound, ply:GetPos(), 60, 150)
        end)
    end
end

TTTPAP:Register(UPGRADE)