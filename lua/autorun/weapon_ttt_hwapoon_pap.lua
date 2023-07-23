TTT_PAP_UPGRADES = TTT_PAP_UPGRADES or {}

TTT_PAP_UPGRADES.weapon_ttt_hwapoon = {
    name = "Triple Hwapoon",
    desc = "Throw 3 hwapoons at once!",
    func = function(SWEP)
        if SERVER then
            SWEP.Primary.ClipSize = 3
            SWEP.Primary.ClipMax = 3
            SWEP.Primary.DefaultClip = 3
            SWEP:SetClip1(3)

            function SWEP:PrimaryAttack()
                local owner = self:GetOwner()
                if not IsValid(owner) then return end
                self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
                if not self:CanPrimaryAttack() then return end
                self:TakePrimaryAmmo(1)
                self:CreateArrow("normal", owner, self)
                self.NextShot = CurTime() + 0.5

                if not (game.SinglePlayer() and CLIENT) then
                    self:EmitSound("weapons/crossbow/bolt_fly4.wav", 100, 100)
                    self:EmitSound("hwapoon" .. math.random(1, 5) .. ".wav", 100, 100)
                end

                owner:ViewPunch(Angle(math.Rand(-0.2, -0.1) * 10, math.Rand(-0.1, 0.1) * 10, 0))

                if SERVER and self:Clip1() <= 0 then
                    self:Remove()
                end
            end
        end
    end
}