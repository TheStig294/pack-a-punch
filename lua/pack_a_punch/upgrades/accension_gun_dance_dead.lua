local UPGRADE = {}
UPGRADE.id = "accension_gun_dance_dead"
UPGRADE.class = "dancedead"
UPGRADE.name = "Accension Gun"
UPGRADE.desc = "x2 ammo, players ascend into the sky as they die..."
UPGRADE.ammoMult = 2

function UPGRADE:Apply(SWEP)
    self:AddHook("EntityTakeDamage", function(victim, dmg)
        if not self:IsPlayer(victim) then return end
        local attacker = dmg:GetAttacker()
        if not self:IsPlayer(attacker) then return end
        local wep = attacker:GetActiveWeapon()

        if self:IsUpgraded(wep) then
            local timername = victim:SteamID64() .. "TTTPAPAccensionGunLift"

            timer.Create(victim:SteamID64() .. "TTTPAPAccensionGunLift", 0.01, 2000, function()
                if not IsValid(victim) or not victim:Alive() or victim:IsSpec() or GetRoundState == ROUND_PREP then
                    timer.Remove(timername)

                    if IsValid(victim) then
                        victim:SetGravity(1)
                    end

                    return
                end

                victim:SetGravity(0.01)
                local pos = victim:GetPos()
                pos.z = pos.z + 2
                victim:SetPos(pos)
            end)
        end
    end)
end

TTTPAP:Register(UPGRADE)