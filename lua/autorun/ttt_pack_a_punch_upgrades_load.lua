-- This file sets up all the core important logic of the Pack-a-Punch weapon upgrades, as well as loads all other lua files in the right order
-- The global table used by the client and server to access all upgrade data
TTTPAP = {}
TTTPAP.upgrades = {}
TTTPAP.camo = "ttt_pack_a_punch/pap_camo"
TTTPAP.convars = {}
-- Creating a fake class of "UPGRADE" using metatables, borrowed from the randomat's "EVENT" class
local pap_meta = {}
pap_meta.__index = pap_meta

function pap_meta:Apply(SWEP)
end

function pap_meta:Condition()
    return true
end

-- Store every weapon upgrade first by the weapon's classname, then the id of each upgrade for that weapon, e.g:
-- Upgrades = {
--    weapon_1 = {
--        upgrade_1,
--        upgrade_2
--    },
--    weapon_2 = {
--        upgrade_1
--    }
--}
function RegisterPAPUpgrade(upgrade)
    TTTPAP.upgrades[upgrade.classname] = TTTPAP.upgrades[upgrade.classname] or {}
    TTTPAP.upgrades[upgrade.classname][upgrade.id] = upgrade
end

-- These 2 functions are from Malivil's randomat mod, to save having to come up with a unique ID for a hook every time...
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

-- Reading all weapon upgrade lua files
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
local files, _ = file.Find("pack_a_punch/upgrades/*.lua", "LUA")

for _, fil in ipairs(files) do
    AddServer("pack_a_punch/upgrades/" .. fil)
    AddClient("pack_a_punch/upgrades/" .. fil)
end