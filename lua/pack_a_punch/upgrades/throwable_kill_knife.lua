local UPGRADE = {}
UPGRADE.id = "throwable_kill_knife"
UPGRADE.class = "weapon_ttt_impostor_knife_randomat"
UPGRADE.name = "Throwable Kill Knife"
UPGRADE.desc = "Is now throwable!"

function UPGRADE:Apply(SWEP)
    local owner = SWEP:GetOwner()

    if IsValid(owner) and not IsValid(SWEP.PAPOriginalOwner) and owner:GetRole() == ROLE_TRAITOR then
        SWEP.PAPOriginalOwner = owner
    end

    function SWEP:SecondaryAttack()
        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
        self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)
        self:SendWeaponAnim(ACT_VM_MISSCENTER)

        if SERVER then
            local ply = self:GetOwner()
            if not IsValid(ply) then return end
            ply:SetAnimation(PLAYER_ATTACK1)
            local ang = ply:EyeAngles()

            if ang.p < 90 then
                ang.p = -10 + ang.p * (90 + 10) / 90
            else
                ang.p = 360 - ang.p
                ang.p = -10 + ang.p * -((90 + 10) / 90)
            end

            local vel = math.Clamp((90 - ang.p) * 5.5, 550, 800)
            local vfw = ang:Forward()
            local vrt = ang:Right()
            local src = ply:GetPos() + (ply:Crouching() and ply:GetViewOffsetDucked() or ply:GetViewOffset())
            src = src + vfw * 1 + vrt * 3
            local thr = vfw * vel + ply:GetVelocity()
            local knife_ang = Angle(-28, 0, 0) + ang
            knife_ang:RotateAroundAxis(knife_ang:Right(), -90)
            local knife = ents.Create("ttt_pap_throwable_kill_knife")
            if not IsValid(knife) then return end
            knife:SetPos(src)
            knife:SetAngles(knife_ang)
            knife:Spawn()
            knife.Damage = self.Primary.Damage
            knife:SetOwner(ply)
            local phys = knife:GetPhysicsObject()

            if IsValid(phys) then
                phys:SetVelocity(thr)
                phys:AddAngleVelocity(Vector(0, 1500, 0))
                phys:Wake()
            end

            self:Remove()
        end
    end

    function SWEP:PrimaryAttack()
        self:SecondaryAttack()
    end

    self:AddHook("PlayerCanPickupWeapon", function(ply, wep)
        if not IsValid(wep) then return end
        if wep:GetClass() ~= self.class then return end
        if wep.PAPOriginalOwner and wep.PAPOriginalOwner ~= ply then return false end
    end)
end

TTTPAP:Register(UPGRADE)