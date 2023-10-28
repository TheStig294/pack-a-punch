local UPGRADE = {}
UPGRADE.id = "slowgun"
UPGRADE.class = "speedgun"
UPGRADE.name = "Slowgun"
UPGRADE.desc = "x1.5 ammo, permenantely slows players instead!"
UPGRADE.ammoMult = 1.5

function UPGRADE:Apply(SWEP)
    function SWEP:ShootBullet(damage, num_bullets, aimcone)
        local owner = self:GetOwner()
        local bullet = {}
        bullet.Num = num_bullets
        bullet.Src = owner:GetShootPos()
        bullet.Dir = owner:GetAimVector()
        bullet.Spread = Vector(0, 0, 0)
        bullet.Tracer = 1
        bullet.TracerName = "ToolTracer"
        bullet.Force = 1
        bullet.Damage = 2
        bullet.AmmoType = "Pistol"

        bullet.Callback = function(attacker, tr, dmginfo)
            local ply = tr.Entity

            if SERVER and UPGRADE:IsPlayer(ply) then
                ply:ChatPrint("You've been slowed by an upgraded speedgun!")
                ply:SetLaggedMovementValue(ply:GetLaggedMovementValue() * 0.5)
            end
        end

        owner:FireBullets(bullet)
        self:ShootEffects()
    end
end

TTTPAP:Register(UPGRADE)