local UPGRADE = {}
UPGRADE.id = "perk_vision_aid_active"
UPGRADE.class = "zombies_perk_vultureaid"
UPGRADE.name = "Vision Aid"
UPGRADE.desc = "See weapons and players through walls!"

function UPGRADE:Apply(SWEP)
    if SERVER then
        util.AddNetworkString("TTTPAPVisionAidPerkOutlines")
    end

    SWEP.PAPOldOnDrank = SWEP.OnDrank

    function SWEP:OnDrank()
        self:PAPOldOnDrank()
        local owner = self:GetOwner()

        if IsValid(owner) then
            net.Start("TTTPAPVisionAidPerkOutlines")
            net.Send(owner)
        end
    end

    if CLIENT then
        net.Receive("TTTPAPVisionAidPerkOutlines", function()
            self:AddHook("PreDrawHalos", function()
                local weps = {}

                for _, ent in ipairs(ents.GetAll()) do
                    if not IsValid(ent) then continue end

                    if ent:IsPlayer() or (ent:IsWeapon() and ent.Kind) then
                        table.insert(weps, ent)
                    end
                end

                halo.Add(weps, COLOR_WHITE, 2, 2, 3, true, true)
            end)
        end)
    end
end

TTTPAP:Register(UPGRADE)