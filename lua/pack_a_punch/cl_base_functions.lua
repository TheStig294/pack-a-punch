-- 
-- Client-side pack-a-punch functions
-- 
net.Receive("TTTPAPApply", function()
    local SWEP = net.ReadEntity()
    if not IsValid(SWEP) then return end
    -- Reading data from server
    local delay = net.ReadFloat()
    local RPM = net.ReadFloat()
    local damage = net.ReadFloat()
    local cone = net.ReadFloat()
    local spread = net.ReadFloat()
    local clipSize = net.ReadFloat()
    local recoil = net.ReadFloat()
    local staticRecoilFactor = net.ReadFloat()
    local automatic = net.ReadBool()
    local upgradeID = net.ReadString()
    local upgradeClass = net.ReadString()
    local noDesc = net.ReadBool()
    local UPGRADE

    -- Generic upgrades do not have a weapon class defined
    if upgradeClass == "" then
        UPGRADE = TTTPAP.genericUpgrades[upgradeID]
    else
        UPGRADE = TTTPAP.upgrades[upgradeClass][upgradeID]
    end

    -- Apply upgrade function on the client
    UPGRADE:Apply(SWEP)
    table.insert(TTTPAP.activeUpgrades, UPGRADE)

    -- Stats
    if istable(SWEP.Primary) then
        SWEP.Primary.Delay = delay
        SWEP.Primary.RPM = RPM
        SWEP.Primary.Damage = damage
        SWEP.Primary.Cone = cone
        SWEP.Primary.Spread = spread
        SWEP.Primary.ClipSize = clipSize
        SWEP.Primary.ClipMax = clipSize
        SWEP.Primary.Recoil = recoil
        SWEP.Primary.StaticRecoilFactor = staticRecoilFactor
        SWEP.Primary.Automatic = automatic
    end

    -- Name
    if UPGRADE.name then
        SWEP.PrintName = UPGRADE.name
        -- If no defined name for a weapon, just call it: "PAP [weapon name]"
    elseif SWEP.PrintName then
        SWEP.PrintName = "PAP " .. LANG.TryTranslation(SWEP.PrintName)
    end

    -- Description
    if UPGRADE.desc and not noDesc then
        -- Need to check this is the player actually holding the weapon!
        for _, wep in ipairs(LocalPlayer():GetWeapons()) do
            if wep == SWEP then
                chat.AddText("PAP UPGRADE: " .. UPGRADE.desc)
                break
            end
        end
    end

    -- Camo (SWEP construction kit weapons)
    if not UPGRADE.noCamo then
        if SWEP.VElements and istable(SWEP.VElements) then
            for _, element in pairs(SWEP.VElements) do
                element.material = TTTPAP.camo
            end
        end

        if SWEP.WElements and istable(SWEP.WElements) then
            for _, element in pairs(SWEP.WElements) do
                element.material = TTTPAP.camo
            end
        end
    end

    -- Upgraded flag
    SWEP.PAPUpgrade = UPGRADE
end)

-- Camo
local appliedCamo = false

hook.Add("PreDrawViewModel", "TTTPAPApplyCamo", function(vm, _, SWEP)
    if not IsValid(SWEP) then return end

    if SWEP.PAPUpgrade and not SWEP.PAPUpgrade.noCamo then
        vm:SetMaterial(TTTPAP.camo)
        appliedCamo = true
    elseif appliedCamo or vm:GetMaterial() == TTTPAP.camo then
        vm:SetMaterial("")
        appliedCamo = false
    end
end)

-- Extra camo reset
local vm

hook.Add("TTTPrepareRound", "TTTPAPRemoveCamo", function()
    timer.Simple(0.1, function()
        if not IsValid(vm) then
            local client = LocalPlayer()
            if not IsValid(client) then return end
            vm = client:GetViewModel()
            if not IsValid(vm) then return end
        end

        if vm:GetMaterial() == TTTPAP.camo then
            vm:SetMaterial("")
            appliedCamo = false
        end
    end)
end)

-- Sound
hook.Add("EntityEmitSound", "TTTPAPApplySound", function(data)
    if not IsValid(data.Entity) or not data.Entity.PAPUpgrade or data.Entity.PAPUpgrade.noSound then return end
    local current_sound = data.SoundName:lower()
    local fire_start, _ = string.find(current_sound, ".*weapons/.*fire.*%..*")
    local shot_start, _ = string.find(current_sound, ".*weapons/.*shot.*%..*")
    local shoot_start, _ = string.find(current_sound, ".*weapons/.*shoot.*%..*")

    if fire_start or shot_start or shoot_start then
        data.SoundName = TTTPAP.shootSound

        return true
    end
end)

net.Receive("TTTPAPApplySound", function()
    local SWEP = net.ReadEntity()

    if SWEP.Primary then
        SWEP.Primary.Sound = TTTPAP.shootSound
    end
end)

-- 
-- Adding icons to the buy menu to show if a weapon is upgradeable or not
-- 
-- Travels down the panel hierarchy of the buy menu, and returns a table of all buy menu icons
local function GetItemIconPanels(dsheet)
    local panelHierachy

    -- The way the buy menu panels are laid out depends on what version of TTT you are using
    -- In Custom Roles, the search bar is in the way, on the main dsheet on the left hand side
    -- In the regular Better Equipment Menu UI, and TTT2, the search bar is on the right hand side, a different panel to the main dsheet
    -- First index is the scroll panel child, the second index is the "Equipment Items" child, its children are all of the buy menu icons
    -- A table of the children of that panel is returned (The buy menu icons)
    if CR_VERSION then
        panelHierachy = {2, 1}
    else
        panelHierachy = {1, 1}
    end

    local buyMenu

    for _, tab in ipairs(dsheet:GetItems()) do
        if tab.Name == "Order Equipment" then
            buyMenu = tab.Panel
            break
        end
    end

    if not buyMenu then return end
    buyMenu = buyMenu:GetChildren()

    -- From here, things get unavoidably arbitrary
    -- Hopefully Panel:GetChildren() always returns these child panels the same way every time since they don't have any sort of ID
    -- Being super careful here to check for nil or empty table values at each step,
    -- since Gmod store skins or future updates for the buy menu could render it unusable otherwise
    for _, childIndex in ipairs(panelHierachy) do
        if not buyMenu or table.IsEmpty(buyMenu) then return end
        buyMenu = buyMenu[childIndex]
        if not buyMenu then return end
        buyMenu = buyMenu:GetChildren()
    end

    return buyMenu
end

local iconToClass = {}

local function GetClassFromIcon(icon)
    if table.IsEmpty(iconToClass) then
        for _, wep in ipairs(weapons.GetList()) do
            local wepIcon = wep.Icon

            if wepIcon then
                if TTT2 then
                    wepIcon = string.StripExtension(wepIcon)
                end

                iconToClass[wepIcon] = WEPS.GetClass(wep)
            end
        end
    end

    return iconToClass[icon]
end

local iconToUpgradeable = {}

hook.Add("TTTEquipmentTabs", "TTTPAPAddBuyMenuIcons", function(dsheet)
    if not GetConVar("ttt_pap_upgradeable_indicator"):GetBool() then return end
    local itemIcons = GetItemIconPanels(dsheet)
    if not itemIcons or table.IsEmpty(itemIcons) then return end
    -- Now we've finally made it, start looping through the buy menu icons and start counting which weapons are upgradeable or not
    local upgradeableCount = 0
    local notUpgradeableCount = 0

    for _, iconPanel in ipairs(itemIcons) do
        if not iconPanel.GetIcon then return end
        local icon

        -- TTT2 just loves to be difficult doesn't it?
        -- (TTT2 breaks the GetIcon() function, it always returns nil...)
        if TTT2 then
            icon = iconPanel.Icon:GetMaterial():GetName()
        else
            icon = iconPanel:GetIcon()
        end

        local class = GetClassFromIcon(icon)
        -- Skip passive items, or items we couldn't find
        if not class then continue end

        -- Count how many items are upgradeable vs. not
        if TTTPAP:CanOrderPAP(class) then
            upgradeableCount = upgradeableCount + 1
            iconToUpgradeable[icon] = true
        else
            notUpgradeableCount = notUpgradeableCount + 1
            iconToUpgradeable[icon] = false
        end
    end

    local moreUpgradeableThanNot = upgradeableCount > notUpgradeableCount

    -- Then create the icons, either showing upgradeable, or not upgradeable, whichever adds less icons
    for _, iconPanel in ipairs(itemIcons) do
        local upgradeable

        if TTT2 then
            upgradeable = iconToUpgradeable[iconPanel.Icon:GetMaterial():GetName()]
        else
            upgradeable = iconToUpgradeable[iconPanel:GetIcon()]
        end

        local icon

        if upgradeable and not moreUpgradeableThanNot then
            icon = vgui.Create("DImage")
            icon:SetImage("vgui/ttt/icon_pap_16.png")
            icon:SetTooltip("Upgradable")
        elseif upgradeable == false and (moreUpgradeableThanNot or upgradeableCount == 0) then
            icon = vgui.Create("DImage")
            icon:SetImage("vgui/ttt/icon_not_upgradeable_16.png")
            icon:SetTooltip("Not Upgradable")
        else
            continue
        end

        -- Set the icon to be faded if the buy menu icon is faded (e.g. weapon is already bought)
        icon:SetImageColor(iconPanel.Icon:GetImageColor())

        -- This is how other overlayed icons are done in vanilla TTT, so we do the same here
        -- This normally used for the slot icon and custom item icon
        -- Hopefully TTT2 also has a "LayeredIcon" vgui element but you know how TTT2 goes... We'll probably have to do something else...
        icon.PerformLayout = function(s)
            s:AlignBottom(4)
            s:CenterHorizontal()
            s:SetSize(16, 16)
        end

        iconPanel:AddLayer(icon)
        iconPanel:EnableMousePassthrough(icon)
    end
end)