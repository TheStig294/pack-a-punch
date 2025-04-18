local UPGRADE = {}
UPGRADE.id = "truck_gun"
UPGRADE.class = "weapon_ttt_car_gun"
UPGRADE.name = "Truck Gun"
UPGRADE.desc = "Now shoots a truck, you can't miss!"

UPGRADE.convars = {
    {
        name = "pap_truck_gun_ammo",
        type = "int"
    },
    {
        name = "pap_truck_gun_target_damage",
        type = "int"
    },
    {
        name = "pap_truck_gun_non_target_damage",
        type = "int"
    },
    {
        name = "pap_truck_gun_speed",
        type = "int"
    },
    {
        name = "pap_truck_gun_scale",
        type = "float"
    },
    {
        name = "pap_truck_gun_range",
        type = "int"
    }
}

local ammoCvar = CreateConVar("pap_truck_gun_ammo", "1", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Truck gun ammo", 1, 10)

function UPGRADE:Apply(SWEP)
    self:SetClip(SWEP, ammoCvar:GetInt())
    SWEP.Sound = Sound("ttt_pack_a_punch/truck_gun/trucking_tuesday.mp3")
    SWEP:SetHoldType(SWEP.HoldType)

    function SWEP:PrimaryAttack()
        if CLIENT or not self:CanPrimaryAttack() then return end
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        owner:EmitSound("weapons/pistol/pistol_fire2.wav")
        self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
        local cone = self.Primary.Cone
        local bullet = {}
        bullet.Attacker = owner
        bullet.Num = 1
        bullet.Src = owner:GetShootPos()
        bullet.Dir = owner:GetAimVector()
        bullet.Spread = Vector(cone, cone, 0)
        bullet.Tracer = 1
        bullet.Force = 10
        bullet.Damage = 1
        bullet.AmmoType = self.Primary.Ammo
        bullet.TracerName = "PhyscannonImpact"

        bullet.Callback = function(_, tr)
            if SERVER or CLIENT and IsFirstTimePredicted() then
                local victim = tr.Entity

                if IsValid(victim) then
                    victim:EmitSound(self.Sound)
                    owner:EmitSound(self.Sound)

                    if SERVER and victim:IsPlayer() then
                        local victimAim = owner:GetAimVector()
                        victimAim.x = -victimAim.x
                        victimAim.y = -victimAim.y
                        victimAim.z = -victimAim.z
                        victimAim = victimAim:Angle()
                        victim:SetEyeAngles(victimAim)
                        self:TakePrimaryAmmo(1)

                        if self:Clip1() <= 0 then
                            self:Remove()
                        end

                        timer.Simple(0, function()
                            victim:Lock()
                            local truck = ents.Create("ttt_pap_truck_gun_truck")
                            truck:SetPos(owner:EyePos() + owner:GetAimVector() * 100)
                            truck:SetAngles(owner:EyeAngles())
                            truck:SetOwner(owner)
                            truck.SWEP = self
                            truck.Target = victim
                            truck:Spawn()
                        end)
                    end
                end
            end
        end

        owner:FireBullets(bullet)
    end
end

TTTPAP:Register(UPGRADE)