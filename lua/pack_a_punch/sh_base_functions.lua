-- 
-- TTTPAP functions and core logic
-- 
-- The global table/namespace used by the client and server to access all upgrade data
TTTPAP = {}
TTTPAP.upgrades = {}
TTTPAP.genericUpgrades = {}
TTTPAP.activeUpgrades = {}
TTTPAP.camo = "ttt_pack_a_punch/pap_camo"
TTTPAP.shootSound = Sound("ttt_pack_a_punch/shoot.mp3")
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
    else
        TTTPAP.genericUpgrades[UPGRADE.id] = TTTPAP.genericUpgrades[UPGRADE.id] or {}
        TTTPAP.genericUpgrades[UPGRADE.id] = UPGRADE
    end

    -- Create enable/disable convar
    cvarName = "ttt_pap_" .. UPGRADE.id

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

-- Allowing PAP convars to be changed from the client, if the player is an admin
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

-- Resetting all active weapon upgrade logic, at the start of each round
hook.Add("TTTPrepareRound", "TTTPAPResetAll", function()
    if TTTPAP.activeUpgrades ~= {} then
        for _, UPGRADE in pairs(TTTPAP.activeUpgrades) do
            UPGRADE:Reset()
            UPGRADE:CleanUpHooks()
        end

        TTTPAP.activeUpgrades = {}
    end
end)

-- Preventing the Pack-a-Punch from being bought when it shouldn't be
function TTTPAP:CanOrderPAP(ply, displayErrorMessage)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    local SWEP = ply:GetActiveWeapon()
    local class = SWEP:GetClass()
    local upgrades = TTTPAP.upgrades[class]

    if not IsValid(SWEP) then
        -- Preventing purchase if the currently held weapon is invalid
        if displayErrorMessage then
            ply:PrintMessage(HUD_PRINTCENTER, "Invalid weapon, try again")
            ply:PrintMessage(HUD_PRINTTALK, "Invalid weapon, try again")
        end

        return false
    elseif not upgrades and (not SWEP.AutoSpawnable or not GetConVar("ttt_pap_apply_generic_upgrades"):GetBool()) then
        -- Preventing purchase if held weapon is not a floor weapon or generic upgrades are turned off, and the weapon has no PaP upgrade
        if displayErrorMessage then
            ply:PrintMessage(HUD_PRINTCENTER, "Held weapon can't be upgraded")
            ply:PrintMessage(HUD_PRINTTALK, "Weapon has no upgrade made for it :(")
        end

        return false
    elseif upgrades then
        -- Preventing purchase if all upgrades' condition functions return false or all have their convars disabled
        for id, UPGRADE in pairs(upgrades) do
            -- If even one upgrade's condition returns true, and its convar is on, we're good, return out of printing an error
            if UPGRADE:Condition() and GetConVar("ttt_pap_" .. UPGRADE.id):GetBool() then return true end
        end

        if displayErrorMessage then
            ply:PrintMessage(HUD_PRINTCENTER, "Held weapon can't be upgraded")
            ply:PrintMessage(HUD_PRINTTALK, "The weapon you're holding out can't be upgraded")
        end

        return false
    elseif not upgrades then
        -- Preventing purchase if all generic upgrades' condition functions return false or all have had their convars disabled
        for id, UPGRADE in pairs(TTTPAP.genericUpgrades) do
            -- If even one generic upgrade's condition returns true, and its convar is on, we're good, return out of printing an error
            if UPGRADE:Condition() and GetConVar("ttt_pap_" .. UPGRADE.id):GetBool() then return true end
        end

        if displayErrorMessage then
            ply:PrintMessage(HUD_PRINTCENTER, "Held weapon can't be upgraded")
            ply:PrintMessage(HUD_PRINTTALK, "The weapon you're holding out can't be upgraded")
        end

        return false
    end

    return true
end

-- Credit to Malivil for this force-switch hook for TFA weapons
-- If we're switching from a TFA weapon to the holstered when upgrading a weapon, JUST DO IT!
-- The holster animation causes a delay where the client is not allowed to switch weapons
-- This means if we tell the user to select a weapon and then block the user from switching weapons immediately after,
-- the holster animation delay will cause the player to not select the weapon we told them to
hook.Add("TFA_PreHolster", "TTTPAPUpgradeBlockTFAAutoWeaponSwitch", function(wep, target)
    if not IsValid(wep) or not IsValid(target) then return end
    local owner = wep:GetOwner()
    if not IsPlayer(owner) or not owner:GetNWBool("TTTPAPIsUpgrading") then return end
    if WEPS.GetClass(target) == "weapon_ttt_unarmed" then return true end
end)