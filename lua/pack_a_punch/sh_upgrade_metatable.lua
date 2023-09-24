-- 
-- Creating a fake "UPGRADE" class using metatables, borrowed from the randomat's "EVENT" class
-- 
local UPGRADE = {}
UPGRADE.__index = UPGRADE
-- Basic properties
UPGRADE.id = nil -- Unique ID name of the upgrade, required. Try to not use the weapon's classname, as other upgrades might use this
UPGRADE.class = nil -- Classname of the weapon the upgrade is for, nil designates the upgrade as a "Generic upgrade" that can be applied to any basic weapon
UPGRADE.name = nil -- Displayed SWEP.PrintName of the upgrade weapon
UPGRADE.desc = nil -- Displayed in chat, upgrade description on receiving the upgraded weapon
UPGRADE.convars = nil -- Table of convar info tables, format:
-- convars = {
--    {
--        name = ConVar name,
--        type = ConVar variable type (bool, int, float or string),
--        decimals = No. of decimals the convar value slider should have in the F1 tab
--    },
--    {
--        ...
--    },
--    ...
--}
-- Weapon stats
UPGRADE.firerateMult = 1 -- Firerate
UPGRADE.damageMult = 1 -- Damage
UPGRADE.spreadMult = 1 -- Inverse of accuracy
UPGRADE.ammoMult = 1 -- Ammo
UPGRADE.recoilMult = 1 -- Weapon recoil
UPGRADE.automatic = nil -- Automatic fire, a true/false value overrides the weapon's default
-- Upgrade options
UPGRADE.noSelectWep = nil -- Prevents the upgraded weapon from being automatically selected after it is given
UPGRADE.newClass = nil -- Defines a different weapon SWEP to be given instead of the same one when a weapon is upgraded
UPGRADE.noCamo = nil -- Prevents the upgrade camo from being applied to the weapon
UPGRADE.noSound = nil -- Prevents the PAP shoot sound from being applied

-- If false, prevents the upgrade from being applied. Mainly used for checking if the upgrade's required mods are installed on the server
function UPGRADE:Condition()
    return true
end

-- The function responsible for upgrading the weapon, run when the weapon should be upgraded
function UPGRADE:Apply(SWEP)
end

-- Run the next time TTTPrepareRound is called to reset any data or anything that needs cleaning up that the weapon upgrade affected
function UPGRADE:Reset()
end

-- These functions are from Malivil's randomat mod, where hooks passed are automatically given an appropriate hook id and are removed the next time TTTPrepareRound is called
-- Upgrade functions use self:AddHook(), self:RemoveHook() and self:AddCleanupHooks() are used in sh_base_functions.lua to clean up the hooks at the end of the round
function UPGRADE:AddHook(hooktype, callbackfunc, suffix)
    callbackfunc = callbackfunc or self[hooktype]
    local id = "TTTPAP." .. self.id .. ":" .. hooktype

    if suffix and type(suffix) == "string" and #suffix > 0 then
        id = id .. ":" .. suffix
    end

    hook.Add(hooktype, id, function(...) return callbackfunc(...) end)
    self.Hooks = self.Hooks or {}

    table.insert(self.Hooks, {hooktype, id})
end

function UPGRADE:RemoveHook(hooktype, suffix)
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

function UPGRADE:CleanUpHooks()
    if not self.Hooks then return end

    for _, ahook in ipairs(self.Hooks) do
        hook.Remove(ahook[1], ahook[2])
    end

    table.Empty(self.Hooks)
end

-- Utility functions available inside any UPGRADE function, usually used in UPGRADE:Apply()
function UPGRADE:GetAlivePlayers(shuffle)
    local plys = {}

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() and not ply:IsSpec() then
            table.insert(plys, ply)
        end
    end

    if shuffle then
        table.Shuffle(plys)
    end

    return plys
end

local ForceSetPlayermodel = FindMetaTable("Entity").SetModel

function UPGRADE:SetModel(ply, model)
    ForceSetPlayermodel(ply, model)
end

function UPGRADE:IsPlayer(ply)
    return IsValid(ply) and ply:IsPlayer()
end

function UPGRADE:IsAlive(ply)
    return ply:Alive() and not ply:IsSpec()
end

function UPGRADE:IsAlivePlayer(ply)
    return self:IsPlayer(ply) and self:IsAlive(ply)
end

-- Making the metatable accessible to the base code by placing it in the TTTPAP namespace
TTTPAP.upgrade_meta = UPGRADE