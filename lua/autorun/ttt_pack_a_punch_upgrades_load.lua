if engine.ActiveGamemode() ~= "terrortown" then return end
-- This file sets up all the core important logic of the Pack-a-Punch weapon upgrades, as well as loads all other lua files in the right order
-- The global table used by the client and server to access all upgrade data
TTTPAP = {}
TTTPAP.upgrades = {}
TTTPAP.genericUpgrades = {}
TTTPAP.activeUpgrades = {}
TTTPAP.camo = "ttt_pack_a_punch/pap_camo"
-- 
-- Creating a fake class of "UPGRADE" using metatables, borrowed from the randomat's "EVENT" class
-- 
local pap_meta = {}
pap_meta.__index = pap_meta
-- Initialising default stats multipliers
pap_meta.firerateMult = 1
pap_meta.damageMult = 1
pap_meta.spreadMult = 1
pap_meta.ammoMult = 1
pap_meta.recoilMult = 1

function pap_meta:Condition()
    return true
end

function pap_meta:Apply()
end

function pap_meta:Reset()
end

-- These 3 functions are from Malivil's randomat mod, to save having to come up with a unique ID for a hook every time...
function pap_meta:AddHook(hooktype, callbackfunc, suffix)
    callbackfunc = callbackfunc or self[hooktype]
    local id = "TTTPAP." .. self.id .. ":" .. hooktype

    if suffix and type(suffix) == "string" and #suffix > 0 then
        id = id .. ":" .. suffix
    end

    hook.Add(hooktype, id, function(...) return callbackfunc(...) end)
    self.Hooks = self.Hooks or {}

    table.insert(self.Hooks, {hooktype, id})
end

function pap_meta:RemoveHook(hooktype, suffix)
    local id = "TTTPAP." .. self.id .. ":" .. hooktype

    if suffix and type(suffix) == "string" and #suffix > 0 then
        id = id .. ":" .. suffix
    end

    for idx, ahook in ipairs(self.Hooks or {}) do
        if ahook[1] == hooktype and ahook[2] == id then
            hook.Remove(ahook[1], ahook[2])
            table.remove(self.Hooks, idx)

            return
        end
    end
end

function pap_meta:CleanUpHooks()
    if not self.Hooks then return end

    for _, ahook in ipairs(self.Hooks) do
        hook.Remove(ahook[1], ahook[2])
    end

    table.Empty(self.Hooks)
end

function pap_meta:GetAlivePlayers(shuffle)
    local plys = {}

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() and ply:IsSpec() then
            table.insert(plys, ply)
        end
    end

    if shuffle then
        table.Shuffle(plys)
    end

    return plys
end

-- 
-- TTTPAP functions and core hook/convar logic
-- 
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
    local cvarName
    setmetatable(UPGRADE, pap_meta)

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

-- 
-- Loading all UPGRADE object lua files and Pack-a-Punch base code
-- 
local function AddServer(fil)
    if SERVER then
        include(fil)
    end
end

local function AddClient(fil)
    if SERVER then
        AddCSLuaFile(fil)
    end

    if CLIENT then
        include(fil)
    end
end

AddServer("pack_a_punch/sh_pap_base.lua")
AddClient("pack_a_punch/sh_pap_base.lua")
AddClient("pack_a_punch/cl_pap_f1_settings_tab.lua")
local genericFiles, _ = file.Find("pack_a_punch/generic_upgrades/*.lua", "LUA")

for _, fil in ipairs(genericFiles) do
    AddServer("pack_a_punch/generic_upgrades/" .. fil)
    AddClient("pack_a_punch/generic_upgrades/" .. fil)
end

local files, _ = file.Find("pack_a_punch/upgrades/*.lua", "LUA")

for _, fil in ipairs(files) do
    AddServer("pack_a_punch/upgrades/" .. fil)
    AddClient("pack_a_punch/upgrades/" .. fil)
end