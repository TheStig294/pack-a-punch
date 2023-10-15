local UPGRADE = {}
UPGRADE.id = "perk_doubletap_05_passive"
UPGRADE.class = "ttt_perk_doubletap"
UPGRADE.name = "Doubletap 0.5"
UPGRADE.desc = "Slows the shoot speed of other players you shoot!"

function UPGRADE:Apply(SWEP)
    local owner = SWEP:GetOwner()
    owner.PAPDoubleTap2 = true

    self:AddHook("EntityTakeDamage", function(ent, dmg)
        if not self:IsPlayer(ent) then return end
        local attacker = dmg:GetAttacker()
        if not IsValid(attacker) or not attacker.PAPDoubleTap2 then return end
        local activeWep = ent:GetActiveWeapon()

        if IsValid(activeWep) and not activeWep.PAPDoubleTap2Slow then
            activeWep.PAPDoubleTap2Slow = true

            if activeWep.Primary and isnumber(activeWep.Primary.Delay) then
                activeWep.Primary.Delay = activeWep.Primary.Delay * 1.5
                ent:ChatPrint("Shoot speed slowed by someone!")
            end
        end
    end)
end

function UPGRADE:Reset()
    for _, ply in ipairs(player.GetAll()) do
        ply.PAPDoubleTap2 = nil
    end
end

TTTPAP:Register(UPGRADE)