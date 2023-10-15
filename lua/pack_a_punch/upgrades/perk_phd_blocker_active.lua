local UPGRADE = {}
UPGRADE.id = "phd_blocker_active"
UPGRADE.class = "zombies_perk_phdflopper"
UPGRADE.name = "PHD Blocker"
UPGRADE.desc = "Bullet damage only!"

function UPGRADE:Apply(SWEP)
    SWEP.PAPOldOnDrank = SWEP.OnDrank

    function SWEP:OnDrank()
        self:PAPOldOnDrank()
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
    end
end

TTTPAP:Register(UPGRADE)