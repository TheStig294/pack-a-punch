local UPGRADE = {}
UPGRADE.id = "safe_fire_dash"
UPGRADE.class = "weapon_ttt_fire_dash"
UPGRADE.name = "Safe Fire Dash"
UPGRADE.desc = "Doesn't kill you!\nImmune to fire damage while active"

function UPGRADE:Apply(SWEP)
    self:AddHook("EntityTakeDamage", function(victim, dmg)
        if not self:IsAlivePlayer(victim) or not dmg:IsDamageType(DMG_BURN) then return end
        local activeWep = victim:GetActiveWeapon()
        if not IsValid(activeWep) then return end
        -- The fire dash being "Active" means a player has left-clicked with the weapon and they can now run into players to kill them (for 10 seconds)
        -- After this time the weapon is automatically removed, so their fire damage immunity should stop as well
        if WEPS.GetClass(activeWep) == self.class and self:IsUpgraded(activeWep) and activeWep.Active then return true end
    end)
end

TTTPAP:Register(UPGRADE)