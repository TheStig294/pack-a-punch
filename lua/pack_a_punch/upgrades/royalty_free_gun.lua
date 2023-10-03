local UPGRADE = {}
UPGRADE.id = "royalty_free_gun"
UPGRADE.class = "weapon_dubstepgun"
UPGRADE.name = "Royalty Free Gun"
UPGRADE.desc = "New music, more damage,\ngoes through most explosion immunities!"

function UPGRADE:Apply(SWEP)
    function SWEP:PrimaryAttack()
        if not self:CanPrimaryAttack() then return end

        if self.LoopSound then
            self.LoopSound:ChangeVolume(1, 0.1)
        else
            self.LoopSound = CreateSound(self:GetOwner(), Sound("ttt_pack_a_punch/royalty_free_gun/disfigure_blank.mp3"))

            if self.LoopSound then
                self.LoopSound:Play()
            end
        end

        if self.BeatSound then
            self.BeatSound:ChangeVolume(0, 0.1)
        end

        if self.PreventEffectSpam == true then return end
        self.PreventEffectSpam = true
        self.AllowBounce = true

        timer.Simple(0.3, function()
            self.PreventEffectSpam = false
        end)

        timer.Simple(0.45, function()
            self.AllowBounce = false
        end)

        local tr = self:GetOwner():GetEyeTrace()
        local effectdata = EffectData()
        effectdata:SetOrigin(tr.HitPos)
        util.Effect("dubstep_wub_effect", effectdata, true, true)
        local effectdata2 = EffectData()
        effectdata2:SetOrigin(tr.HitPos)
        effectdata2:SetStart(self:GetOwner():GetShootPos())
        effectdata2:SetScale(5)
        effectdata2:SetAttachment(1)
        effectdata2:SetEntity(self)
        util.Effect("dubstep_wub_beam", effectdata2, true, true)

        if SERVER and IsFirstTimePredicted() then
            for _, ent in ipairs(ents.FindInSphere(tr.HitPos, 175)) do
                if not IsValid(ent) then continue end
                local dmg = DamageInfo()
                dmg:SetDamage(17)
                dmg:SetDamageType(DMG_CLUB)
                dmg:SetInflictor(self)
                local attacker = self:GetOwner()

                if not IsValid(attacker) then
                    attacker = self
                end

                dmg:SetAttacker(attacker)
                ent:TakeDamageInfo(dmg)
            end
        end

        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
        self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)
    end
end

TTTPAP:Register(UPGRADE)