-- 
-- TTTPAP functions and core logic
-- 
-- The global table/namespace used by the client and server to access all upgrade data
TTTPAP = {}
TTTPAP.upgrades = {}
TTTPAP.genericUpgrades = {}
TTTPAP.activeUpgrades = {}
TTTPAP.camo = "ttt_pack_a_punch/pap_camo"
TTTPAP.upgrade_meta = {} -- Set by sh_upgrade_metatable.lua

-- Create convar to disable trying to apply generic upgrades on weapons without one
CreateConVar("ttt_pap_apply_generic_upgrades", 1, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Weapons without upgrades will *try* to be upgraded with a random \"generic\" upgrade (Normally a stats upgrade)", 0, 1)

-- Convars to turn off detective/traitor being able to buy the Pack-a-Punch for vanilla TTT (Custom Roles users can just use the role weapons system)
CreateConVar("ttt_pap_detective", 1, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Detectives can buy PaP (Requires map change)", 0, 1)

CreateConVar("ttt_pap_traitor", 1, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Traitors can buy PaP (Requires map change)", 0, 1)

local PAPConvars = {
    ttt_pap_apply_generic_upgrades = true,
    ttt_pap_detective = true,
    ttt_pap_traitor = true
}

-- Store every weapon upgrade first by the weapon's classname, then the id of each upgrade for that weapon, e.g:
-- Upgrades = {
--    weapon_1_class = {
--        upgrade_1_id = {...},
--        upgrade_2_id = {...}
--    },
--    weapon_2_class = {
--        upgrade_1_id = {...}
--    }
--}
function TTTPAP:Register(UPGRADE)
    setmetatable(UPGRADE, TTTPAP.upgrade_meta)
    local cvarName

    -- Register to TTTPAP.upgrades, or TTTPAP.genericUpgrades if no base weapon to apply to upgrade is defined
    if UPGRADE.class then
        TTTPAP.upgrades[UPGRADE.class] = TTTPAP.upgrades[UPGRADE.class] or {}
        TTTPAP.upgrades[UPGRADE.class][UPGRADE.id] = UPGRADE
        -- Create enable/disable convar
        cvarName = "ttt_pap_" .. UPGRADE.class .. "_" .. UPGRADE.id
    else
        TTTPAP.genericUpgrades[UPGRADE.id] = TTTPAP.genericUpgrades[UPGRADE.id] or {}
        TTTPAP.genericUpgrades[UPGRADE.id] = UPGRADE
        cvarName = "ttt_pap_" .. UPGRADE.id
    end

    CreateConVar(cvarName, 1, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED})

    -- Add convar to the list of allowed to be changed convars by the "TTTPAPChangeConvar" net message
    PAPConvars[cvarName] = true

    -- Also add any custom convar settings the upgrade may have
    if UPGRADE.convars then
        for _, cvarInfo in ipairs(UPGRADE.convars) do
            PAPConvars[cvarInfo.name] = true
        end
    end
end

if SERVER then
    util.AddNetworkString("TTTPAPChangeConvar")

    net.Receive("TTTPAPChangeConvar", function(_, ply)
        if not ply:IsAdmin() then return end
        local cvarName = net.ReadString()
        -- Don't allow non-PAP convars to be changed by this net message
        if not PAPConvars[cvarName] then return end
        local value = net.ReadString()

        if ConVarExists(cvarName) then
            GetConVar(cvarName):SetString(value)
        end
    end)
end

hook.Add("TTTPrepareRound", "TTTPAPResetAll", function()
    if TTTPAP.activeUpgrades ~= {} then
        for _, UPGRADE in pairs(TTTPAP.activeUpgrades) do
            UPGRADE:Reset()
            UPGRADE:CleanUpHooks()
        end

        TTTPAP.activeUpgrades = {}
    end
end)