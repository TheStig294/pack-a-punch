-- 
-- Creating the Pack-a-Punch passive item (It's here in the entities folder because else there's issues syncing the same item id between client and server)
-- 
if TTT2 or engine.ActiveGamemode() ~= "terrortown" then return end
AddCSLuaFile()

-- Convars to turn off detective/traitor being able to buy the Pack-a-Punch for vanilla TTT (Custom Roles users can just use the role weapons system)
local detectiveCvar = CreateConVar("ttt_pap_detective", 1, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Detectives can buy PaP (Requires map change)", 0, 1)

local traitorCvar = CreateConVar("ttt_pap_traitor", 1, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Traitors can buy PaP (Requires map change)", 0, 1)

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

-- Faker breaks by spending a credit without being able to get one back
-- Randoman is supposed to have just randomats to buy (I recommend adding: ttt_randoman_guaranteed_randomats "papupgrade" to your server config instead)
-- Jester/Swapper are shop roles because of an old request to let them have buyable items that pre-dates the role weapons system, which hasn't been removed for some reason
-- Hive Mind's buy menu is supposed to start empty
-- The Renegade is marked as a buy menu role despite not having anything in the shop by default
local bannedRoles = {ROLE_FAKER, ROLE_RANDOMAN, ROLE_JESTER, ROLE_SWAPPER, ROLE_HIVEMIND, ROLE_RENEGADE}

if not detectiveCvar:GetBool() then
    table.insert(bannedRoles, ROLE_DETECTIVE)
end

if not traitorCvar:GetBool() then
    table.insert(bannedRoles, ROLE_TRAITOR)
end

local bannedRolesDictionary = {}

-- Not a sequential table, unless all banned roles aren't nil, so we have to use pairs instead of ipairs
for _, role in pairs(bannedRoles) do
    bannedRolesDictionary[role] = true
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
hook.Add("TTTPrepareRound", "TTTPAPRegister", function()
    for role, equTable in pairs(EquipmentItems) do
        -- Check:
        -- Role is not banned
        -- Role doesn't already have the PaP
        -- CR is not installed, or role has a shop
        if not bannedRolesDictionary[role] and not HasItemWithPropertyValue(EquipmentItems[role], "id", EQUIP_PAP) and (not SHOP_ROLES or SHOP_ROLES[role]) then
            table.insert(equTable, pap)
        end
    end

    hook.Remove("TTTPrepareRound", "TTTPAPRegister")
end)

-- Preventing the Pack-a-Punch from being bought when it shouldn't be
hook.Add("TTTCanOrderEquipment", "TTTPAPPrePurchase", function(ply, equipment, is_item)
    -- Set the displaying of error messages to players to true
    if is_item and math.floor(equipment) == EQUIP_PAP and not TTTPAP:CanOrderPAP(ply, true) then return false end
end)

-- After TTTCanOrderEquipment is called and the weapon is in fact upgradable, find an upgrade for the weapon and apply it!
hook.Add("TTTOrderedEquipment", "TTTPAPPurchase", function(ply, equipment, _)
    if equipment == EQUIP_PAP then
        -- Set skip can upgrade check to true, as this was just done in the TTTCanOrderEquipment hook
        TTTPAP:OrderPAP(ply, true)

        -- Removes the equipment from the player, to make the pack-a-punch item re-buyable
        timer.Simple(0.1, function()
            -- Use the remove method if it exists
            if ply.RemoveEquipmentItem then
                ply:RemoveEquipmentItem(EQUIP_PAP)
            else
                -- Do an exclusive OR bitwise operation, so the only bit that will be affected is the PAP equipment bit
                ply.equipment_items = bit.bxor(ply.equipment_items, EQUIP_PAP)
                ply:SendEquipment()
            end
        end)
    end
end)