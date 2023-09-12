ENT.Type = "anim"
ENT.Base = "ttt_shark_trap"
ENT.PrintName = "Left Shark Trap"

function ENT:Touch(toucher)
    if not IsValid(toucher) or not IsValid(self) or not toucher:IsPlayer() then return end
    toucher:Freeze(true)
    self:Remove()
    self:EmitSound("shark_trap.mp3", 100, 100, 1)

    timer.Simple(1.6, function()
        local effectData = EffectData()
        effectData:SetOrigin(toucher:GetPos())
        effectData:SetScale(20)
        effectData:SetMagnitude(20)
        util.Effect("watersplash", effectData)
        local shark = ents.Create("ttt_pap_left_shark_ent")
        shark:SetPos(toucher:GetPos() + Vector(0, 0, -75))
        shark:SetAngles(Angle(90, 0, 0))
        shark:SetLocalVelocity(Vector(0, 0, 200))
        shark:Spawn()

        timer.Simple(0.5, function()
            shark:SetLocalVelocity(Vector(0, 0, -300))
        end)

        --- Dmg Info ---
        local dmg = DamageInfo()
        local inflictor = ents.Create("ttt_pap_left_shark_trap")
        dmg:SetAttacker(toucher)
        dmg:SetInflictor(inflictor)
        dmg:SetDamage(100)
        dmg:SetDamageType(DMG_CLUB)
        ------
        toucher:TakeDamageInfo(dmg)
        toucher:Freeze(false)

        timer.Simple(2.5, function()
            shark:Remove()
        end)
    end)
end