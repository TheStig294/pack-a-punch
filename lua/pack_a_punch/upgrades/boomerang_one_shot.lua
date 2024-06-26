local UPGRADE = {}
UPGRADE.id = "boomerang_one_shot"
UPGRADE.class = "weapon_ttt_boomerang_randomat"
UPGRADE.name = "1-Shot Boomerang"
UPGRADE.desc = "It's a 1-shot if it hits you once!"

function UPGRADE:Apply(SWEP)
    SWEP:GetOwner().PAP1ShotBoomerang = true
    SWEP.Primary.Damage = 10000

    function SWEP:PrimaryAttack()
        if self:Clip1() <= 0 then return end
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
        local Pos = owner:GetShootPos()
        local trace = owner:GetEyeTrace()
        local targetPos = trace.HitPos

        if trace.HitWorld and Pos:Distance(targetPos) < 2000 then
            targetPos = targetPos - (Pos - targetPos):GetNormalized() * 10
        else
            targetPos = Pos + owner:GetAimVector() * 2000
        end

        targetPos = Pos + owner:GetAimVector() * 2000
        self:EmitSound("weapons/slam/throw.wav")

        if SERVER then
            local boomerang = ents.Create("ttt_pap_boomerang_one_shot")
            boomerang:SetAngles(Angle(20, 0, 90))
            boomerang:SetPos(owner:GetShootPos())
            boomerang:SetOwner(owner)
            boomerang:SetPhysicsAttacker(owner, 10)
            boomerang:SetNWVector("targetPos", targetPos)
            boomerang:Spawn()
            boomerang:Activate()
            boomerang.Hits = self.Hits
            boomerang.LastVelocity = owner:GetAimVector()
            boomerang.Damage = self.Primary.Damage
            local phys = boomerang:GetPhysicsObject()
            phys:SetVelocity(owner:GetAimVector():GetNormalized() * 10)
            phys:AddAngleVelocity(Vector(0, -10, 0))

            -- Fail-safe to give back a boomerang after a certain amount of time if it does not return
            timer.Create(owner:SteamID64() .. "BoomerangRandomatTimer", GetConVar("randomat_boomerang_timer"):GetInt(), 1, function()
                if not owner:HasWeapon(GetConVar("randomat_boomerang_weaponid"):GetString()) and Randomat:IsEventActive("boomerang") then
                    owner:Give(GetConVar("randomat_boomerang_weaponid"):GetString())
                end
            end)

            self:Remove()
        end
    end

    -- Make every boomerang equipped by a player with this weapon be a PAP version until the next round
    self:AddHook("WeaponEquip", function(weapon, owner)
        local class = weapon:GetClass()

        if owner.PAP1ShotBoomerang and class == self.class then
            -- Prevent the upgrade description from being displayed every time the weapon is received
            self.noDesc = true
            TTTPAP:ApplyUpgrade(weapon, self)
        end
    end)
end

TTTPAP:Register(UPGRADE)