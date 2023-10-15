local UPGRADE = {}
UPGRADE.id = "phd_blocker_stig"
UPGRADE.class = "ttt_perk_phd"
UPGRADE.name = "PHD Blocker"
UPGRADE.desc = "Bullet damage only!"

function UPGRADE:Apply(SWEP)
    SWEP:GetOwner().PAPPHDBlocker = true

    self:AddHook("EntityTakeDamage", function(ent, dmg)
        if IsValid(ent) and ent.PAPPHDBlocker and ent:GetNWBool("PHDActive", false) and not dmg:IsBulletDamage() then
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