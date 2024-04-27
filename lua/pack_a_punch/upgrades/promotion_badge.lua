local UPGRADE = {}
UPGRADE.id = "promotion_badge"
UPGRADE.class = "weapon_mhl_badge"
UPGRADE.name = "Promotion Badge"
UPGRADE.desc = "Auto-promotes the player to detective!"

function UPGRADE:Apply(SWEP)
    self:AddHook("TTTPlayerRoleChangedByItem", function(owner, target, wep)
        if WEPS.GetClass(wep) == self.class and self:IsUpgraded(wep) then
            timer.Simple(0.1, function()
                if IsValid(target) then
                    target:HandleDetectiveLikePromotion()
                end
            end)
        end
    end)
end

TTTPAP:Register(UPGRADE)