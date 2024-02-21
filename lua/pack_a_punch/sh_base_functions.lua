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

    -- Manually define player:IsAdmin() for TTT2
    local function IsAdmin(ply)
        if not IsValid(ply) or not ply:IsPlayer() then return false end
        local userGroup = ply:GetNWString("UserGroup", "user")

        if userGroup == "superadmin" or userGroup == "admin" then
            return true
        else
            return false
        end
    end

    net.Receive("TTTPAPChangeConvar", function(_, ply)
        if not IsAdmin(ply) then return end
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

    if not IsValid(SWEP) then
        -- Preventing purchase if the currently held weapon is invalid
        if displayErrorMessage then
            ply:PrintMessage(HUD_PRINTCENTER, "Invalid weapon, try again")
            ply:PrintMessage(HUD_PRINTTALK, "[Pack-a-Punch] Invalid weapon, try again")
        end

        return false
    end

    local class = SWEP:GetClass()
    local upgrades = TTTPAP.upgrades[class]

    if SWEP.PAPUpgrade then
        -- Preventing purchase if the currently held weapon is already upgraded
        if displayErrorMessage then
            ply:PrintMessage(HUD_PRINTCENTER, "Weapon already upgraded")
            ply:PrintMessage(HUD_PRINTTALK, "[Pack-a-Punch] That weapon is already upgraded")
        end

        return false
    elseif not upgrades and (not SWEP.AutoSpawnable or SWEP.Kind == WEAPON_NADE or not GetConVar("ttt_pap_apply_generic_upgrades"):GetBool()) then
        -- Preventing purchase if held weapon is either not a floor weapon, is a grenade, or generic upgrades are turned off, and the weapon has no PaP upgrade
        if displayErrorMessage then
            ply:PrintMessage(HUD_PRINTCENTER, "Held weapon can't be upgraded")
            ply:PrintMessage(HUD_PRINTTALK, "[Pack-a-Punch] Weapon has no upgrade made for it :(")
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
            ply:PrintMessage(HUD_PRINTTALK, "[Pack-a-Punch] Upgrade disabled, or the required mod for this upgrade isn't installed on the server")
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
            ply:PrintMessage(HUD_PRINTTALK, "[Pack-a-Punch] Upgrade disabled, or the required mod for this upgrade isn't installed on the server")
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

-- Credit to Hoff for the original PlayerCanPickupWeapon hook
-- The original intention of this hook is to prevent players from having more than 4 perks at a time, and not allow a player to try to drink more than 1 perk at a time
-- However, there is currently a bug where the flag "bIsDrinkingPerk" is never cleared if the player's perk bottle is removed mid-drink
-- Therefore, the player is then unable to pickup any new weapons until the map changes
-- So we simply allow the player to pickup the perk bottle if they are upgrading a weapon (TTTPAPIsUpgrading NWBool from TTTPAP:OrderPAP()), which eventually removes the "bIsDrinkingPerk" flag when they finish drinking
hook.Add("InitPostEntity", "TTTPAPOverrideHoffPerkBottleHook", function()
    hook.Add("PlayerCanPickupWeapon", "CanGetPerk", function(ply, weapon)
        if ply:GetNWBool("TTTPAPIsUpgrading") then return end
        if ply:HasWeapon(weapon:GetClass()) and string.match(weapon:GetClass(), "zombies_perk_") then return false end
        local activeWeapon = ply:GetActiveWeapon()
        if ply:HasWeapon(weapon:GetClass()) or IsValid(ply) and IsValid(activeWeapon) and string.match(activeWeapon:GetClass(), "zombies_perk_") then return false end
        if ply:GetNWBool("bIsDrinkingPerk") then return false end

        if string.match(weapon:GetClass(), "zombies_perk_") then
            local PerkLimit = ConVarExists("Perks_PerkLimit") and GetConVar("Perks_PerkLimit"):GetInt() or 0
            local PerkTable = {}

            if ply:GetNWString("PerkTable") and #ply:GetNWString("PerkTable") > 0 then
                PerkTable = string.Explode(",", ply:GetNWString("PerkTable"))
            end

            if PerkLimit > 0 and table.Count(PerkTable) >= PerkLimit then return false end
        end
    end)
end)

-- Credit to Malivil for this function to add compatibility with Custom Roles role packs
function TTTPAP:CanRoleSpawn(role)
    if not role or role == -1 then return false end
    if util.CanRoleSpawn then return util.CanRoleSpawn(role) end
    if role == ROLE_DETECTIVE or role == ROLE_INNOCENT or role == ROLE_TRAITOR then return true end

    if ROLE_STRINGS_RAW then
        local cvar = "ttt_" .. ROLE_STRINGS_RAW[role] .. "_enabled"

        return ConVarExists(cvar) and GetConVar(cvar):GetBool()
    end

    return false
end