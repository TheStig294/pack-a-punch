-- This file loads all other Pack-a-Punch lua files in the right order
if engine.ActiveGamemode() ~= "terrortown" then return end

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

-- Base functions
AddServer("pack_a_punch/sh_base_functions.lua")
AddClient("pack_a_punch/sh_base_functions.lua")
AddServer("pack_a_punch/sv_base_functions.lua")
AddClient("pack_a_punch/cl_base_functions.lua")
-- UPGRADE object
AddServer("pack_a_punch/sh_upgrade_metatable.lua")
AddClient("pack_a_punch/sh_upgrade_metatable.lua")
-- F1 menu tab
AddClient("pack_a_punch/cl_f1_settings_tab.lua")
-- Weapon upgrades
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