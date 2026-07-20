local UPGRADE = {}
UPGRADE.id = "true_whale"
UPGRADE.class = "weapon_whl_buffettable"
UPGRADE.name = "True Whale"
UPGRADE.desc = "You can pick from ANY role!"
UPGRADE.noSelectWep = true

function UPGRADE:Apply(SWEP)
    local trueWhaleCvar = GetConVar("ttt_whaleindependent_is_true_whale")
    local originalValue = trueWhaleCvar:GetBool()
    local own = SWEP:GetOwner()

    if IsValid(own) then
        own:SetRole(ROLE_WHALEINDEPENDENT)

        if SERVER then
            SendFullStateUpdate()
        end

        -- Some annoying jank to do with some weird setup logic done in the weapon's Deploy hook
        if CLIENT then
            input.SelectWeapon(SWEP)
        end
    end

    SWEP.PAPOldSecondaryAttack = SWEP.SecondaryAttack

    function SWEP:SecondaryAttack()
        if SERVER then
            trueWhaleCvar:SetBool(true)
        end

        self:PAPOldSecondaryAttack()

        if SERVER then
            trueWhaleCvar:SetBool(originalValue)
        end
    end
end

TTTPAP:Register(UPGRADE)