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

-- Manually define player:IsAdmin() for TTT2
local function IsAdmin(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    local userGroup = ply:GetNWString("UserGroup", "user")

    if userGroup == "superadmin" or userGroup == "admin" then
        return true
    else
        return false
    end
end

local function OptionsMenu(UPGRADE)
    if not IsAdmin(LocalPlayer()) then return end
    -- Main window frame
    local frame = vgui.Create("DFrame")
    frame:SetSize(500, 350)
    frame:SetTitle("Upgrade Options")
    frame:MakePopup()
    frame:Center()

    frame.Paint = function(_, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0))
    end

    -- Scrollbar
    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    local layout = vgui.Create("DListLayout", scroll)
    layout:Dock(FILL)
    -- Name
    local name = vgui.Create("DLabel", layout)
    local nameText = ""

    if UPGRADE.name then
        nameText = "       " .. LANG.TryTranslation(UPGRADE.name)
    end

    name:SetText(nameText)
    name:SetFont("Trebuchet24")
    name:SetTextColor(COLOR_WHITE)
    name:SizeToContents()
    -- Description
    local desc = vgui.Create("DLabel", layout)
    local descText = ""

    if UPGRADE.desc then
        descText = "       " .. LANG.TryTranslation(UPGRADE.desc)
    end

    desc:SetText(descText)
    desc:SetFont("PAPDesc")
    desc:SetTextColor(COLOR_WHITE)
    desc:SizeToContents()

    -- Convar list
    for _, cvarInfo in ipairs(UPGRADE.convars) do
        if not ConVarExists(cvarInfo.name) then return end
        -- Padding
        local padding = layout:Add("DPanel")
        padding:SetBackgroundColor(COLOR_BLACK)
        padding:SetHeight(10)
        local cvar = GetConVar(cvarInfo.name)
        local helpText = cvar:GetHelpText() or ""

        -- Checkbox boolean convars
        if cvarInfo.type == "bool" then
            local checkbox = layout:Add("DCheckBoxLabel")
            checkbox:SetText(helpText)
            checkbox:SetChecked(cvar:GetBool())
            checkbox:SizeToContents()
            checkbox:SetIndent(10)

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
        elseif cvarInfo.type == "int" or cvarInfo.type == "float" then
            -- Slider integer convars
            local slider = layout:Add("DNumSlider")
            slider:SetSize(300, 100)
            slider:SetText(helpText)
            slider:SetMin(cvar:GetMin() or 0)
            slider:SetMax(cvar:GetMax() or 100)

            if cvarInfo.type == "int" then
                slider:SetDecimals(0)
            else
                slider:SetDecimals(cvarInfo.decimals or 2)
            end

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
            -- Textbox string convars
            local text = layout:Add("DLabel")
            text:SetText(helpText)
            text:SizeToContents()
            local textBox = layout:Add("DTextEntry")
            textBox:SetSize(450, 25)
            textBox:SetText(cvar:GetString())

            textBox.OnEnter = function(_, value)
                net.Start("TTTPAPChangeConvar")
                net.WriteString(cvarInfo.name)
                net.WriteString(value)
                net.SendToServer()
            end
        end
    end
end

local function ExtraOptionsMenu()
    if not IsAdmin(LocalPlayer()) then return end
    -- Main window frame
    local frame = vgui.Create("DFrame")
    frame:SetSize(500, 350)
    frame:SetTitle("Extra Options")
    frame:MakePopup()
    frame:Center()

    frame.Paint = function(_, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0))
    end

    -- Scrollbar
    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    local layout = vgui.Create("DIconLayout", scroll)
    layout:Dock(TOP)
    -- Title text
    local titleText = layout:Add("DLabel")
    titleText:SetText("                         Extra Admin Options")
    titleText:SetFont("Trebuchet24")
    titleText:SizeToContents()
    -- Sets the space between the image and text boxes
    layout:SetSpaceY(8)
    layout:SetSpaceX(10)
    -- Sets the space between the edge of the window and the edges of the tab's contents
    layout:SetBorder(5)
    -- Convar checkbox for enabling/disabling generic PaP upgrades when a floor weapon doesn't have a designated upgrade
    local genericUpgradesCvar = GetConVar("ttt_pap_apply_generic_upgrades")
    local genericUpgradesCheck = layout:Add("DCheckBoxLabel")
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

    -- Convar checkbox for enabling/disabling upgradeable indicator icons in the buy menu
    local indicatorCvar = GetConVar("ttt_pap_upgradeable_indicator")
    local indicatorCheck = layout:Add("DCheckBoxLabel")
    indicatorCheck:SetText(indicatorCvar:GetHelpText())
    indicatorCheck:SetChecked(indicatorCvar:GetBool())
    indicatorCheck:SetIndent(10)
    indicatorCheck:SizeToContents()

    function indicatorCheck:OnChange()
        net.Start("TTTPAPChangeConvar")
        net.WriteString(indicatorCvar:GetName())

        if indicatorCheck:GetChecked() then
            net.WriteString("1")
        else
            net.WriteString("0")
        end

        net.SendToServer()
    end

    -- Convar checkbox for enabling/disabling the generic PaP upgraded shoot sound
    local shootSoundCvar = GetConVar("ttt_pap_apply_generic_shoot_sound")
    local shootSoundCheck = layout:Add("DCheckBoxLabel")
    shootSoundCheck:SetText(shootSoundCvar:GetHelpText())
    shootSoundCheck:SetChecked(shootSoundCvar:GetBool())
    shootSoundCheck:SetIndent(10)
    shootSoundCheck:SizeToContents()

    function shootSoundCheck:OnChange()
        net.Start("TTTPAPChangeConvar")
        net.WriteString(shootSoundCvar:GetName())

        if shootSoundCheck:GetChecked() then
            net.WriteString("1")
        else
            net.WriteString("0")
        end

        net.SendToServer()
    end
end

local function DrawWeaponBar(list, UPGRADE)
    local SWEP = weapons.Get(UPGRADE.class)
    -- Icon
    local icon = list:Add("DImage")
    local image

    if SWEP and SWEP.Icon then
        image = SWEP.Icon
    else
        image = "vgui/ttt/icon_bullet"
    end

    icon:SetImage(image, "vgui/ttt/icon_bullet")
    icon:SetSize(64, 64)
    -- Background box
    local background = list:Add("DPanel")
    background:SetSize(480, 64)
    background:DockPadding(10, 0, 10, 5)
    -- Enabled cvar
    local alpha = 255
    local enabledCvarName = "ttt_pap_" .. UPGRADE.id
    local enabledCvar = GetConVar(enabledCvarName)

    if not enabledCvar:GetBool() then
        alpha = 100
    end

    background.Paint = function(_, w, h)
        draw.RoundedBox(10, 0, 0, w, h, Color(40, 40, 40, alpha))
    end

    -- Name
    local name = vgui.Create("DLabel", background)
    local nameText

    if SWEP and SWEP.PrintName then
        nameText = LANG.TryTranslation(SWEP.PrintName)
    elseif UPGRADE.class then
        nameText = UPGRADE.class
    else
        nameText = "Generic Upgrade"
    end

    name:SetText(nameText)
    name:SetPos(12, 2)
    name:SetFont("Trebuchet24")

    -- Name colour
    if SWEP and istable(SWEP.CanBuy) then
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
    local descriptionText = ""

    if UPGRADE.name then
        descriptionText = descriptionText .. "\"" .. UPGRADE.name .. "\" "
    end

    if UPGRADE.desc then
        descriptionText = descriptionText .. UPGRADE.desc
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
        net.WriteString(enabledCvarName)

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
    if UPGRADE.convars then
        local optionsButton = vgui.Create("DButton", background)
        optionsButton:SetText("Options")
        optionsButton:SizeToContents()
        optionsButton:SetPos(350, 4)

        function optionsButton:DoClick()
            OptionsMenu(UPGRADE)
        end
    end
end

local upgradeList = {}

-- Sorts the weapons by name in alphabetical order
local function DrawWeaponsList(list, searchQuery)
    if not searchQuery then
        searchQuery = ""
    end

    -- Only build the weapon upgrades table if needed
    if table.IsEmpty(upgradeList) then
        for class, upgrades in pairs(TTTPAP.upgrades) do
            local SWEP = weapons.Get(class)
            if not SWEP then continue end
            -- If a weapon doesn't have a human-readable name, just use the weapon's classname instead
            local name = class

            if SWEP.PrintName then
                name = LANG.TryTranslation(SWEP.PrintName)
            end

            upgradeList[name] = upgrades
        end

        -- Add all of the generic upgrades as well
        upgradeList["Generic Upgrade"] = table.Copy(TTTPAP.genericUpgrades)
    end

    -- If there is a search query, search the weapon's name, the upgraded weapon's name, and the upgrade's description
    for name, upgrades in SortedPairs(upgradeList) do
        -- Find the name and description of each of the weapon's upgrades
        for id, UPGRADE in pairs(upgrades) do
            local description = ""

            if UPGRADE.name then
                description = description .. UPGRADE.name
            end

            if UPGRADE.desc then
                description = description .. UPGRADE.desc
            end

            -- Search for the normal weapon's name, else the upgraded weapon's name and description
            if string.find(string.lower(name), string.lower(searchQuery), 1, true) or string.find(string.lower(description), string.lower(searchQuery), 1, true) then
                DrawWeaponBar(list, UPGRADE)
            end
        end
    end
end

local function CreateOptionsMenu()
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

    nonScrollList.Paint = function(_, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0))
    end

    -- Title text
    local titleText = nonScrollList:Add("DLabel")
    titleText:SetText("                             Pack-a-Punch Admin Options")
    titleText:SetFont("Trebuchet24")
    titleText:SizeToContents()
    -- Filler space
    local fillerPanel = nonScrollList:Add("DPanel")
    fillerPanel:SetSize(100, 1)

    fillerPanel.Paint = function(_, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0))
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
        roleWepsDesc:SetText("  Change which roles can buy the PaP, or any item, by clicking the button on the left.\n  (Note: By default, almost every role with a buy menu has the PaP)")
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

    -- Extra options button
    local extraOptionsButton = nonScrollList:Add("DButton")
    extraOptionsButton:SetText("Extra Options")
    extraOptionsButton:SetSize(100, 25)
    extraOptionsButton.DoClick = ExtraOptionsMenu
    -- Extra options button description text
    local roleWepsDesc = nonScrollList:Add("DLabel")
    roleWepsDesc:SetText("  More settings to customise the PaP")
    roleWepsDesc:SizeToContents()
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

    list.Paint = function(_, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0))
    end

    -- Weapons list
    DrawWeaponsList(list)

    -- Refreshes the weapons list according to what is typed in the search bar
    searchBar.OnValueChange = function(_, value)
        list:Clear()
        scroll:InvalidateLayout()
        DrawWeaponsList(list, value)
    end

    return basePnl
end

-- Adds the tab panel to TTT's F1 menu
hook.Add("TTTSettingsTabs", "TTTPAPUpgradesList", function(dtabs)
    if TTT2 or not IsAdmin(LocalPlayer()) then return end
    local basePnl = CreateOptionsMenu()
    dtabs:AddSheet("PaP", basePnl, "vgui/ttt/icon_pap_16.png", false, false, "Enable/disable individual weapon upgrades for the Pack-a-punch buyable item")
end)

-- Opening the PaP options menu when the F1 menu is not available
local function OpenStandaloneF1Menu(ply)
    if not IsAdmin(LocalPlayer()) or ply ~= LocalPlayer() then return end
    local frame = vgui.Create("DFrame")
    frame:SetSize(600, 480)
    frame:Center()
    frame:SetTitle("PAP Admin Options Menu")
    frame:ShowCloseButton(true)
    frame:MakePopup()
    local basePnl = CreateOptionsMenu()
    basePnl:SetParent(frame)
end

-- Opens menu on typing command into chat
hook.Add("OnPlayerChat", "TTTPAPTTT2OptionsMenu", function(ply, text)
    if not TTT2 or string.lower(text) ~= "/papop" or not IsAdmin(LocalPlayer()) or ply ~= LocalPlayer() then return end
    OpenStandaloneF1Menu(ply)

    return true
end)

-- Lets players know about chat/console command
hook.Add("TTTBeginRound", "TTTPAPTTT2OptionsMessage", function()
    if TTT2 and IsAdmin(LocalPlayer()) then
        LocalPlayer():ChatPrint("Type /papop to open options window\nor ttt_pap_options in the console")
    end

    hook.Remove("TTTBeginRound", "TTTPAPTTT2OptionsMessage")
end)

concommand.Add("ttt_pap_options", OpenStandaloneF1Menu)