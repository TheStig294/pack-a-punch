local UPGRADE = {}
UPGRADE.id = "infinite_teleporter"
UPGRADE.class = "weapon_ttt_teleportgren"
UPGRADE.name = "Infinite Teleporter"
UPGRADE.desc = "Infinite teleport grenades!"

function UPGRADE:Apply(SWEP)
    if CLIENT then return end
    local owner = SWEP:GetOwner()

    function SWEP:OwnerChanged()
        owner = SWEP:GetOwner()
    end

    local kind = SWEP.Kind

    self:AddHook("PlayerCanPickupWeapon", function(ply, wep)
        if not IsValid(owner) or ply ~= owner then return end
        if wep.Kind and wep.Kind == kind and wep:GetClass() ~= UPGRADE.class then return false end
    end)

    function SWEP:OnRemove()
        if not IsValid(owner) then return end

        timer.Simple(0.1, function()
            for _, wep in ipairs(owner:GetWeapons()) do
                if wep.Kind == kind and wep ~= self then
                    wep:Remove()
                end
            end

            local newWep = owner:Give(UPGRADE.class)
            local newUPGRADE = UPGRADE
            newUPGRADE.noDesc = true
            TTTPAP:ApplyUpgrade(newWep, UPGRADE)
            owner:SelectWeapon(UPGRADE.class)
        end)
    end

    -- Add PAP camo
    self:AddToHook("")
end

TTTPAP:Register(UPGRADE)