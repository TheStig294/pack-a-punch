local UPGRADE = {}
UPGRADE.id = "slime_sprinkler"
UPGRADE.class = "tfa_sliquifier"
UPGRADE.name = "Slime Sprinkler"
UPGRADE.desc = "Unlimited ammo + higher firerate + full-auto\nDoesn't deal direct damage"
UPGRADE.firerateMult = 3
UPGRADE.automatic = true

function UPGRADE:Apply(SWEP)
    SWEP.PAPOldPrimaryAttack = SWEP.PrimaryAttack

    function SWEP:PrimaryAttack()
        self:PAPOldPrimaryAttack()
        self:SetClip1(self.Primary.ClipSize)
    end

    self:AddHook("EntityTakeDamage", function(ent, dmg)
        local inflictor = dmg:GetInflictor()
        if not IsValid(inflictor) or inflictor:GetClass() ~= "obj_sliquifier_proj" then return end
        local attacker = dmg:GetAttacker()
        if not IsValid(attacker) or not attacker:IsPlayer() then return end
        local wep = attacker:GetWeapon(self.class)
        if inflictor:GetClass() == "obj_sliquifier_proj" and IsValid(wep) and wep.PAPUpgrade and wep.PAPUpgrade.id == self.id then return true end
    end)
end

TTTPAP:Register(UPGRADE)