local UPGRADE = {}
UPGRADE.id = "spacetime_gun"
UPGRADE.class = "weapon_ttt_gravity_pistol"
UPGRADE.name = "Spacetime Gun"
UPGRADE.desc = "Continually changes the victim's gravity!"

function UPGRADE:Apply(SWEP)
    function SWEP:PrimaryAttack()
        if not self:CanPrimaryAttack() then return end
        local owner = self:GetOwner()
        local cone = self.Primary.Cone
        local num = 1
        local bullet = {}
        bullet.Num = num
        bullet.Src = owner:GetShootPos()
        bullet.Dir = owner:GetAimVector()
        bullet.Spread = Vector(cone, cone, 0)
        bullet.Tracer = 1
        bullet.Force = 5
        bullet.Damage = 0
        bullet.TracerName = "AirboatGunHeavyTracer"

        bullet.Callback = function(attacker, tr, dmg)
            local victim = tr.Entity
            if not UPGRADE:IsAlivePlayer(victim) then return end
            local pos = victim:GetPos()
            local effectData = EffectData()
            effectData:SetOrigin(pos)
            effectData:SetStart(pos)
            util.Effect("bloodspray", effectData, true, true)
            victim:SetGravity(-0.5)
            victim:SetPos(victim:GetPos() + Vector(0, 0, 1))
            if CLIENT then return end
            local timerName = "TTTPAPSpaceTimeGun" .. victim:SteamID64()

            local gravityValues = {-1, -0.3, 0.3, 2}

            timer.Create(timerName, 3, 0, function()
                if not IsValid(victim) or GetRoundState() ~= ROUND_ACTIVE or not UPGRADE:IsAlive(victim) then
                    timer.Remove(timerName)

                    if IsValid(victim) then
                        victim:SetGravity(1)
                    end

                    return
                end

                local randomGravity = gravityValues[math.random(#gravityValues)]
                victim:SetGravity(randomGravity)
                victim:SetGroundEntity(NULL)
            end)
        end

        owner:FireBullets(bullet)
        self:ShootEffects()

        return self.BaseClass.PrimaryAttack(self)
    end
end

TTTPAP:Register(UPGRADE)