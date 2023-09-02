local UPGRADE = {}
UPGRADE.id = "flinging_spin_attack"
UPGRADE.class = "weapon_ttt_whoa_randomat"
UPGRADE.name = "Flinging Spin Attack"
UPGRADE.desc = "Spun players get flung away!"

function UPGRADE:Apply(SWEP)
    local flingSound = Sound("ttt_pack_a_punch/flinging_spin_attack/fling.mp3")
    local flingSpeed = 10000

    self:AddHook("EntityTakeDamage", function(ply, dmg)
        if not IsValid(ply) or not ply:IsPlayer() then return end
        local attacker = dmg:GetAttacker()
        if not IsValid(attacker) or not attacker:IsPlayer() then return end
        local inflictor = dmg:GetInflictor()
        if not IsValid(inflictor) or inflictor:GetClass() ~= self.class or not inflictor.PAPUpgrade then return end
        -- Only fling when the player is about to die
        if ply:Health() > 10 then return end

        if IsValid(attacker) then
            ply:EmitSound(flingSound)
            -- Use vector subtraction to get the direction vector to know which way to fling the player
            local attackerPos = attacker:GetPos()
            local plyPos = ply:GetPos()
            local flingDirection = attackerPos - plyPos
            flingDirection:Normalize()
            flingDirection:Mul(flingSpeed)
            flingDirection.z = flingSpeed
            ply:SetVelocity(flingDirection)
        end
    end)
end

TTTPAP:Register(UPGRADE)