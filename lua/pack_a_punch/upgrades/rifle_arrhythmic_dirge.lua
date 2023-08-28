local UPGRADE = {}
UPGRADE.id = "rifle_arrhythmic_dirge"
UPGRADE.class = "weapon_zm_rifle"
UPGRADE.name = "Arrhythmic Dirge"
UPGRADE.desc = "Zoomier zoom, fire rate increase!"
UPGRADE.automatic = false
UPGRADE.firerateMult = 1.2
UPGRADE.damageMult = 1.5

function UPGRADE:Apply(SWEP)
    if SERVER then
        function SWEP:SetZoom(state)
            if IsValid(self:GetOwner()) and self:GetOwner():IsPlayer() then
                if state then
                    self:GetOwner():SetFOV(10, 0.4)
                else
                    self:GetOwner():SetFOV(0, 0.2)
                end
            end
        end
    end
end

TTTPAP:Register(UPGRADE)