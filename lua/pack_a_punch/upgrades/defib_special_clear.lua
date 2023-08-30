local UPGRADE = {}
UPGRADE.id = "defib_special_clear"
UPGRADE.class = "weapon_clearrandomat_defib"
UPGRADE.name = "Special Innocent Defib"
UPGRADE.desc = "Turns innocents into non-vanilla innocents!"

UPGRADE.convars = {
    {
        name = "pap_defib_special_clear_can_become_paramedic",
        type = "bool"
    }
}

local canBecomeMedCvar = CreateConVar("pap_defib_special_clear_can_become_paramedic", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Allow revived players to become paramedics")

function UPGRADE:Apply()
    if SERVER then
        -- Getting the list of all enabled innocent roles
        local enabledInnocentRoles = {}
        local allowParamedic = canBecomeMedCvar:GetBool()

        for role, roleString in pairs(ROLE_STRINGS_RAW) do
            if INNOCENT_ROLES[role] and not DETECTIVE_ROLES[role] and ConVarExists("ttt_" .. roleString .. "_enabled") and GetConVar("ttt_" .. roleString .. "_enabled"):GetBool() then
                -- Don't allow PaP paramedic device to turn other players into paramedics if the convar is disabled
                if not allowParamedic and role == ROLE_PARAMEDIC then continue end
                table.insert(enabledInnocentRoles, role)
            end
        end

        self:AddHook("TTTPlayerRoleChangedByItem", function(_, ply, wep)
            -- Check it is the PaPed paramedic device
            if wep:GetClass() ~= self.class or not wep.PAPUpgrade then return end
            -- Vanilla innocents and detectives are revived as special innocents
            if ply:GetRole() ~= ROLE_INNOCENT and not ply:IsDetectiveTeam() then return end
            -- If only the paramedic is enabled out of all special innocent roles,
            -- and turning other players into paramedics is disabled, then the enabled innocent roles table will be empty,
            -- so we return here to avoid errors
            if table.IsEmpty(enabledInnocentRoles) then return end
            local randomRole = enabledInnocentRoles[math.random(#enabledInnocentRoles)]

            timer.Simple(0.1, function()
                ply:SetRole(randomRole)
                SendFullStateUpdate()
            end)
        end)
    end
end

TTTPAP:Register(UPGRADE)