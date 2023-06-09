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
    -- If a weapon doesn't have a human-readable name, it probably shouldn't be on this list (e.g. weapon_ttt_base)
    if not SWEP.PrintName then return end
    local class = SWEP.ClassName or SWEP.Classname
    if not ConVarExists("ttt_pap_" .. class) then return end
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
    local name = SWEP.PrintName
    title:SetText(LANG.TryTranslation(name))
    title:SetPos(30, 5)
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
    -- -- Description
    -- -- Hide descriptions of hidden trophies unless the SWEP is earned, or its description is flagged as forced to show
    -- -- (Some trophies are too hard to discover if all SWEP descriptions are hidden)
    -- if SWEP.EquipMenuData and SWEP.EquipMenuData.desc then
    --     local desc = vgui.Create("DLabel", background)
    --     local description = SWEP.EquipMenuData.desc
    --     if isstring(description) then
    --         description = LANG.TryTranslation(description)
    --         desc:SetText(description)
    --         desc:Dock(BOTTOM)
    --         desc:SetFont("TrophyDesc")
    --         desc:SetTextColor(COLOUR_WHITE)
    --         desc:SizeToContents()
    --     end
    -- end
    -- Enabled/disabled checkbox
    local enabledBox = vgui.Create("DCheckBoxLabel", background)
    enabledBox:SetText("Enabled")
    enabledBox:SetChecked(enabledCvar:GetBool())
    enabledBox:SetIndent(10)
    enabledBox:SizeToContents()
    enabledBox:SetPos(400, 5)

    function enabledBox:OnChange()
        net.Start("TTTPAPToggleEnabledConvar")
        net.WriteString(class)
        net.SendToServer()
    end
end

hook.Add("TTTSettingsTabs", "TTTTrophies", function(dtabs)
    if not LocalPlayer():IsAdmin() then return end
    -- Base panel
    local basePnl = vgui.Create("DPanel")
    basePnl:Dock(FILL)
    basePnl:SetBackgroundColor(COLOR_BLACK)
    -- List outside the scrollbar
    local nonScrollList = vgui.Create("DIconLayout", basePnl)
    nonScrollList:Dock(TOP)
    -- Sets the space between the image and text boxes
    nonScrollList:SetSpaceY(10)
    nonScrollList:SetSpaceX(10)
    -- Sets the space between the edge of the window and the edges of the tab's contents
    nonScrollList:SetBorder(10)

    nonScrollList.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0))
    end

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
    scroll:Dock(BOTTOM)
    scroll:SetSize(600, 280)
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
    text:SetText("       Enable/disable individual weapon upgrades for the Pack-a-punch buyable item! Only admins can access this.")
    text:SizeToContents()

    -- -- Sorts the trophies by earned/unearned and rarity
    -- if table.IsEmpty(earnedTrophies) and table.IsEmpty(unearnedTrophies) then
    --     for id, trophy in pairs(TTTTrophies.trophies) do
    --         if trophy.earned then
    --             table.insert(earnedTrophies, trophy)
    --         else
    --             table.insert(unearnedTrophies, trophy)
    --         end
    --     end
    -- end
    -- The list of trophies, showing if they are earned or not
    -- for id, trophy in SortedPairsByMemberValue(unearnedTrophies, "rarity", false) do
    --     DrawTrophyBar(list, trophy)
    -- end
    -- for id, trophy in SortedPairsByMemberValue(earnedTrophies, "rarity", false) do
    --     DrawTrophyBar(list, trophy)
    -- end
    for _, SWEP in ipairs(weapons.GetList()) do
        DrawTrophyBar(list, SWEP)
    end

    -- Adds the tab panel to TTT's F1 menu
    dtabs:AddSheet("PaP", basePnl, "vgui/ttt/icon_pap_16.png", false, false, "Enable/disable individual weapon upgrades for the Pack-a-punch buyable item")
end)