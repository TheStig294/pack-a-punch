local UPGRADE = {}
UPGRADE.id = "infinite_christmas_cannon_randomat"
UPGRADE.class = "weapon_randomat_christmas_cannon"
UPGRADE.name = "Infinite Christmas Cannon"
UPGRADE.desc = "Infinite Pack-a-Punch presents!"

-- All credit goes to Mal and Nick for creating the Santa role and randomat, including the below function!
function UPGRADE:Apply(SWEP)
    function SWEP:PrimaryAttack()
        if not IsFirstTimePredicted() then return end
        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
        self:EmitSound("weapons/grenade_launcher1.wav")

        if SERVER then
            local present = ents.Create("randomat_hellosanta_present")
            if not present:IsValid() then return false end
            local ang = owner:EyeAngles()
            present:SetAngles(ang)
            present:SetPos(owner:GetShootPos() + ang:Forward() * 50 + ang:Right() * 1 - ang:Up() * 1)
            present:SetOwner(owner)
            -- Presents always contain the Pack-a-Punch!
            present.item_id = EQUIP_PAP
            present:SetPAPCamo()
            present:Spawn()
            local physobj = present:GetPhysicsObject()

            if IsValid(physobj) then
                physobj:SetVelocity(owner:GetAimVector() * 1000)
            end
        end

        owner:ViewPunch(Angle(util.SharedRandom(self:GetClass(), -0.2, -0.1, 0) * self.Primary.Recoil, util.SharedRandom(self:GetClass(), -0.1, 0.1, 1) * self.Primary.Recoil, 0))
    end

    -- Disable coal-piece shooting
    function SWEP:SecondaryAttack()
    end
end

TTTPAP:Register(UPGRADE)