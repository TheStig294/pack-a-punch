-- 
-- Creating the Pack-a-Punch passive item (It's here in the entities folder because else there's issues syncing the same item id between client and server)
-- 
if not TTT2 then return end
AddCSLuaFile()

-- Convars to turn off detective/traitor being able to buy the Pack-a-Punch for vanilla TTT (Custom Roles users can just use the role weapons system)
local detCvar = CreateConVar("ttt_pap_detective", 1, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Detectives can buy PaP (Requires map change)", 0, 1)

local traitorCvar = CreateConVar("ttt_pap_traitor", 1, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Traitors can buy PaP (Requires map change)", 0, 1)

if CLIENT then
    LANG.AddToLanguage("english", "pap_name", "Pack-A-Punch")
    LANG.AddToLanguage("english", "pap_desc", "Upgrades your held weapon!\n\nHold out the weapon you want to upgrade in your hands, then buy this item!")
end

ITEM.EquipMenuData = {
    type = "item_passive",
    name = "pap_name",
    desc = "pap_desc",
}

ITEM.credits = 1
ITEM.material = "vgui/ttt/ttt_pack_a_punch.png"
ITEM.CanBuy = {}

if detCvar:GetBool() then
    table.insert(ITEM.CanBuy, ROLE_DETECTIVE)
end

if traitorCvar:GetBool() then
    table.insert(ITEM.CanBuy, ROLE_TRAITOR)
end

if SERVER then
    -- Preventing the Pack-a-Punch from being bought when it shouldn't be
    hook.Add("TTTCanOrderEquipment", "TTTPAPPrePurchase", function(ply, id)
        -- Set the displaying of error messages to players to true
        if id == "ttt2_pap_item" then return TTTPAP:CanOrderPAP(ply, true) end
    end)

    -- After TTTCanOrderEquipment is called and the weapon is in fact upgradable, find an upgrade for the weapon and apply it!
    function ITEM:Bought(ply)
        -- Set skip can upgrade check to true, as this was just done in the TTTCanOrderEquipment hook
        TTTPAP:OrderPAP(ply, true)
    end
end