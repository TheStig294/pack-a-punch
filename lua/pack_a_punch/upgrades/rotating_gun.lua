local UPGRADE = {}
UPGRADE.id = "rotating_gun"
UPGRADE.class = "rotgun"
UPGRADE.name = "Rotating Gun"
UPGRADE.desc = "Stronger spin, players keep rotating for a few seconds!"

function UPGRADE:Apply(SWEP)
    self:AddToHook(SWEP, "PrimaryAttack", function()
        local owner = SWEP:GetOwner()
        if not IsValid(owner) then return end
        local victim = owner:GetEyeTrace().Entity
        if not self:IsPlayer(victim) then return end
        ply:SetEyeAngles(ply:EyeAngles() + Angle(0, 20, 0))
        victim:StopSound("ttt_pack_a_punch/rotating_gun/maxwell_rotate.mp3")
        victim:EmitSound("ttt_pack_a_punch/rotating_gun/maxwell_rotate.mp3")
        local timerName = "TTTPAPRotatingGun" .. victim:EntIndex()

        timer.Create(timerName, 0.01, 250, function()
            if not IsValid(victim) then
                timer.Remove(timerName)

                return
            elseif not self:IsAlive(victim) then
                victim:StopSound("ttt_pack_a_punch/rotating_gun/maxwell_rotate.mp3")
            else
                victim:SetEyeAngles(victim:EyeAngles() + Angle(0, 1, 0))
            end
        end)
    end)
end

TTTPAP:Register(UPGRADE)