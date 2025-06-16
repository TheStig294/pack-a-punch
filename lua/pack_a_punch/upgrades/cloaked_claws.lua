local UPGRADE = {}
UPGRADE.id = "cloaked_claws"
UPGRADE.class = "weapon_wwf_claws"
UPGRADE.name = "Cloaked Claws"
UPGRADE.desc = "Become invisible while held!"
UPGRADE.noCamo = true

function UPGRADE:Apply(SWEP)
    local owner = SWEP:GetOwner()
    if not IsValid(owner) then return end
    owner.TTTPAPCloakedClaws = true
    owner:SetMaterial("sprites/heatwave")
    SWEP.TTTPAPCloakedClawsOwner = owner

    self:AddHook("WeaponEquip", function(wep, ply)
        if WEPS.GetClass(wep) == self.class and ply.TTTPAPCloakedClaws then
            TTTPAP:ApplyUpgrade(wep, self)
        end
    end)

    -- Prevent smuggling the claws into daytime by upgrading them as it changes to day
    self:AddToHook(SWEP, "Think", function()
        if SERVER and not WEREWOLF.isNight then
            SWEP:Remove()
        end
    end)

    self:AddToHook(SWEP, "OnRemove", function()
        if IsValid(SWEP.TTTPAPCloakedClawsOwner) then
            SWEP.TTTPAPCloakedClawsOwner:SetMaterial("")
        end
    end)
end

function UPGRADE:Reset()
    for _, ply in player.Iterator() do
        ply.TTTPAPCloakedClaws = nil
        ply:SetMaterial("")
    end
end

TTTPAP:Register(UPGRADE)