local UPGRADE = {}
UPGRADE.id = "quadruple_knife"
UPGRADE.class = "weapon_ttt_knife_randomat"
UPGRADE.name = "Quadruple Knife"
UPGRADE.desc = "+3 extra uses!"

function UPGRADE:Apply(SWEP)
    SWEP.Primary.Damage = 10000
    SWEP.KnifeUses = 4

    function SWEP:PrimaryAttack()
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
            local knife = ents.Create("ttt_knife_proj_randomat")
            if not IsValid(knife) then return end
            knife:SetPos(src)
            knife:SetAngles(knife_ang)
            knife:Spawn()
            knife.Damage = self.Primary.Damage
            knife:SetOwner(ply)
            knife:SetPAPCamo()
            local phys = knife:GetPhysicsObject()

            if IsValid(phys) then
                phys:SetVelocity(thr)
                phys:AddAngleVelocity(Vector(0, 1500, 0))
                phys:Wake()
            end

            self.KnifeUses = self.KnifeUses - 1

            if self.KnifeUses <= 0 then
                self:Remove()
            end
        end
    end
end

TTTPAP:Register(UPGRADE)