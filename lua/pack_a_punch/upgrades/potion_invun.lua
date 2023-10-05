local UPGRADE = {}
UPGRADE.id = "potion_invun"
UPGRADE.class = "weapon_ttt_mc_immortpotion"
UPGRADE.name = "Invunerability Potion"
UPGRADE.desc = "Take bullet damage only while held!"

function UPGRADE:Apply(SWEP)
    timer.Simple(0.1, function()
        SWEP:SetClip1(-1)
    end)

    self:AddHook("EntityTakeDamage", function(ent, dmg)
        if dmg:IsBulletDamage() or not self:IsAlivePlayer(ent) then return end
        local wep = ent:GetActiveWeapon()
        if IsValid(wep) and WEPS.GetClass(wep) == self.class and wep.PAPUpgrade.id == self.id then return true end
    end)

    if CLIENT then
        SWEP.PAPOldDrawWorldModel = SWEP.DrawWorldModel

        function SWEP:DrawWorldModel()
            SWEP:PAPOldDrawWorldModel()

            if IsValid(self.WorldModelEnt) then
                self.WorldModelEnt:SetMaterial(TTTPAP.camo)
            end
        end
    end
end

TTTPAP:Register(UPGRADE)