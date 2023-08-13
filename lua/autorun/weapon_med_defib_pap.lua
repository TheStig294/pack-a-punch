TTT_PAP_UPGRADES = TTT_PAP_UPGRADES or {}

local canBecomeMedCvar = CreateConVar("ttt_pap_paramedic_device_can_become_paramedic", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Allow revived players to become paramedics")

local class = "weapon_med_defib"
TTT_PAP_CONVARS[class] = {}

table.insert(TTT_PAP_CONVARS[class], {
    name = "ttt_pap_paramedic_device_can_become_paramedic",
    type = "bool"
})

TTT_PAP_UPGRADES.weapon_med_defib = {
    name = "Special Innocent Defib",
    desc = "Turns innocents into non-vanilla innocents!",
    func = function(SWEP)
        if SERVER then
            hook.Add("TTTPlayerRoleChangedByItem", "TTTPAPParamedicDevice", function(owner, ply, wep)
                -- Check it is the PaPed paramedic device
                if wep:GetClass() ~= "weapon_med_defib" or not wep:GetNWBool("IsPackAPunched") then return end
                -- Vanilla innocents and detectives are revived as special innocents
                if ply:GetRole() ~= ROLE_INNOCENT and not ply:IsDetectiveTeam() then return end
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
}