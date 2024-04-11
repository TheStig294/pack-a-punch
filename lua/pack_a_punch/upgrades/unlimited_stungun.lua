local UPGRADE = {}
UPGRADE.id = "unlimited_stungun"
UPGRADE.class = "stungun"
UPGRADE.name = "Unlimited Stungun"
UPGRADE.desc = "Unlimited ammo!"

function UPGRADE:Apply(SWEP)
    self:AddHook("Think", function()
        for _, ply in pairs(player.GetAll()) do
            local wep = ply:GetActiveWeapon()

            if IsValid(wep) and wep.PAPUpgrade and wep.PAPUpgrade.id == self.id then
                wep:SetClip1(wep.Primary.ClipSize)
            end
        end
    end)
end

TTTPAP:Register(UPGRADE)