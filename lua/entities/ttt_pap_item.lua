-- 
-- Creating the Pack-a-Punch passive item (It's here in the entities folder because else there's issues syncing the same item id between client and server)
-- 
if TTT2 then return end
AddCSLuaFile()

-- Convars to turn off detective/traitor being able to buy the Pack-a-Punch for vanilla TTT (Custom Roles users can just use the role weapons system)
CreateConVar("ttt_pap_detective", 1, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Detectives can buy PaP (Requires map change)", 0, 1)

CreateConVar("ttt_pap_traitor", 1, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Traitors can buy PaP (Requires map change)", 0, 1)

if CLIENT then
    LANG.AddToLanguage("english", "pap_name", "Pack-A-Punch")
    LANG.AddToLanguage("english", "pap_desc", "Upgrades your held weapon!\n\nHold out the weapon you want to upgrade in your hands, then buy this item!")
end

EQUIP_PAP = GenerateNewEquipmentID and GenerateNewEquipmentID() or 2048

local pap = {
    id = EQUIP_PAP,
    loadout = false,
    type = "item_passive",
    material = "vgui/ttt/ttt_pack_a_punch.png",
    name = "pap_name",
    desc = "pap_desc"
}

-- Prevent roles from getting the PaP in their buy menu that shouldn't
local bannedRoles = {}

if not GetConVar("ttt_pap_detective"):GetBool() then
    bannedRoles[ROLE_DETECTIVE] = true
end

if not GetConVar("ttt_pap_traitor"):GetBool() then
    bannedRoles[ROLE_TRAITOR] = true
end

-- Would be too powerful
if ROLE_ASSASSIN then
    bannedRoles[ROLE_ASSASSIN] = true
end

-- Is supposed to have just randomats to buy
if ROLE_RANDOMAN then
    bannedRoles[ROLE_RANDOMAN] = true
end

-- For some reason the PaP is becoming buyable for the Jester/Swapper even though they aren't shop roles?
-- SHOP_ROLES[ROLE_JESTER]/SHOP_ROLES[ROLE_SWAPPER] is true
if ROLE_JESTER then
    bannedRoles[ROLE_JESTER] = true
end

if ROLE_SWAPPER then
    bannedRoles[ROLE_SWAPPER] = true
end

-- Mad scientist has the death radar but no basic shop items so it probably shouldn't have the PaP by default
if ROLE_MADSCIENTIST then
    bannedRoles[ROLE_MADSCIENTIST] = true
end

-- Check that the PaP item hasn't been added already
local function HasItemWithPropertyValue(tbl, key, val)
    if not tbl or not key then return end

    for _, v in pairs(tbl) do
        if v[key] and v[key] == val then return true end
    end

    return false
end

-- Add the PaP to every role's buy menu that isn't banned
hook.Add("TTTBeginRound", "TTTPAPRegister", function()
    for role, equTable in pairs(EquipmentItems) do
        -- Check:
        -- Role is not banned
        -- Role doesn't already have the PaP
        -- CR is not installed, or role has a shop
        if not bannedRoles[role] and not HasItemWithPropertyValue(EquipmentItems[role], "id", EQUIP_PAP) and (not SHOP_ROLES or SHOP_ROLES[role]) then
            table.insert(equTable, pap)
        end
    end

    hook.Remove("TTTBeginRound", "TTTPAPRegister")
end)

-- Preventing the Pack-a-Punch from being bought when it shouldn't be
hook.Add("TTTCanOrderEquipment", "TTTPAPPrePurchase", function(ply, equipment, is_item)
    -- Set the displaying of error messages to players to true
    if is_item and math.floor(equipment) == EQUIP_PAP then return TTTPAP:CanOrderPAP(ply, true) end
end)

-- After TTTCanOrderEquipment is called and the weapon is in fact upgradable, find an upgrade for the weapon and apply it!
hook.Add("TTTOrderedEquipment", "TTTPAPPurchase", function(ply, equipment, _)
    if equipment == EQUIP_PAP then
        -- Set skip can upgrade check to true, as this was just done in the TTTCanOrderEquipment hook
        TTTPAP:OrderPAP(ply, true)
    end
end)