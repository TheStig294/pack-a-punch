local UPGRADE = {}
UPGRADE.id = "phd_blocker_hoff"
UPGRADE.class = "zombies_perk_phdflopper"
UPGRADE.name = "PHD Blocker"
UPGRADE.desc = "Bullet damage only!"

function UPGRADE:Apply(SWEP)
    SWEP:GetOwner().PAPUpgradedHoffBottle = true
    SWEP.PAPOldOnDrank = SWEP.OnDrank

    function SWEP:OnDrank()
        SWEP:PAPOldOnDrank()
        self:GetOwner().PAPPHDBlocker = true
    end

    self:AddHook("EntityTakeDamage", function(ent, dmg)
        if IsValid(ent) and ent.PAPPHDBlocker and not dmg:IsBulletDamage() then
            dmg:SetDamage(0)
        end
    end)
end

function UPGRADE:Reset()
    for _, ply in ipairs(player.GetAll()) do
        ply.PAPPHDBlocker = nil
        ply.PAPUpgradedHoffBottle = nil
    end
end

TTTPAP:Register(UPGRADE)