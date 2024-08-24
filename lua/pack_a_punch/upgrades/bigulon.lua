local UPGRADE = {}
UPGRADE.id = "bigulon"
UPGRADE.class = "weapon_dr2_remote"
UPGRADE.name = "Bigulon"

UPGRADE.convar = {
    {
        name = "pap_bigulon_manhack_damage",
        type = "int"
    },
    {
        name = "pap_bigulon_manhack_decay_time",
        type = "int"
    }
}

local damageCvar = CreateConVar("pap_bigulon_manhack_damage", "20", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Damage manhacks deal on touch", 1, 100)

local decayTimeCvar = CreateConVar("pap_bigulon_manhack_decay_time", "20", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds manhacks last until dying", 1, 120)

UPGRADE.desc = "Fires high-damage manhacks instead of missiles.\nManhacks die after " .. decayTimeCvar:GetInt() .. " seconds."

function UPGRADE:Apply(SWEP)
    function SWEP:SetGunThink(drone)
        if not IsValid(drone.gun) then return end

        drone.gun._Think = function()
            local user = drone:GetDriver()

            if not drone:IsDroneDestroyed() and drone:HasFuel() and user:IsValid() then
                local viewdir = Angle(user:EyeAngles().p < -20 and -20 or user:EyeAngles().p, user:EyeAngles().y, 0)

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
                        manhack.PrintName = "Beepulon"
                        local phys = manhack:GetPhysicsObject()

                        if phys:IsValid() then
                            phys:SetVelocity(drone:GetDriverDirection() * 1500)
                        end

                        manhack:SetMaterial(TTTPAP.camo)
                        manhack.TTTPAPBigulon = true

                        timer.Simple(decayTimeCvar:GetInt(), function()
                            if IsValid(manhack) then
                                manhack:Fire("break")
                            end
                        end)
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
    local soundCooldown = false

    self:AddHook("EntityTakeDamage", function(ent, dmg)
        local inflictor = dmg:GetInflictor()

        if IsValid(inflictor) and inflictor.TTTPAPBigulon then
            dmg:SetDamage(damageCvar:GetInt())
            dmg:SetAttacker(inflictor.originalplayer or inflictor)

            if not soundCooldown then
                inflictor:EmitSound("ttt_pack_a_punch/beepulon/beepulon" .. math.random(1, 4) .. ".mp3")
                soundCooldown = true

                timer.Simple(2, function()
                    soundCooldown = false
                end)
            end
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
            local phys = drone:GetPhysicsObject()
            phys:SetVelocity(owner:GetAimVector() * 60 + Vector(0, 0, 200))
            drone:SetAngles(drone:GetAngles() + Angle(0, -90, 0))
            self:SetNWEntity("target", drone)
            self:SetGunThink(drone)
            drone.PrintName = "Bigulon"
            local timerName = "TTTPAPBigulonSounds" .. drone:EntIndex()

            timer.Create(timerName, 20, 0, function()
                if not IsValid(drone) or drone:IsDroneDestroyed() then
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