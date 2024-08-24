local UPGRADE = {}
UPGRADE.id = "bigulon"
UPGRADE.class = "weapon_dr2_remote"
UPGRADE.name = "Bigulon"
UPGRADE.desc = "Fires manhacks instead of missiles"

function UPGRADE:Apply(SWEP)
    function SWEP:SetGunThink(drone)
        if not IsValid(drone.gun) then return end

        drone.gun._Think = function()
            local user = drone:GetDriver()

            if not drone:IsDroneDestroyed() and drone:HasFuel() and user:IsValid() then
                local viewdir = Angle(user:EyeAngles().p < -20 and -20 or user:EyeAngles().p, user:EyeAngles().y, 0) --bookmark

                if not user:GetNWBool("dronejaschamovement", false) then
                    viewdir = viewdir + drone:GetAngles()
                end

                if user:KeyDown(IN_ATTACK) and drone:HasAmmo() and CurTime() > drone.nextshoot then
                    drone.gun:EmitSound("Weapon_RPG.Single")

                    if SERVER then
                        local manhack = ents.Create("npc_manhack")
                        manhack:SetPos(drone:GetPos() - drone:GetUp() * drone.cam_up + drone.gun:GetForward() * 4)
                        manhack.originalplayer = user
                        manhack.FlyAngle = viewdir
                        manhack:Spawn()
                        manhack:SetAngles(viewdir)
                        manhack:EmitSound("ttt_pack_a_punch/beepulon/beepulon" .. math.random(1, 4) .. ".mp3")
                        manhack:SetMaxHealth(1)
                        manhack:SetHealth(1)
                        local phys = manhack:GetPhysicsObject()

                        if phys:IsValid() then
                            phys:SetVelocity(drone:GetDriverDirection() * 1500)
                        end

                        manhack:SetMaterial(TTTPAP.camo)
                        manhack.TTTPAPBigulon = true
                    end

                    drone:SetAmmo(drone.Ammo - 1)
                    drone.nextshoot = CurTime() + 0.75
                    drone.mostrecentammo = CurTime() + 1.6
                end

                drone.gun:SetAngles(viewdir)
            end
        end
    end

    -- Fired manhacks deal increased damage and make beepulon noises
    self:AddHook("EntityTakeDamage", function(ent, dmg)
        local inflictor = dmg:GetInflictor()

        if IsValid(inflictor) and inflictor.TTTPAPBigulon then
            dmg:SetDamage(20)
            dmg:SetAttacker(inflictor.originalplayer or inflictor)
            inflictor:EmitSound("ttt_pack_a_punch/beepulon/beepulon" .. math.random(1, 4) .. ".mp3")
        end
    end)

    function SWEP:PrimaryAttack()
        if CLIENT then return end
        local owner = self:GetOwner()
        if not IsValid(owner) then return end

        if not self:GetNWEntity("target", nil):IsValid() then
            self:SetNextPrimaryFire(CurTime() + 0.5)
            self:SetNextSecondaryFire(CurTime() + 0.5)
            local drone = ents.Create("drone_scout")
            local vThrowPos = owner:EyePos() + owner:GetRight() * 8
            drone:SetPos(self:CheckSpace(vThrowPos) or (vThrowPos + owner:GetForward() * 30))
            drone:Spawn()
            drone.PAPOwner = owner
            local phys = drone:GetPhysicsObject()
            phys:SetVelocity(owner:GetAimVector() * 60 + Vector(0, 0, 200))
            drone:SetAngles(drone:GetAngles() + Angle(0, -90, 0))
            self:SetNWEntity("target", drone)
            self:SetGunThink(drone)
            local timerName = "TTTPAPBigulonSounds" .. drone:EntIndex()

            timer.Create(timerName, 20, 0, function()
                if not IsValid(drone) then
                    timer.Remove(timerName)

                    return
                end

                drone:EmitSound("ttt_pack_a_punch/beepulon/beepulon" .. math.random(1, 4) .. ".mp3", 150, 75)
            end)
        elseif not self:GetNWEntity("target", nil):GetDriver():IsValid() then
            local tr = util.TraceHull{
                start = owner:GetShootPos(),
                endpos = owner:GetShootPos() + owner:GetAimVector() * 100,
                filter = owner,
                mins = Vector(-10, -10, -10),
                maxs = Vector(10, 10, 10)
            }

            local drone = tr.Entity

            if drone:IsValid() and drone.IS_DRONE and drone == self:GetNWEntity("target", nil) then
                drone:Remove()
                self:SetNextPrimaryFire(CurTime() + 0.5)
                self:SetNextSecondaryFire(CurTime() + 0.5)
            end
        end
    end
end

TTTPAP:Register(UPGRADE)