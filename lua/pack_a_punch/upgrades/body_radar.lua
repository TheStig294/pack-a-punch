local UPGRADE = {}
UPGRADE.id = "body_radar"
UPGRADE.class = "weapon_ttt_deadtector"
UPGRADE.name = "Body Radar"
UPGRADE.desc = "Highlights unsearched bodies through walls!"

function UPGRADE:Apply(SWEP)
    if SERVER then return end
    local client = LocalPlayer()
    local bodies = {}

    timer.Create("TTTPAPBodyRadar", 1, 0, function()
        bodies = {}

        if not IsValid(client) then
            client = LocalPlayer()

            return
        end

        if not self:IsValidUpgrade(client:GetActiveWeapon()) then return end

        for _, ent in ipairs(ents.FindByClass("prop_ragdoll")) do
            if IsValid(CORPSE.GetPlayer(ent)) and not CORPSE.GetFound(ent) then
                table.insert(bodies, ent)
            end
        end
    end)

    self:AddHook("PreDrawHalos", function()
        halo.Add(bodies, color_white, 1, 1, 2, true, true)
    end)
end

function UPGRADE:Reset()
    if SERVER then return end
    timer.Remove("TTTPAPBodyRadar")
end

TTTPAP:Register(UPGRADE)