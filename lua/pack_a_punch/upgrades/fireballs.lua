local UPGRADE = {}
UPGRADE.id = "fireballs"
UPGRADE.class = "weapon_ttt_snowballs"
UPGRADE.name = "Fireballs"
UPGRADE.desc = "A placeable pile of fireballs!"

function UPGRADE:Apply(SWEP)
    self:AddHook("JokeWeaponsSnowballsPlaced", function(snowballPile, wep)
        if self:IsUpgraded(wep) then
            snowballPile:SetPAPCamo()
            snowballPile.PAPUpgrade = self
            snowballPile.NumberOfUses = 3
        end
    end)

    self:AddHook("JokeWeaponsSnowballsUsed", function(snowballPile, snowballWep)
        if self:IsUpgraded(snowballPile) and TTTPAP:CanOrderPAP(snowballWep) then
            TTTPAP:ApplyUpgrade(snowballWep, TTTPAP.upgrades.weapon_snowball.fireball)
        end
    end)
end

TTTPAP:Register(UPGRADE)