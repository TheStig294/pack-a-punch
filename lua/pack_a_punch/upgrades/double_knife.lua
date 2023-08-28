local UPGRADE = {}
UPGRADE.id = "double_knife"
UPGRADE.class = "weapon_ttt_knife"
UPGRADE.name = "Double Knife"
UPGRADE.desc = "+1 extra use, one-shot kills!"

function UPGRADE:Apply(SWEP)
    SWEP.Primary.Damage = 10000
    SWEP.KnifeCount = 0

    function SWEP:PrimaryAttack()
        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
        self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)
        if not IsValid(self:GetOwner()) then return end
        self:GetOwner():LagCompensation(true)
        local spos = self:GetOwner():GetShootPos()
        local sdest = spos + self:GetOwner():GetAimVector() * 70
        local kmins = Vector(1, 1, 1) * -10
        local kmaxs = Vector(1, 1, 1) * 10

        local tr = util.TraceHull({
            start = spos,
            endpos = sdest,
            filter = self:GetOwner(),
            mask = MASK_SHOT_HULL,
            mins = kmins,
            maxs = kmaxs
        })

        -- Hull might hit environment stuff that line does not hit
        if not IsValid(tr.Entity) then
            tr = util.TraceLine({
                start = spos,
                endpos = sdest,
                filter = self:GetOwner(),
                mask = MASK_SHOT_HULL
            })
        end

        local hitEnt = tr.Entity

        -- effects
        if IsValid(hitEnt) then
            self:SendWeaponAnim(ACT_VM_HITCENTER)
            local edata = EffectData()
            edata:SetStart(spos)
            edata:SetOrigin(tr.HitPos)
            edata:SetNormal(tr.Normal)
            edata:SetEntity(hitEnt)

            if hitEnt:IsPlayer() or hitEnt:GetClass() == "prop_ragdoll" then
                util.Effect("BloodImpact", edata)
            end
        else
            self:SendWeaponAnim(ACT_VM_MISSCENTER)
        end

        if SERVER then
            self:GetOwner():SetAnimation(PLAYER_ATTACK1)
        end

        if SERVER and tr.Hit and tr.HitNonWorld and IsValid(hitEnt) and hitEnt:IsPlayer() then
            -- knife damage is never karma'd, so don't need to take that into
            -- account we do want to avoid rounding error strangeness caused by
            -- other damage scaling, causing a death when we don't expect one, so
            -- when the target's health is close to kill-point we just kill
            if hitEnt:Health() < self.Primary.Damage + 10 then
                self:StabKill(tr, spos, sdest)
            else
                local dmg = DamageInfo()
                dmg:SetDamage(self.Primary.Damage)
                dmg:SetAttacker(self:GetOwner())
                dmg:SetInflictor(self or self)
                dmg:SetDamageForce(self:GetOwner():GetAimVector() * 5)
                dmg:SetDamagePosition(self:GetOwner():GetPos())
                dmg:SetDamageType(DMG_SLASH)
                hitEnt:DispatchTraceAttack(dmg, spos + self:GetOwner():GetAimVector() * 3, sdest)
            end

            self.KnifeCount = self.KnifeCount + 1

            if self.KnifeCount >= 2 then
                self:Remove()
            end
        end

        self:GetOwner():LagCompensation(false)
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
            local knife = ents.Create("ttt_knife_proj")
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

            self.KnifeCount = self.KnifeCount + 1

            if self.KnifeCount >= 2 then
                self:Remove()
            end
        end
    end
end

TTTPAP:Register(UPGRADE)