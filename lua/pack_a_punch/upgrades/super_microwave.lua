local UPGRADE = {}
UPGRADE.id = "super_microwave"
UPGRADE.class = "weapon_ttt_health_station"
UPGRADE.name = "Super Microwave"
UPGRADE.desc = "Heal much faster, x2 capacity"

function UPGRADE:Apply(SWEP)
    local throwsound = Sound("Weapon_SLAM.SatchelThrow")

    function SWEP:HealthDrop()
        if SERVER then
            local ply = self:GetOwner()
            if not IsValid(ply) then return end
            if self.Planted then return end
            local vsrc = ply:GetShootPos()
            local vang = ply:GetAimVector()
            local vvel = ply:GetVelocity()
            local vthrow = vvel + vang * 200
            local health = ents.Create("ttt_health_station")

            if IsValid(health) then
                health:SetPos(vsrc + vang * 10)
                health:Spawn()
                health:SetPlacer(ply)
                health:PhysWake()
                health:SetPAPCamo()
                health.MaxHeal = 50
                health.MaxStored = 400
                health.RechargeRate = 2
                health.RechargeFreq = 1 -- in seconds
                health.HealRate = 2
                health.HealFreq = 0.1
                health:SetStoredHealth(400)
                local phys = health:GetPhysicsObject()

                if IsValid(phys) then
                    phys:SetVelocity(vthrow)
                end

                self:Remove()
                self.Planted = true
            end
        end

        self:EmitSound(throwsound)
    end
end

TTTPAP:Register(UPGRADE)