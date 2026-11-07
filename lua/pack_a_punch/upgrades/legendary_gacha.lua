local UPGRADE = {}
UPGRADE.id = "legendary_gacha"
UPGRADE.class = "weapon_gmr_gacha"
UPGRADE.name = "Legendary Gacha"
UPGRADE.desc = "Always gives legendary prizes!"

function UPGRADE:Apply(SWEP)
    SWEP.PAPOldPrimaryAttack = SWEP.PrimaryAttack

    function SWEP:PrimaryAttack()
        local originalChances = {}

        -- Set all non-legendary rarities for this gacha spin to 0% chance, and legendary to 100% chance
        for _, rarity in pairs(GAMER.Rarities) do
            originalChances[rarity] = GAMER.Config.Rarities[rarity].Chance
            GAMER.Config.Rarities[rarity].Chance = rarity == GAMER.Rarities.Legendary and 1 or 0
        end

        self:PAPOldPrimaryAttack()

        -- Reset all rarities for the next gacha spin that might not necessarily be upgraded
        for _, rarity in pairs(GAMER.Rarities) do
            GAMER.Config.Rarities[rarity].Chance = originalChances[rarity]
        end
    end
end

TTTPAP:Register(UPGRADE)