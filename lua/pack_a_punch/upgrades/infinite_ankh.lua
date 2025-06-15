local UPGRADE = {}
UPGRADE.id = "infinite_ankh"
UPGRADE.class = "weapon_phr_ankh"
UPGRADE.name = "Infinite Ankh"
UPGRADE.desc = "Unlimited respawns!\n(So long as it's not destroyed...)"

function UPGRADE:Apply(SWEP)
    self:AddToHook(SWEP, "PrimaryAttack", function()
        local owner = SWEP:GetOwner()
        if not IsValid(owner) then return end
        local vm = owner:GetViewModel()
        if not IsValid(vm) then return end

        timer.Simple(SWEP:SequenceDuration() + 0.1, function()
            local ankh = owner.PharaohAnkh
            if not IsValid(ankh) then return end
            ankh:SetPAPCamo()
            ankh.OGDestroyAnkh = ankh.DestroyAnkh
            ankh.TTTPAPInfiniteAnkh = true

            function ankh:DestroyAnkh()
                if self:Health() <= 0 then
                    ankh:OGDestroyAnkh()
                end
            end
        end)
    end)

    self:AddHook("FindUseEntity", function(ply, ent)
        if ent.TTTPAPInfiniteAnkh then
            ply.TTTPAPInfiniteAnkh = true
        end
    end)

    self:AddHook("WeaponEquip", function(wep, ply)
        if ply.TTTPAPInfiniteAnkh then
            TTTPAP:ApplyUpgrade(wep, self)
            ply.TTTPAPInfiniteAnkh = nil
        end
    end)
end

function UPGRADE:Reset()
    for _, ply in player.Iterator() do
        ply.TTTPAPInfiniteAnkh = nil
    end
end

TTTPAP:Register(UPGRADE)