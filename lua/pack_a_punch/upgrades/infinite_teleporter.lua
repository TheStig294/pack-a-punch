local UPGRADE = {}
UPGRADE.id = "infinite_teleporter"
UPGRADE.class = "weapon_ttt_teleportgren"
UPGRADE.name = "Infinite Teleporter"
UPGRADE.desc = "Infinite teleport grenades!"

function UPGRADE:Apply(SWEP)
    if CLIENT then return end
    -- Use SWEP.PAPOwner instead of just using self:GetOwner() because it returns NULL in SWEP:OnRemove() on the server...
    SWEP.PAPOwner = SWEP:GetOwner()

    function SWEP:OwnerChanged()
        self.PAPOwner = SWEP:GetOwner()
    end

    local kind = SWEP.Kind

    self:AddHook("PlayerCanPickupWeapon", function(ply, wep)
        if not IsValid(wep) or not IsValid(wep.PAPOwner) or ply ~= wep.PAPOwner then return end
        if wep.Kind and wep.Kind == kind and wep:GetClass() ~= UPGRADE.class then return false end
    end)

    function SWEP:OnRemove()
        local owner = self.PAPOwner
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

    -- Set PaP camo
    self:AddHook("OnEntityCreated", function(ent)
        timer.Simple(0, function()
            if not IsValid(ent) or ent:GetClass() ~= "ttt_teleportgren_proj" then return end
            local owner = ent:GetOwner()
            if not IsValid(owner) then return end
            self:SetUpgraded(ent)
        end)
    end)
end

TTTPAP:Register(UPGRADE)