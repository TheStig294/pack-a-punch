AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "ttt_shark_trap"
ENT.PrintName = "Left Shark Trap"

-- Code from the shark trap SWEP and cleaned up
-- https://steamcommunity.com/sharedfiles/filedetails/?id=2550782000
function ENT:Touch(toucher)
    if not IsValid(toucher) or not IsValid(self) or not toucher:IsPlayer() then return end
    toucher:Freeze(true)
    self:Remove()
    toucher:EmitSound("shark_trap.mp3", 100, 100, 1)
    local attacker = self.Owner

    timer.Simple(1.6, function()
        toucher:StopSound("shark_trap.mp3")
        toucher:EmitSound("ttt_pack_a_punch/left_shark_trap/blegh.mp3", 100, 100, 1)
        local effectData = EffectData()
        effectData:SetOrigin(toucher:GetPos())
        effectData:SetScale(10)
        effectData:SetMagnitude(10)
        util.Effect("watersplash", effectData)
        local shark = ents.Create("ttt_pap_left_shark_ent")
        shark:SetPos(toucher:GetPos() + Vector(0, 0, -75))
        shark:SetAngles(toucher:GetAngles())
        shark:SetLocalVelocity(Vector(0, 0, 200))
        shark:Spawn()

        timer.Simple(0.5, function()
            shark:SetLocalVelocity(Vector(0, 0, -300))
        end)

        --- Dmg Info ---
        local dmg = DamageInfo()
        local inflictor = ents.Create("ttt_pap_left_shark_trap")
        dmg:SetAttacker(attacker)
        dmg:SetInflictor(inflictor)
        dmg:SetDamage(100)
        dmg:SetDamageType(DMG_DROWN)
        ------
        toucher:TakeDamageInfo(dmg)
        toucher:Freeze(false)

        timer.Simple(2.5, function()
            shark:Remove()
        end)
    end)
end