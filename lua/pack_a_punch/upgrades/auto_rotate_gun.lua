local UPGRADE = {}
UPGRADE.id = "auto_rotate_gun"
UPGRADE.class = "rotgun"
UPGRADE.name = "Auto-Rotate Gun"
UPGRADE.desc = "Players auto-rotate for a sec!"

function UPGRADE:Apply(SWEP)
    SWEP.Primary.Damage = 5

    function SWEP:PrimaryAttack()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        local victim = owner:GetEyeTrace().Entity

        if UPGRADE:IsPlayer(victim) then
            victim:StopSound("ttt_pack_a_punch/auto_rotate_gun/maxwell_rotate.mp3")
            victim:EmitSound("ttt_pack_a_punch/auto_rotate_gun/maxwell_rotate.mp3")
            local timerName = "TTTPAPAutoRotateGun" .. victim:EntIndex()

            timer.Create(timerName, 0.01, 115, function()
                if not IsValid(victim) then
                    timer.Remove(timerName)

                    return
                elseif not UPGRADE:IsAlive(victim) then
                    victim:StopSound("ttt_pack_a_punch/auto_rotate_gun/maxwell_rotate.mp3")
                else
                    victim:SetEyeAngles(victim:EyeAngles() + Angle(0, 1, 0))
                end
            end)
        end

        return self.BaseClass.PrimaryAttack(self)
    end
end

TTTPAP:Register(UPGRADE)