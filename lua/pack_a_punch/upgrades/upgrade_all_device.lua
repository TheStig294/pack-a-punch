local UPGRADE = {}
UPGRADE.id = "upgrade_all_device"
UPGRADE.class = "weapon_tnk_upgrader"
UPGRADE.name = "Upgrade All Device"
UPGRADE.desc = "Upgrades ALL of the target player's weapons!"

function UPGRADE:Apply(SWEP)
    function SWEP:OnSuccess(ply)
        for _, wep in ipairs(ply:GetWeapons()) do
            if WEPS.GetClass(wep) == "weapon_ttt_unarmed" then continue end
            TTTPAP:ApplyRandomUpgrade(wep)
        end

        local owner = self:GetOwner()
        owner:SetNWInt("TTTTinkererCharge", owner:GetNWInt("TTTTinkererCharge") - GetConVar("ttt_tinkerer_upgrade_cost"):GetFloat() or 100)
    end
end

TTTPAP:Register(UPGRADE)