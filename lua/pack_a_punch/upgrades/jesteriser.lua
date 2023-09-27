local UPGRADE = {}
UPGRADE.id = "jesteriser"
UPGRADE.class = "maclunkey"
UPGRADE.name = "Jesteriser"
UPGRADE.desc = "x2 ammo, turns players you shoot into jesters!"
UPGRADE.ammoMult = 2

function UPGRADE:Condition()
    return ROLE_JESTER ~= nil
end

function UPGRADE:Apply(SWEP)
    timer.Simple(0.01, function()
        if IsValid(SWEP:GetOwner()) then
            SWEP:GetOwner():StopSound("weapons/maclunkey_draw.wav")
            SWEP:StopSound("weapons/maclunkey_draw.wav")
        end
    end)

    self:AddHook("EntityTakeDamage", function(ent, dmg)
        if not self:IsPlayer(ent) then return end
        local inflictor = dmg:GetInflictor()
        if not self:IsPlayer(inflictor) then return end
        inflictor = inflictor:GetActiveWeapon()

        if IsValid(inflictor) and inflictor:GetClass() == self.class and inflictor.PAPUpgrade and inflictor.PAPUpgrade.id == self.id then
            ent:SetRole(ROLE_JESTER)
            SendFullStateUpdate()

            return true
        end
    end)
end

TTTPAP:Register(UPGRADE)