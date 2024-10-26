local UPGRADE = {}
UPGRADE.id = "fireball"
UPGRADE.class = "weapon_snowball"
UPGRADE.name = "Fireball"
UPGRADE.desc = "A flaming explosive fireball!"

function UPGRADE:Apply(SWEP)
    SWEP.NoPlayerSlowdown = true

    if SERVER then
        function SWEP:EventThrow(strength, spread)
            local owner = self:GetOwner()
            if not IsValid(owner) then return end
            local snowball = ents.Create("snowball")
            if not IsValid(snowball) then return end
            local aimvec = owner:GetAimVector()
            local pos = aimvec * 12
            pos:Add(owner:EyePos())
            snowball:SetPos(pos)
            snowball:SetAngles(owner:EyeAngles())
            snowball:Spawn()
            snowball:SetOwner(owner)
            local phys = snowball:GetPhysicsObject()

            if not phys:IsValid() then
                snowball:Remove()

                return
            end

            local vel = owner:GetVelocity()
            local dir = owner:GetForward() * (strength + 500)
            local sp = spread

            if sp < 2 then
                sp = 0
            else
                sp = math.random(-spread, spread)
            end

            phys:SetVelocity(dir + (vel / 2) + Vector(sp, sp, 0))
            snowball:SetPAPCamo()
            snowball:Ignite(40)

            snowball:CallOnRemove("TTTPAPFireballExplosion", function(ent)
                local tr = util.QuickTrace(snowball:GetPos(), Vector(0, 0, -1))
                local hitPos = tr.HitPos

                if IsValid(tr.Entity) then
                    hitPos = tr.Entity:GetPos()
                end

                if SERVER then
                    local fireNade = ents.Create("ttt_firegrenade_proj")
                    fireNade:SetPos(hitPos)
                    fireNade:Spawn()
                    fireNade:SetDmg(15)
                    fireNade:SetThrower(snowball:GetOwner())
                    fireNade:Explode(tr)
                end
            end)
        end
    end
end

TTTPAP:Register(UPGRADE)