local UPGRADE = {}
UPGRADE.id = "thieves_upgrader"
UPGRADE.class = "weapon_thf_thievestools"
UPGRADE.name = "Thieves' Upgrader"
UPGRADE.desc = "All stolen weapons are upgraded!"

function UPGRADE:Apply(SWEP)
    local PLAYER = FindMetaTable("Player")
    if PLAYER.PAPOldThiefSteal then return end
    PLAYER.PAPOldThiefSteal = PLAYER.ThiefSteal

    function PLAYER:ThiefSteal(...)
        local hasUpgradedWeapon = false
        local oldWeapons = {}

        for _, wep in ipairs(self:GetWeapons()) do
            oldWeapons[wep] = true

            if UPGRADE:IsUpgraded(wep) then
                hasUpgradedWeapon = true
            end
        end

        self:PAPOldThiefSteal(...)
        if not hasUpgradedWeapon then return end

        for _, wep in ipairs(self:GetWeapons()) do
            if not oldWeapons[wep] then
                TTTPAP:ApplyRandomUpgrade(wep)
            end
        end
    end
end

TTTPAP:Register(UPGRADE)