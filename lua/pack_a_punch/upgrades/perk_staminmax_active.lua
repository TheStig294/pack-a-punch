local UPGRADE = {}
UPGRADE.id = "perk_staminmax_active"
UPGRADE.class = "zombies_perk_staminup"
UPGRADE.name = "Staminmax"
UPGRADE.desc = "Double walk speed"

-- Staminup perk errors on being removed because ent:IsValid() is being used, rather than IsValid(ent),
-- and doesn't check for self.CachedSpeeds being valid
hook.Add("PreRegisterSWEP", "TTTPAPFixActiveStaminup", function(SWEP, class)
    if class == "zombies_perk_staminup" then
        function SWEP:OnRemove()
            local owner = self:GetOwner()

            if IsValid(owner) and owner:Alive() and self.CachedSpeeds and self.CachedSpeeds[0] and self.CachedSpeeds[1] then
                owner:SetWalkSpeed(self.CachedSpeeds[0])
                owner:SetRunSpeed(self.CachedSpeeds[1])
            end
        end
    end
end)

function UPGRADE:Apply(SWEP)
    SWEP.PAPOldOnDrank = SWEP.OnDrank

    function SWEP:OnDrank()
        local owner = self:GetOwner()

        if IsValid(owner) then
            local walkSpeed = owner:GetWalkSpeed()
            self:PAPOldOnDrank()
            -- The staminup perk resets player walk speed by itself
            owner:SetWalkSpeed(walkSpeed * 2)
        end
    end
end

TTTPAP:Register(UPGRADE)