TTT_PAP_UPGRADES = TTT_PAP_UPGRADES or {}

local canBecomeHypCvar = CreateConVar("ttt_pap_hypnotist_device_can_become_hypnotist", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Allow revived players to become hypnotists")

local class = "weapon_hyp_brainwash"
TTTPAP.convars[class] = {}

table.insert(TTTPAP.convars[class], {
    name = "ttt_pap_hypnotist_device_can_become_hypnotist",
    type = "bool"
})

TTT_PAP_UPGRADES.weapon_hyp_brainwash = {
    name = "Brain Cleansing Device",
    desc = "Turns players into non-vanilla traitors!",
    func = function(SWEP)
        if SERVER then
            hook.Add("TTTPlayerRoleChangedByItem", "TTTPAPHypnotistDevice", function(owner, ply, wep)
                -- Check it is the PaPed hypnotist device
                if wep:GetClass() ~= "weapon_hyp_brainwash" or not wep:GetNWBool("IsPackAPunched") then return end
                -- Getting the list of all enabled traitor roles
                local enabledTraitorRoles = {}
                local allowHypnotist = canBecomeHypCvar:GetBool()

                for role, roleString in pairs(ROLE_STRINGS_RAW) do
                    if TRAITOR_ROLES[role] and ConVarExists("ttt_" .. roleString .. "_enabled") and GetConVar("ttt_" .. roleString .. "_enabled"):GetBool() then
                        -- Don't allow PaP hypnotist device to turn other players into hypnotists if the convar is disabled
                        if not allowHypnotist and role == ROLE_HYPNOTIST then continue end
                        table.insert(enabledTraitorRoles, role)
                    end
                end

                -- If only the hypnotist is enabled out of all special traitor roles,
                -- and turning other players into hypnotists is disabled, then the enabled traitor roles table will be empty,
                -- so we return here to avoid errors
                if table.IsEmpty(enabledTraitorRoles) then return end
                local randomRole = enabledTraitorRoles[math.random(#enabledTraitorRoles)]

                timer.Simple(0.1, function()
                    ply:SetRole(randomRole)
                    SendFullStateUpdate()
                end)
            end)
        end
    end
}