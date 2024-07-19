local UPGRADE = {}
UPGRADE.id = "lmao_bang_cr_m9k"
UPGRADE.class = "weapon_cr_m9k_dbarrel"
UPGRADE.name = "Lmao Bang"
UPGRADE.desc = "x2 ammo, new gun shoot sounds!"
UPGRADE.noSound = true
UPGRADE.ammoMult = 2

function UPGRADE:Apply(SWEP)
    SWEP.Primary.Sound = "ttt_pack_a_punch/lmao_bang/bang1.mp3"
    SWEP.Secondary.Sound = "ttt_pack_a_punch/lmao_bang/bang2.mp3"

    function SWEP:SecondaryAttack()
        local ammo = self:Clip1()
        self.SecondaryAttacking = true

        if ammo <= 0 then
            self:Reload()
            self.SecondaryAttacking = false
        elseif ammo == 1 then
            self:PrimaryAttack()
            self.SecondaryAttacking = false
        else
            self:PrimaryAttack()
            self:SetNextPrimaryFire(CurTime() + 0.05)
            local timername = "TTTPAPLmaoBang" .. self:EntIndex()

            timer.Create(timername, 0.05, ammo - 1, function()
                if not IsValid(self) then
                    timer.Remove(timername)

                    return
                end

                self:PrimaryAttack()
                self:SetNextPrimaryFire(CurTime() + 0.05)

                if timer.RepsLeft(timername) == 0 then
                    self.SecondaryAttacking = false
                end
            end)
        end
    end

    self:AddToHook(SWEP, "PrimaryAttack", function()
        if SWEP.SecondaryAttacking then
            SWEP:EmitSound(SWEP.Secondary.Sound)
        end
    end)
end

TTTPAP:Register(UPGRADE)