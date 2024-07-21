local UPGRADE = {}
UPGRADE.id = "soul_powerer"
UPGRADE.class = "weapon_ttt_smg_soulbinding"
UPGRADE.name = "Soul Powerer"
UPGRADE.desc = "All Soulbound abilities are upgraded!"

hook.Add("PostGamemodeLoaded", "TTTPAPSoulPowererPrepareAbilities", function()
    if not SOULBOUND then return end
    SOULBOUND.PAPAbilities = {}

    for id, ABILITY in pairs(SOULBOUND.Abilities) do
        if string.StartsWith(id, "pap_") then
            SOULBOUND.PAPAbilities[id] = ABILITY
            SOULBOUND.Abilities[id] = nil
        end
    end
end)

function UPGRADE:Apply(SWEP)
    -- Take a copy of the soulbound abilities to restore once we're done
    if not SOULBOUND.PAPOldAbilities then
        SOULBOUND.PAPOldAbilities = table.Copy(SOULBOUND.Abilities)
    end

    self:AddToHook(SWEP, "OnSuccess", function(ply, body)
        print(ply, body)
        ply.PAPSoulPowerer = true
    end)
end

function UPGRADE:Reset()
    -- Hopefully restore the Soulbound abilities to what they were
    -- (I've had problems with this in the past with the French randomat restoring old role names to English,
    -- but this is way less complicated than that so it will hopefully *just work*)
    if SOULBOUND.PAPOldAbilities then
        SOULBOUND.Abilities = table.Copy(SOULBOUND.PAPOldAbilities)
    end

    for _, ply in player.Iterator() do
        ply.PAPSoulPowerer = nil
    end
end

TTTPAP:Register(UPGRADE)