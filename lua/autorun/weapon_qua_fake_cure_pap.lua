TTT_PAP_UPGRADES = TTT_PAP_UPGRADES or {}

TTT_PAP_UPGRADES.weapon_qua_fake_cure = {
    name = "Parasite Cure",
    desc = "\"Cures\" a player of a parasite, by exploding them after 5 seconds!",
    noCamo = true,
    func = function(SWEP)
        local msg = "That's one way to cure the parasite..."
        local warningSound = Sound("items/medcharge4.wav")

        function SWEP:OnSuccess(ply, body)
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
}