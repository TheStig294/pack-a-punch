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

local function OptionsMenu(SWEP, PAPClass)
    if not LocalPlayer():IsAdmin() then return end
    local frame = vgui.Create("DFrame")
    frame:SetSize(500, 350)
    frame:SetTitle("Upgrade Options")
    frame:MakePopup()
    frame:Center()

    frame.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0))
    end

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    local layout = vgui.Create("DListLayout", scroll)
    layout:Dock(FILL)
    local PAPSWEP = weapons.Get(PAPClass)
    local name = vgui.Create("DLabel", layout)
    local nameText = LANG.TryTranslation(PAPSWEP.PrintName)

    if isstring(nameText) then
        nameText = "       " .. nameText
    else
        nameText = ""
    end

    name:SetText(nameText)
    name:SetFont("Trebuchet24")
    name:SetTextColor(COLOR_WHITE)
    name:SizeToContents()
    local desc = vgui.Create("DLabel", layout)
    local descText = LANG.TryTranslation(PAPSWEP.PAPDesc)

    if isstring(descText) then
        descText = "       " .. descText
    else
        descText = ""
    end

    desc:SetText(descText)
    desc:SetFont("PAPDesc")
    desc:SetTextColor(COLOR_WHITE)
    desc:SizeToContents()

    for _, cvarInfo in ipairs(TTT_PAP_CONVARS[PAPClass]) do
        if not ConVarExists(cvarInfo.name) then return end
        local padding = layout:Add("DPanel")
        padding:SetBackgroundColor(COLOR_BLACK)
        padding:SetHeight(10)
        local cvar = GetConVar(cvarInfo.name)
        local helpText = cvar:GetHelpText() or ""

        if cvarInfo.type == "bool" then
            local checkbox = layout:Add("DCheckBoxLabel")
            checkbox:SetText(helpText)
            checkbox:SetChecked(cvar:GetBool())
            checkbox:SizeToContents()

            function checkbox:OnChange()
                net.Start("TTTPAPChangeConvar")
                net.WriteString(cvarInfo.name)

                if checkbox:GetChecked() then
                    net.WriteString("1")
                else
                    net.WriteString("0")
                end

                net.SendToServer()
            end
        elseif cvarInfo.type == "int" then
            local slider = layout:Add("DNumSlider")
            slider:SetSize(300, 100)
            slider:SetText(helpText)
            slider:SetMin(cvar:GetMin() or 0)
            slider:SetMax(cvar:GetMax() or 100)
            slider:SetDecimals(0)
            slider:SetValue(cvar:GetInt())
            slider:SetHeight(25)

            slider.OnValueChanged = function(self, value)
                timer.Create("TTTPAPChangeConvarDelay", 0.5, 1, function()
                    value = math.Round(value, self:GetDecimals())
                    net.Start("TTTPAPChangeConvar")
                    net.WriteString(cvarInfo.name)
                    net.WriteString(tostring(value))
                    net.SendToServer()
                end)
            end
        elseif cvarInfo.type == "float" then
            local slider = layout:Add("DNumSlider")
            slider:SetSize(300, 100)
            slider:SetText(helpText)
            slider:SetMin(cvar:GetMin() or 0)
            slider:SetMax(cvar:GetMax() or 100)
            slider:SetDecimals(cvarInfo.decimal or 2)
            slider:SetValue(cvar:GetFloat())
            slider:SetHeight(25)

            slider.OnValueChanged = function(self, value)
                timer.Create("TTTPAPChangeConvarDelay", 0.5, 1, function()
                    value = math.Round(value, self:GetDecimals())
                    net.Start("TTTPAPChangeConvar")
                    net.WriteString(cvarInfo.name)
                    net.WriteString(tostring(value))
                    net.SendToServer()
                end)
            end
        elseif cvarInfo.type == "string" then
            local text = layout:Add("DLabel")
            text:SetText(helpText)
            text:SizeToContents()
            local textBox = layout:Add("DTextEntry")
            textBox:SetSize(450, 25)
            textBox:SetText(cvar:GetString())

            textBox.OnEnter = function(self, value)
                net.Start("TTTPAPChangeConvar")
                net.WriteString(cvarInfo.name)
                net.WriteString(value)
                net.SendToServer()
            end
        end
    end
end

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
        net.Start("TTTPAPChangeConvar")
        local cvarName = "ttt_pap_" .. class
        net.WriteString(cvarName)

        if enabledBox:GetChecked() then
            alpha = 255
            net.WriteString("1")
        else
            alpha = 100
            net.WriteString("0")
        end

        net.SendToServer()
        icon:SetAlpha(alpha)
    end

    -- Options button
    local PAPClass = class .. "_pap"

    if TTT_PAP_CONVARS[PAPClass] then
        local optionsButton = vgui.Create("DButton", background)
        optionsButton:SetText("Options")
        optionsButton:SizeToContents()
        optionsButton:SetPos(350, 4)

        function optionsButton:DoClick()
            OptionsMenu(SWEP, PAPClass)
        end
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
    titleText:SetText("                             Pack-a-Punch Admin Options")
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
        net.Start("TTTPAPChangeConvar")
        net.WriteString(genericUpgradesCvar:GetName())

        if genericUpgradesCheck:GetChecked() then
            net.WriteString("1")
        else
            net.WriteString("0")
        end

        net.SendToServer()
    end

    if CR_VERSION then
        -- If Custom Roles for TTT is installed, simply add a button that opens the roleweapons config window,
        -- since every role with a shop by default can buy the PaP, not just traitor and detective
        -- Role weapons button
        local roleWepsButton = nonScrollList:Add("DButton")
        roleWepsButton:SetText("Buy Menu Editor")
        roleWepsButton:SetSize(100, 25)

        function roleWepsButton:DoClick()
            RunConsoleCommand("ttt_roleweapons")
        end

        -- Role weapons button description text
        local roleWepsDesc = nonScrollList:Add("DLabel")
        roleWepsDesc:SetText("  Change which roles can buy the PaP, or any item, by clicking the button on the left.\n  (Note: By default, every role with a buy menu can buy the PaP)")
        roleWepsDesc:SizeToContents()
    else
        -- Convar checkbox for the detective being able to buy the Pack-a-Punch
        local detectiveCvar = GetConVar("ttt_pap_detective")
        local detectiveCheck = nonScrollList:Add("DCheckBoxLabel")
        detectiveCheck:SetText(detectiveCvar:GetHelpText())
        detectiveCheck:SetChecked(detectiveCvar:GetBool())
        detectiveCheck:SetIndent(10)
        detectiveCheck:SizeToContents()

        function detectiveCheck:OnChange()
            net.Start("TTTPAPChangeConvar")
            net.WriteString(detectiveCvar:GetName())

            if detectiveCheck:GetChecked() then
                net.WriteString("1")
            else
                net.WriteString("0")
            end

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
            net.Start("TTTPAPChangeConvar")
            net.WriteString(traitorCvar:GetName())

            if traitorCheck:GetChecked() then
                net.WriteString("1")
            else
                net.WriteString("0")
            end

            net.SendToServer()
        end
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