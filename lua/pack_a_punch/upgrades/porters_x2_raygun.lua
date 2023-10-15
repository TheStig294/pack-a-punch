local UPGRADE = {}
UPGRADE.id = "porters_x2_raygun"
UPGRADE.class = "tfa_raygun"
UPGRADE.name = "Porter's X2 Ray Gun"
UPGRADE.desc = "Immune to your own shots + extra ammo!"

function UPGRADE:Apply(SWEP)
    SWEP:OnPaP()
    SWEP.Primary.ClipSize = 40
    SWEP:SetClip1(SWEP:Clip1() * 2)

    self:AddHook("EntityTakeDamage", function(ent, dmg)
        local inflictor = dmg:GetInflictor()
        local attacker = dmg:GetAttacker()
        if WEPS.GetClass(inflictor) == self.class and IsValid(attacker) and attacker == ent and IsValid(ent:GetActiveWeapon()) and WEPS.GetClass(ent:GetActiveWeapon()) == self.class then return true end
    end)
end

TTTPAP:Register(UPGRADE)