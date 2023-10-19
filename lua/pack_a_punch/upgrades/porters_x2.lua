local UPGRADE = {}
UPGRADE.id = "porters_x2"
UPGRADE.class = "tfa_raygun"
UPGRADE.name = "Porter's X2"
UPGRADE.desc = "Immune to your own shots + extra ammo!"
UPGRADE.ammoMult = 2

function UPGRADE:Apply(SWEP)
    -- Is a CoD weapon, so has its own PAP function we can take advantage of, this is not from this mod
    SWEP:OnPaP()

    self:AddHook("EntityTakeDamage", function(ent, dmg)
        local inflictor = dmg:GetInflictor()
        local attacker = dmg:GetAttacker()
        if WEPS.GetClass(inflictor) == self.class and IsValid(attacker) and attacker == ent and IsValid(ent:GetActiveWeapon()) and WEPS.GetClass(ent:GetActiveWeapon()) == self.class then return true end
    end)
end

TTTPAP:Register(UPGRADE)