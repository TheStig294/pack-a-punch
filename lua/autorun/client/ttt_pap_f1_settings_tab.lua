surface.CreateFont("PAPDesc", {
    font = "Arial",
    extended = false,
    size = 16,
    weight = 500,
    blursize = 0,
    scanlines = 0,
    antialias = true,
    underline = false,
    italic = true,
    strikeout = false,
    symbol = false,
    rotary = false,
    shadow = false,
    additive = false,
    outline = false,
})

local function DrawWeaponBar(list, SWEP)
    local class = SWEP.ClassName or SWEP.Classname
    local enabledCvar = GetConVar("ttt_pap_" .. class)
    -- Icon
    local icon = list:Add("DImage")
    local image = SWEP.Icon or "vgui/ttt/icon_bullet"
    icon:SetImage(image, "vgui/ttt/icon_bullet")
    icon:SetSize(64, 64)
    -- Background box
    local background = list:Add("DPanel")
    background:SetSize(480, 64)
    background:DockPadding(10, 0, 10, 5)
    local alpha = 255

    if not enabledCvar:GetBool() then
        alpha = 100
    end

    background.Paint = function(self, w, h)
        draw.RoundedBox(10, 0, 0, w, h, Color(40, 40, 40, alpha))
    end

    -- Name
    local name = vgui.Create("DLabel", background)
    name:SetText(LANG.TryTranslation(SWEP.PrintName))
    name:SetPos(12, 2)
    name:SetFont("Trebuchet24")

    -- Name colour
    if istable(SWEP.CanBuy) then
        local colour
        local isDetective = table.HasValue(SWEP.CanBuy, ROLE_DETECTIVE)
        local isTraitor = table.HasValue(SWEP.CanBuy, ROLE_TRAITOR)

        if isDetective and isTraitor then
            colour = Color(165, 29, 255)
        elseif isDetective then
            colour = Color(26, 106, 255)
        elseif isTraitor then
            colour = Color(255, 0, 0)
        else
            colour = COLOUR_WHITE
        end

        name:SetTextColor(colour)
    end

    name:SizeToContents()
    -- Upgrade Description
    local desc = vgui.Create("DLabel", background)
    local description
    local PAPName

    if TTT_PAP_UPGRADES[class] then
        description = TTT_PAP_UPGRADES[class].desc
        PAPName = TTT_PAP_UPGRADES[class].name
    else
        local PAPWep = weapons.Get(class .. "_pap")

        if PAPWep then
            description = PAPWep.PAPDesc
            PAPName = PAPWep.PrintName
        end
    end

    local descriptionText = ""

    if PAPName then
        descriptionText = descriptionText .. "\"" .. PAPName .. "\" "
    end

    if description then
        descriptionText = descriptionText .. description
    end

    desc:SetText(descriptionText)
    desc:Dock(BOTTOM)
    desc:SetFont("PAPDesc")
    desc:SetTextColor(COLOUR_WHITE)
    desc:SizeToContents()
    -- Enabled/disabled checkbox
    local enabledBox = vgui.Create("DCheckBoxLabel", background)
    enabledBox:SetText("Enabled")
    enabledBox:SetChecked(enabledCvar:GetBool())
    enabledBox:SetIndent(10)
    enabledBox:SizeToContents()
    enabledBox:SetPos(400, 5)

    function enabledBox:OnChange()
        net.Start("TTTPAPToggleEnabledConvar")
        local cvarName = "ttt_pap_" .. class
        net.WriteString(cvarName)
        net.SendToServer()

        if enabledBox:GetChecked() then
            alpha = 255
        else
            alpha = 100
        end

        icon:SetAlpha(alpha)
    end
end

local upgradeableWeapons = {}

-- Sorts the weapons by name in alphabetical order
local function DrawWeaponsList(list, searchQuery)
    if not searchQuery then
        searchQuery = ""
    end

    -- Only build the upgradeable weapons table if needed
    if table.IsEmpty(upgradeableWeapons) then
        for _, SWEP in ipairs(weapons.GetList()) do
            -- If a weapon doesn't have a human-readable name, it probably shouldn't be on this list (e.g. weapon_ttt_base)
            if not SWEP.PrintName then continue end
            local class = SWEP.ClassName or SWEP.Classname
            -- Check the weapon actually has a convar to toggle
            if not ConVarExists("ttt_pap_" .. class) then continue end
            local name = LANG.TryTranslation(SWEP.PrintName)
            upgradeableWeapons[name] = SWEP
        end
    end

    -- If there is a search query, search the weapon's name, the upgraded weapon's name, and the upgrade's description
    for name, SWEP in SortedPairs(upgradeableWeapons) do
        local description = ""
        local class = SWEP.ClassName or SWEP.Classname

        -- Find the upgraded weapon's name and description
        -- Stat upgrade
        if TTT_PAP_UPGRADES[class] then
            if TTT_PAP_UPGRADES[class].name then
                description = description .. TTT_PAP_UPGRADES[class].name
            end

            if TTT_PAP_UPGRADES[class].desc then
                description = description .. TTT_PAP_UPGRADES[class].desc
            end
        else
            -- New SWEP upgrade
            local PAPWep = weapons.Get(class .. "_pap")

            if PAPWep then
                if PAPWep.PrintName then
                    description = description .. LANG.TryTranslation(PAPWep.PrintName)
                end

                if PAPWep.PAPDesc then
                    description = description .. PAPWep.PAPDesc
                end
            end
        end

        -- Search for the normal weapon's name, else the upgraded weapon's name and description
        if string.find(string.lower(name), string.lower(searchQuery), 1, true) or string.find(string.lower(description), string.lower(searchQuery), 1, true) then
            DrawWeaponBar(list, SWEP)
        end
    end
end

hook.Add("TTTSettingsTabs", "TTTPAPUpgradesList", function(dtabs)
    if not LocalPlayer():IsAdmin() then return end
    -- Base panel
    local basePnl = vgui.Create("DPanel")
    basePnl:Dock(FILL)
    basePnl:SetBackgroundColor(COLOR_BLACK)
    -- List outside the scrollbar
    local nonScrollList = vgui.Create("DIconLayout", basePnl)
    nonScrollList:Dock(TOP)
    -- Sets the space between the image and text boxes
    nonScrollList:SetSpaceY(8)
    nonScrollList:SetSpaceX(10)
    -- Sets the space between the edge of the window and the edges of the tab's contents
    nonScrollList:SetBorder(5)

    nonScrollList.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0))
    end

    -- Title text
    local titleText = nonScrollList:Add("DLabel")
    titleText:SetText("                       Toggle individual weapon upgrades\n            for the \"Pack-a-Punch\" buyable item! (Admins only)")
    titleText:SetFont("Trebuchet24")
    titleText:SizeToContents()
    -- Convar checkbox for enabling/disabling generic PaP upgrades when a floor weapon doesn't have a designated upgrade
    local genericUpgradesCvar = GetConVar("ttt_pap_apply_generic_upgrade")
    local genericUpgradesCheck = nonScrollList:Add("DCheckBoxLabel")
    genericUpgradesCheck:SetText(genericUpgradesCvar:GetHelpText())
    genericUpgradesCheck:SetChecked(genericUpgradesCvar:GetBool())
    genericUpgradesCheck:SetIndent(10)
    genericUpgradesCheck:SizeToContents()

    function genericUpgradesCheck:OnChange()
        net.Start("TTTPAPToggleEnabledConvar")
        net.WriteString(genericUpgradesCvar:GetName())
        net.SendToServer()
    end

    -- Convar checkbox for the detective being able to buy the Pack-a-Punch
    local detectiveCvar = GetConVar("ttt_pap_detective")
    local detectiveCheck = nonScrollList:Add("DCheckBoxLabel")
    detectiveCheck:SetText(detectiveCvar:GetHelpText())
    detectiveCheck:SetChecked(detectiveCvar:GetBool())
    detectiveCheck:SetIndent(10)
    detectiveCheck:SizeToContents()

    function detectiveCheck:OnChange()
        net.Start("TTTPAPToggleEnabledConvar")
        net.WriteString(detectiveCvar:GetName())
        net.SendToServer()
    end

    -- Convar checkbox for the traitor being able to buy the Pack-a-Punch
    local traitorCvar = GetConVar("ttt_pap_traitor")
    local traitorCheck = nonScrollList:Add("DCheckBoxLabel")
    traitorCheck:SetText(traitorCvar:GetHelpText())
    traitorCheck:SetChecked(traitorCvar:GetBool())
    traitorCheck:SetIndent(10)
    traitorCheck:SizeToContents()

    function traitorCheck:OnChange()
        net.Start("TTTPAPToggleEnabledConvar")
        net.WriteString(traitorCvar:GetName())
        net.SendToServer()
    end

    -- Search bar
    local searchBar = nonScrollList:Add("DTextEntry")
    searchBar:SetSize(570, 20)
    searchBar:SetPlaceholderText("Search...")
    searchBar:SetUpdateOnType(true)
    -- Scrollbar
    local scroll = vgui.Create("DScrollPanel", basePnl)
    scroll:Dock(FILL)
    -- Weapons list
    local list = vgui.Create("DIconLayout", scroll)
    list:Dock(FILL)
    -- Sets the space between the image and text boxes
    list:SetSpaceY(10)
    list:SetSpaceX(10)
    -- Sets the space between the edge of the window and the edges of the tab's contents
    list:SetBorder(10)

    list.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0))
    end

    -- Weapons list
    DrawWeaponsList(list)

    -- Refreshes the weapons list according to what is typed in the search bar
    searchBar.OnValueChange = function(box, value)
        list:Clear()
        scroll:Rebuild()
        DrawWeaponsList(list, value)
    end

    -- Adds the tab panel to TTT's F1 menu
    dtabs:AddSheet("PaP", basePnl, "vgui/ttt/icon_pap_16.png", false, false, "Enable/disable individual weapon upgrades for the Pack-a-punch buyable item")
end)