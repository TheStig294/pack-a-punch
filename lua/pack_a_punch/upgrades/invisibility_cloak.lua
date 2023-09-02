local UPGRADE = {}
UPGRADE.id = "invisibility_cloak"
UPGRADE.class = "weapon_ttt_cloak_randomat"
UPGRADE.name = "Invisibility Cloak"
UPGRADE.desc = "Makes you completely invisible"

function UPGRADE:Apply(SWEP)
    local owner = SWEP:GetOwner()

    if SERVER and IsValid(owner) and SWEP.FirstCloakMessage then
        owner:PrintMessage(HUD_PRINTCENTER, "While held, you are completely invisible")

        timer.Simple(2, function()
            owner:PrintMessage(HUD_PRINTCENTER, "While held, you are completely invisible")
        end)

        SWEP.FirstCloakMessage = false
    end

    SWEP.PAPOldDeploy = SWEP.Deploy

    function SWEP:Deploy()
        local own = self:GetOwner()
        if not IsValid(own) then return end
        own:SetNoDraw(true)

        return self:PAPOldDeploy()
    end

    SWEP.PAPOldHolster = SWEP.Holster

    function SWEP:Holster()
        local own = self:GetOwner()
        if not IsValid(own) then return end
        own:SetNoDraw(false)

        return self:PAPOldHolster()
    end
end

TTTPAP:Register(UPGRADE)