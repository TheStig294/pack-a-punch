local UPGRADE = {}
UPGRADE.id = "remote_paper"
UPGRADE.class = "weapon_mis_proselytizer"
UPGRADE.name = "Remote PAPer"
UPGRADE.desc = "Upgrades all weapons of the player you promote!"

function UPGRADE:Apply(SWEP)
    if CLIENT then return end

    self:AddToHook(SWEP, "OnSuccess", function(ply)
        timer.Simple(0.1, function()
            if not self:IsAlivePlayer(ply) then return end
            TTTPAP:OrderPAP(ply)

            timer.Simple(3.5, function()
                for _, wep in ipairs(ply:GetWeapons()) do
                    TTTPAP:ApplyRandomUpgrade(wep)
                end
            end)
        end)
    end)
end

TTTPAP:Register(UPGRADE)