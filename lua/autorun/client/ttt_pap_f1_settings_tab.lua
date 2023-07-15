surface.CreateFont("TrophyDesc", {
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

local function DrawTrophyBar(list, SWEP)
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

    -- -- Rarity icon
    -- local rarityIcon = vgui.Create("DImage", background)
    -- rarityIcon:SetImage("ttt_trophies/" .. SWEP.rarity .. ".png")
    -- rarityIcon:SetSize(20, 20)
    -- rarityIcon:SetPos(5, 7)
    -- Title
    local title = vgui.Create("DLabel", background)
    title:SetText(LANG.TryTranslation(SWEP.PrintName))
    title:SetPos(12, 2)
    title:SetFont("Trebuchet24")
    -- local colour
    -- if SWEP.rarity == 1 then
    --     colour = Color(231, 131, 82)
    -- elseif SWEP.rarity == 2 then
    --     colour = Color(192, 192, 192)
    -- elseif SWEP.rarity == 3 then
    --     colour = Color(212, 175, 55)
    -- elseif SWEP.rarity == 4 then
    --     colour = Color(46, 104, 165)
    -- end
    -- title:SetTextColor(colour)
    title:SizeToContents()
    -- Description
    -- Displays the name of the upgraded weapon and its description
    local desc = vgui.Create("DLabel", background)
    local description = ""
    local PAPName = ""

    if TTT_PAP_UPGRADES[class] and TTT_PAP_UPGRADES[class].desc then
        description = TTT_PAP_UPGRADES[class].desc
        PAPName = TTT_PAP_UPGRADES[class].name
    else
        local PAPWep = weapons.Get(class .. "_pap")

        if PAPWep and PAPWep.PAPDesc then
            description = PAPWep.PAPDesc
            PAPName = PAPWep.PrintName
        end
    end

    desc:SetText("\"" .. PAPName .. "\" " .. description)
    desc:Dock(BOTTOM)
    desc:SetFont("TrophyDesc")
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

hook.Add("TTTSettingsTabs", "TTTTrophies", function(dtabs)
    if not LocalPlayer():IsAdmin() then return end
    -- Base panel
    local basePnl = vgui.Create("DPanel")
    basePnl:Dock(FILL)
    basePnl:SetBackgroundColor(COLOR_BLACK)
    -- -- List outside the scrollbar
    -- local nonScrollList = vgui.Create("DIconLayout", basePnl)
    -- nonScrollList:Dock(TOP)
    -- -- Sets the space between the image and text boxes
    -- nonScrollList:SetSpaceY(10)
    -- nonScrollList:SetSpaceX(10)
    -- -- Sets the space between the edge of the window and the edges of the tab's contents
    -- nonScrollList:SetBorder(10)
    -- nonScrollList.Paint = function(self, w, h)
    --     draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0))
    -- end
    -- -- Admin options menu
    -- local spacerPanelWidth = 200
    -- if LocalPlayer():IsAdmin() then
    --     local optionsButton = nonScrollList:Add("DButton")
    --     optionsButton:SetText("Admin Options")
    --     optionsButton:SizeToContents()
    --     spacerPanelWidth = spacerPanelWidth - optionsButton:GetSize()
    --     function optionsButton:DoClick()
    --         AdminOptionsMenu()
    --     end
    -- end
    -- local spacerPanel = nonScrollList:Add("DPanel")
    -- spacerPanel:SetBackgroundColor(COLOR_BLACK)
    -- spacerPanel:SetWidth(spacerPanelWidth)
    -- -- Progress bar text
    -- local earnedCount = 0
    -- for _, trophy in pairs(TTTTrophies.trophies) do
    --     if trophy.earned then
    --         earnedCount = earnedCount + 1
    --     end
    -- end
    -- local pctEarned = (earnedCount / table.Count(TTTTrophies.trophies)) * 100
    -- pctEarned = math.Round(pctEarned)
    -- local progressBarText = nonScrollList:Add("DLabel")
    -- progressBarText:SetText(pctEarned .. "% of trophies earned!")
    -- progressBarText:SetFont("TrophyDesc")
    -- progressBarText:SetTextColor(COLOUR_WHITE)
    -- progressBarText:SizeToContents()
    -- -- Progress bar
    -- local progressBar = nonScrollList:Add("DProgress")
    -- progressBar:SetFraction(pctEarned / 100)
    -- progressBar.OwnLine = true
    -- progressBar:SetSize(580, 20)
    -- -- Textbox for changing the hotkey to open the trophy list
    -- local textboxText = nonScrollList:Add("DLabel")
    -- textboxText:SetText("   Key that opens this window:")
    -- textboxText:SetFont("TrophyDesc")
    -- textboxText:SetTextColor(COLOUR_WHITE)
    -- textboxText:SizeToContents()
    -- local textbox = nonScrollList:Add("DTextEntry")
    -- textbox:SetSize(20, 20)
    -- textbox:SetText(GetConVar("ttt_trophies_hotkey_list"):GetString())
    -- textbox.OnLoseFocus = function(self)
    --     GetConVar("ttt_trophies_hotkey_list"):SetString(string.upper(self:GetText()))
    -- end
    -- textbox.OnEnter = function(self)
    --     GetConVar("ttt_trophies_hotkey_list"):SetString(string.upper(self:GetText()))
    -- end
    -- -- Textbox for changing the hotkey to toggle the reward for earning all trophies
    -- local textboxTextReward = nonScrollList:Add("DLabel")
    -- textboxTextReward:SetText("Key to toggle messages, or reward if all trophies earned:")
    -- textboxTextReward:SetFont("TrophyDesc")
    -- textboxTextReward:SetTextColor(COLOUR_WHITE)
    -- textboxTextReward:SizeToContents()
    -- local textboxReward = nonScrollList:Add("DTextEntry")
    -- textboxReward:SetSize(20, 20)
    -- textboxReward:SetText(GetConVar("ttt_trophies_hotkey_rainbow"):GetString())
    -- textboxReward.OnLoseFocus = function(self)
    --     GetConVar("ttt_trophies_hotkey_rainbow"):SetString(string.upper(self:GetText()))
    -- end
    -- textboxReward.OnEnter = function(self)
    --     GetConVar("ttt_trophies_hotkey_rainbow"):SetString(string.upper(self:GetText()))
    -- end
    -- Scrollbar
    local scroll = vgui.Create("DScrollPanel", basePnl)
    scroll:Dock(FILL)
    -- scroll:SetSize(600, 280)
    -- List of trophies in scrollbar
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

    local text = list:Add("DLabel")
    text:SetText("              Enable/disable individual weapon upgrades\n                   for the \"Pack-a-Punch\" buyable item!\n                            (Only admins can see this)")
    text:SetFont("Trebuchet24")
    text:SizeToContents()
    -- Convar checkbox for enabling/disabling generic PaP upgrades when a floor weapon doesn't have a designated upgrade
    local genericUpgradesCheck = list:Add("DCheckBoxLabel")
    local genericUpgradesCvar = GetConVar("ttt_pap_apply_generic_upgrade")
    genericUpgradesCheck:SetText(genericUpgradesCvar:GetHelpText())
    genericUpgradesCheck:SetChecked(genericUpgradesCvar:GetBool())
    genericUpgradesCheck:SetIndent(10)
    genericUpgradesCheck:SizeToContents()

    -- genericUpgradesCheck:SetPos(400, 5)
    function genericUpgradesCheck:OnChange()
        net.Start("TTTPAPToggleEnabledConvar")
        net.WriteString(genericUpgradesCvar:GetName())
        net.SendToServer()
    end

    -- Sorts the weapons by name in alphabetical order
    local upgradeableWeapons = {}

    for _, SWEP in ipairs(weapons.GetList()) do
        -- If a weapon doesn't have a human-readable name, it probably shouldn't be on this list (e.g. weapon_ttt_base)
        if not SWEP.PrintName then continue end
        local class = SWEP.ClassName or SWEP.Classname
        -- Check the weapon actually has a convar to toggle
        if not ConVarExists("ttt_pap_" .. class) then continue end
        local name = LANG.TryTranslation(SWEP.PrintName)
        upgradeableWeapons[name] = SWEP
    end

    for _, SWEP in SortedPairs(upgradeableWeapons) do
        DrawTrophyBar(list, SWEP)
    end

    -- Adds the tab panel to TTT's F1 menu
    dtabs:AddSheet("PaP", basePnl, "vgui/ttt/icon_pap_16.png", false, false, "Enable/disable individual weapon upgrades for the Pack-a-punch buyable item")
end)