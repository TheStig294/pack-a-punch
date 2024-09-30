local UPGRADE = {}
UPGRADE.id = "server_console"
UPGRADE.class = "weapon_ttt_adm_menu"
UPGRADE.name = "Server Console"
UPGRADE.desc = "More powerful set of commands!"
UPGRADE.convars = {}

local defaultCommandCosts = {
    psay = 5,
    playsound = 10,
    mute = 15,
    whip = 4, -- 20 power for 5 seconds
    teleport = 30,
    upgrade = 40,
    cloak = 9, -- 45 power for 5 seconds
    god = 9, -- 45 power for 5 seconds
    noclip = 9, -- 45 power for 5 seconds
    armor = 50,
    credit = 60,
    maul = 70,
    hp = 80,
    voteban = 90, -- not real, don't panic
    forcenr = 100
}

local function ShouldCloseAfterSelfUse(command)
    return command == "whip" or command == "teleport" or command == "cloak" or command == "god" or command == "noclip" or command == "maul"
end

local function SilentChatMessage(command)
    return command == "psay" or command == "mute" or command == "forcenr"
end

local function HasMessage(command)
    return command == "psay" or command == "hp" or command == "voteban" or command == "forcenr"
end

local function IsTimedCommand(command)
    return command == "whip" or command == "cloak" or command == "god" or command == "noclip"
end

-- Fancy dynamic convar creation because I can't be bothered to do it manually
local commands = table.GetKeys(defaultCommandCosts)
local commandCvars = {}

for _, command in ipairs(commands) do
    local convarName = "pap_server_console_" .. command .. "_cost"
    local helptext = "Cost of " .. command

    if IsTimedCommand(command) then
        helptext = helptext .. " per second"
    end

    helptext = helptext .. ". 0 to disable"

    commandCvars[command] = CreateConVar(convarName, defaultCommandCosts[command], {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY}, helptext, 0, 100)

    local convarTable = {
        name = convarName,
        type = "int"
    }

    table.insert(UPGRADE.convars, convarTable)
end

if CLIENT then
    surface.CreateFont("TTTPAPServerConsolePsay", {
        font = "Trebuchet24",
        size = 48,
        weight = 1000
    })
end

local forcedRoles = {}

-- If a role was forced using the forcenr command and the map changed, set each player's role on the new map
if SERVER and file.Exists("ttt_pack_a_punch/server_console_saved_roles.json", "DATA") then
    forcedRoles = util.JSONToTable(file.Read("ttt_pack_a_punch/server_console_saved_roles.json", "DATA"))

    hook.Add("TTTPrepareRound", "TTTPAPServerConsoleSetSavedRoles", function()
        for _, ply in player.Iterator() do
            if UPGRADE:IsAlivePlayer(ply) then
                local id = ply:SteamID()
                local forcedRole = forcedRoles[id]

                if forcedRole then
                    ply:ForceRoleNextRound(forcedRole.role)
                    ply:ChatPrint("Your role has been forced to " .. forcedRole.name .. " next round from your \"forcenr\" " .. ROLE_STRINGS[ROLE_ADMIN] .. " command!")
                    forcedRoles[id] = nil
                end
            end
        end
    end)

    file.Delete("ttt_pack_a_punch/server_console_saved_roles.json")
end

function UPGRADE:Apply(SWEP)
    -- All of this code is made by Nick, taken from the Admin role's device:
    -- https://github.com/Custom-Roles-for-TTT/TTT-Jingle-Jam-Roles-2023/blob/main/gamemodes/terrortown/entities/weapons/weapon_ttt_adm_menu.lua
    -- (Because I can't be bothered doing a PR to make this all modular and there's no avoiding copying all this otherwise...)
    function SWEP:PrimaryAttack()
        if not IsFirstTimePredicted() then return end
        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

        if CLIENT then
            local m = 5
            local listWidth = 120
            local titleBarHeight = 25
            local width = listWidth * 4 + m * 5
            local height = 300
            local labelHeight = 15
            local listHeight = height - titleBarHeight - labelHeight - m * 2
            local buttonHeight = 22
            local dframe = vgui.Create("DFrame")
            dframe:SetSize(width, height)
            dframe:Center()
            dframe:SetTitle("Server Console")
            dframe:SetVisible(true)
            dframe:ShowCloseButton(true)
            dframe:SetMouseInputEnabled(true)
            dframe:SetDeleteOnClose(true)
            local dcommandsLabel = vgui.Create("DLabel", dframe)
            dcommandsLabel:SetFont("TabLarge")
            dcommandsLabel:SetText("Commands:")
            dcommandsLabel:SetWidth(listWidth)
            dcommandsLabel:SetPos(m, titleBarHeight)
            local dcommands = vgui.Create("DListView", dframe)
            dcommands:SetSize(listWidth, listHeight)
            dcommands:SetPos(m, titleBarHeight + labelHeight + m)
            dcommands:SetHideHeaders(true)
            dcommands:SetMultiSelect(false)
            dcommands:AddColumn("Commands")
            local validCommands = {}

            for _, v in ipairs(commands) do
                local cost = commandCvars[v]:GetInt()

                if IsTimedCommand(v) then
                    cost = math.min(5 * cost, 100)
                end

                if cost > 0 then
                    table.insert(validCommands, {
                        command = v,
                        cost = cost
                    })
                end
            end

            table.sort(validCommands, function(a, b)
                if a.cost == b.cost then
                    return a.command < b.command
                else
                    return a.cost < b.cost
                end
            end)

            for _, v in ipairs(validCommands) do
                dcommands:AddLine(v.command)
            end

            local dparams = vgui.Create("DPanel", dframe)
            dparams:SetSize(listWidth * 3 + m * 2, listHeight + labelHeight)
            dparams:SetPos(listWidth + m * 2, titleBarHeight + m)
            dparams:SetPaintBackground(false)

            local descriptions = {
                ["psay"] = "Sends a private message to someone in the middle of their screen.",
                ["playsound"] = "Plays a sound for the target.",
                ["mute"] = "Forces the target to say silly things when trying to chat.",
                ["whip"] = "Slaps the target multiple times in a row.",
                ["teleport"] = "Teleports the target to where they are looking.",
                ["upgrade"] = "Upgrades the target's currently held weapon.",
                ["cloak"] = "Makes the target temporarily invisible.",
                ["god"] = "Makes the target temporarily invincible.",
                ["noclip"] = "Temporarily lets the target fly through walls.",
                ["armor"] = "The target takes reduced damage until armor runs out.",
                ["credit"] = "Gives the target a credit.",
                ["maul"] = "Spawns 4 fast zombies around the target.",
                ["hp"] = "Sets the health of the target. Must be from 1 to 200.",
                ["voteban"] = "Starts a vote to ban the target from the server.", -- Again, not real, don't panic
                ["forcenr"] = "Choose your role for next round"
            }

            dcommands.OnRowSelected = function(_, _, row)
                dparams:Clear()
                local command = row:GetValue(1)
                local cost = commandCvars[command]:GetInt()
                local dtargetLabel = vgui.Create("DLabel", dparams)
                dtargetLabel:SetFont("TabLarge")
                dtargetLabel:SetText("Target:")
                dtargetLabel:SetWidth(listWidth)
                dtargetLabel:SetPos(0, -m)
                local dtarget = vgui.Create("DListView", dparams)
                dtarget:SetSize(listWidth, listHeight)
                dtarget:SetPos(0, labelHeight)
                dtarget:SetHideHeaders(true)
                dtarget:SetMultiSelect(false)
                dtarget:AddColumn("Players")

                for _, p in player.Iterator() do
                    -- Skip players who are true spectators, not just dead players
                    if p:IsSpec() and p:GetRole() == ROLE_NONE then continue end
                    local sid64 = p:SteamID64()
                    dtarget:AddLine(p:Nick(), sid64)
                end

                local runX = listWidth + m
                local drunLabel = vgui.Create("DLabel", dparams)
                drunLabel:SetFont("TabLarge")
                drunLabel:SetText("Execute:")
                drunLabel:SetWidth(listWidth)
                drunLabel:SetPos(runX, -m)
                local range = math.floor(100 / cost)
                local time = 1

                if IsTimedCommand(command) then
                    time = math.min(5, range)
                end

                local message = ""
                local drun = vgui.Create("DButton", dparams)
                drun:SetWidth(listWidth)
                drun:SetPos(runX, labelHeight)
                drun:SetText(command)
                drun:SetEnabled(false)

                drun.DoClick = function()
                    local power = self:GetOwner():GetNWInt("TTTAdminPower")

                    if power < cost then
                        self:GetOwner():PrintMessage(HUD_PRINTTALK, "You do not have enough admin power to use this command!")
                    else
                        net.Start("TTTPAPServerConsoleExecuteCommand")
                        net.WriteString(command)
                        local sid64 = dtarget:GetSelected()[1]:GetValue(2)
                        net.WriteUInt64(sid64)

                        if IsTimedCommand(command) then
                            net.WriteUInt(time, 8)
                        elseif HasMessage(command) then
                            net.WriteString(message)
                        end

                        net.SendToServer()

                        if ShouldCloseAfterSelfUse(command) and sid64 == self:GetOwner():SteamID64() then
                            dframe:Close()
                        end
                    end
                end

                dtarget.OnRowSelected = function(_, _, _)
                    drun:SetEnabled(true)
                end

                local costY = buttonHeight + labelHeight
                local dcost = vgui.Create("DLabel", dparams)
                dcost:SetText("Costs " .. cost * time .. " admin power.")
                dcost:SetWidth(listWidth)
                dcost:SetPos(runX, costY)
                local ddesc = vgui.Create("DLabel", dparams)
                ddesc:SetText(descriptions[command])
                ddesc:SetWrap(true)
                ddesc:SetAutoStretchVertical(true)
                ddesc:SetWidth(listWidth)
                ddesc:SetPos(runX, costY + labelHeight + m)

                if IsTimedCommand(command) then
                    local dtimelabel = vgui.Create("DLabel", dparams)
                    dtimelabel:SetWidth(20)
                    dtimelabel:SetPos(runX + listWidth - 20, costY)
                    dtimelabel:SetText(time .. "s")
                    local dtime = vgui.Create("DSlider", dparams)
                    dtime:SetLockY(0.5)
                    dtime:SetSlideX(time / range)
                    dtime:SetTrapInside(true)
                    dtime:SetWidth(listWidth - 20)
                    dtime:SetPos(runX, buttonHeight + labelHeight)
                    dtime:SetNotches(range)
                    Derma_Hook(dtime, "Paint", "Paint", "NumSlider")

                    dtime.OnValueChanged = function(_, x, _)
                        time = math.max(math.ceil(x * range), 1)
                        dtimelabel:SetText(time .. "s")
                        dcost:SetText("Costs " .. cost * time .. " admin power.")
                    end

                    dcost:SetPos(runX, costY + labelHeight + m)
                    ddesc:SetPos(runX, costY + (labelHeight + m) * 2)
                elseif HasMessage(command) then
                    local dmessage = vgui.Create("DTextEntry", dparams)
                    dmessage:SetWidth(listWidth)
                    dmessage:SetPos(listWidth + m, buttonHeight + labelHeight + m)
                    dmessage:SetPlaceholderText("Value/Message")

                    dmessage.OnChange = function()
                        local text = dmessage:GetValue()

                        if not text or #text == 0 then
                            message = ""
                        else
                            message = text
                        end
                    end

                    dcost:SetPos(runX, costY + buttonHeight + m)
                    ddesc:SetPos(runX, costY + buttonHeight + labelHeight + m * 2)
                end
            end

            dframe.OnClose = function()
                hook.Remove("Think", "Admin_Think_" .. self:EntIndex())
            end

            dframe:MakePopup()
            local client = LocalPlayer()

            hook.Add("Think", "Admin_Think_" .. self:EntIndex(), function()
                if not dframe or not IsValid(dframe) then
                    hook.Remove("Think", "Admin_Think_" .. self:EntIndex())

                    return
                end

                local round_state = GetRoundState()

                -- Automatically close the menu when the player dies or the round is in a state where they wouldn't have the weapon anymore
                if not client:Alive() or (round_state ~= ROUND_ACTIVE and round_state ~= ROUND_POST) then
                    dframe:Close()
                    hook.Remove("Think", "Admin_Think_" .. self:EntIndex())
                end
            end)

            -- Overriding the chat message net message because for some reason,
            -- if this net message doesn't receive a player as the first chat message, it returns out and nothing gets printed...
            -- All of the admin messages from the base role set ADMIN_MESSAGE_PLAYER in their first message
            -- So I think leaving this if-else block in was an oversight when it was copy-pasted by Nick...
            --[[
                if i == 1 then
                    admin = value
                    if value == sid64 then
                        table.insert(message, colorSelf)
                        table.insert(message, "You")
                    else
                        local ply = player.GetBySteamID64(value)
                        if not IsPlayer(ply) then return end <-- this is the culprit... why??? just print it ugh...
                        table.insert(message, colorPlayer)
                        table.insert(message, ply:Nick())
                    end
                ]]
            local colorText = Color(151, 211, 255)
            local colorPlayer = Color(0, 201, 0)
            local colorSelf = Color(75, 0, 130)
            local colorVariable = Color(0, 255, 0)

            net.Receive("TTT_AdminMessage", function()
                local sid64 = LocalPlayer():SteamID64()
                local count = net.ReadUInt(4)
                local admin
                local message = {}
                local silentCommand

                for i = 1, count do
                    local type = net.ReadUInt(2)
                    local value = net.ReadString()

                    if i == 1 and value == "(SILENT) " then
                        silentCommand = true
                    end

                    if type == ADMIN_MESSAGE_TEXT then
                        table.insert(message, colorText)
                        table.insert(message, value)
                    elseif type == ADMIN_MESSAGE_PLAYER then
                        if value == sid64 then
                            table.insert(message, colorSelf)

                            if value == admin then
                                table.insert(message, "Yourself")
                            else
                                table.insert(message, "You")
                            end
                        elseif value == admin then
                            table.insert(message, colorPlayer)
                            table.insert(message, "Themselves")
                        else
                            local ply = player.GetBySteamID64(value)
                            if not IsPlayer(ply) then return end
                            table.insert(message, colorPlayer)
                            table.insert(message, ply:Nick())
                        end
                    elseif type == ADMIN_MESSAGE_VARIABLE then
                        table.insert(message, colorVariable)
                        table.insert(message, value)
                    end

                    if (i == 1 and not silentCommand) or (i == 2 and silentCommand) then
                        admin = value
                    end
                end

                if #message > 0 then
                    chat.AddText(unpack(message))
                end
            end)

            -- 
            -- psay
            -- 
            net.Receive("TTTPAPServerConsolePsay", function()
                local message = net.ReadString()
                local TextData = {}
                TextData.color = COLOR_WHITE
                TextData.font = "TTTPAPServerConsolePsay"

                TextData.pos = {ScrW() / 2, ScrH() / 4}

                TextData.text = message
                TextData.xalign = TEXT_ALIGN_CENTER
                TextData.yalign = TEXT_ALIGN_CENTER
                local shadowDist = 2

                hook.Add("DrawOverlay", "TTTPAPServerConsolePsayDrawText", function()
                    draw.DrawText(TextData.text, TextData.font, TextData.pos[1] + shadowDist, TextData.pos[2] + shadowDist, COLOR_BLACK, TextData.xalign)
                    draw.DrawText(TextData.text, TextData.font, TextData.pos[1], TextData.pos[2], TextData.color, TextData.xalign)
                end)

                timer.Create("TTTPAPServerConsolePsayDrawText", 5, 1, function()
                    hook.Remove("DrawOverlay", "TTTPAPServerConsolePsayDrawText")
                end)
            end)

            -- 
            -- voteban
            -- 
            local voteBanWindow

            net.Receive("TTTPAPServerConsoleVoteBan", function()
                local admin = net.ReadPlayer()
                local target = net.ReadPlayer()
                local votesNeeded = net.ReadUInt(8)
                local reason = net.ReadString()

                voteBanWindow = Derma_Query("Should " .. target:Nick() .. " be banned from the server?\n" .. votesNeeded .. " yes votes needed.\nReason: " .. reason, admin:Nick() .. " the " .. ROLE_STRINGS[ROLE_ADMIN] .. " asks:", "Yes", function()
                    net.Start("TTTPAPServerConsoleVoteVoted")
                    net.WriteBool(true)
                    net.SendToServer()
                end, "No", function()
                    net.Start("TTTPAPServerConsoleVoteVoted")
                    net.WriteBool(false)
                    net.SendToServer()
                end)
            end)

            local votebanScreenMat = Material("ui/roles/adm/kickScreen.png")

            net.Receive("TTTPAPServerConsoleVotePassed", function()
                local admin = net.ReadPlayer()
                local target = net.ReadPlayer()
                local votePassed = net.ReadBool()
                local reason = net.ReadString()
                local localPly = LocalPlayer()

                if IsValid(voteBanWindow) then
                    voteBanWindow:Close()
                end

                -- Credit goes to Nick for this code block taken from: jingle_jam_2023_roles_pack_cr_for_ttt\lua\customroles\admin.lua
                -- A modified version of the TTT_AdminKickClient net message
                if votePassed and target == localPly then
                    hook.Add("HUDShouldDraw", "Admin_HUDShouldDraw_VoteBan", function(name)
                        if name ~= "CHudGMod" then return false end
                    end)

                    hook.Add("PlayerBindPress", "Admin_PlayerBindPress_VoteBan", function(ply, bind, pressed)
                        if string.find(bind, "+showscores") then return true end
                    end)

                    hook.Add("Think", "Admin_Think_VoteBan", function()
                        localPly:ConCommand("soundfade 100 1")
                    end)

                    local window = vgui.Create("DFrame")
                    window:SetSize(ScrW(), ScrH())
                    window:SetPos(0, 0)
                    window:SetTitle("")
                    window:SetVisible(true)
                    window:SetDraggable(false)
                    window:ShowCloseButton(false)
                    window:SetMouseInputEnabled(true)
                    window:SetDeleteOnClose(true)
                    window.Paint = function() end
                    local overlayPanel = vgui.Create("DPanel", window)
                    overlayPanel:SetSize(window:GetWide(), window:GetTall())
                    overlayPanel:SetPos(0, 0)

                    overlayPanel.Paint = function(_, w, h)
                        surface.SetDrawColor(COLOR_WHITE)
                        surface.SetMaterial(votebanScreenMat)
                        surface.DrawTexturedRect(0, 0, w, h)
                    end

                    local dpanel = vgui.Create("DPanel", window)
                    dpanel:SetSize(380, 132)
                    dpanel:Center()

                    dpanel.Paint = function(_, w, h)
                        surface.SetDrawColor(115, 115, 115, 245)
                        surface.DrawRect(0, 0, w, h)
                        surface.SetDrawColor(0, 0, 0, 255)
                        surface.DrawOutlinedRect(0, 0, w, h, 1)
                    end

                    local dlabel = vgui.Create("DLabel", dpanel)
                    dlabel:SetWrap(true)
                    dlabel:SetAutoStretchVertical(true)
                    dlabel:SetSize(340, 48)
                    dlabel:SetPos(20, 20)
                    dlabel:SetFont("KickText")
                    local message = "Disconnect: Banned by " .. admin:Nick()
                    message = message .. " - " .. reason
                    dlabel:SetText(message)
                    local dbutton = vgui.Create("DButton", dpanel)
                    dbutton:SetSize(72, 24)
                    dbutton:SetPos(288, 88)
                    dbutton:SetFont("KickText")
                    dbutton:SetText("Close")

                    dbutton.Paint = function(_, w, h)
                        surface.SetDrawColor(228, 228, 228, 255)
                        surface.DrawRect(0, 0, w, h)
                        surface.SetDrawColor(0, 0, 0, 255)
                        surface.DrawOutlinedRect(0, 0, w, h, 1)
                    end

                    dbutton.DoClick = function()
                        hook.Remove("HUDShouldDraw", "Admin_HUDShouldDraw_VoteBan")
                        hook.Remove("PlayerBindPress", "Admin_PlayerBindPress_VoteBan")
                        hook.Remove("Think", "Admin_Think_VoteBan")
                        window:Close()
                    end

                    window:MakePopup()
                end
            end)
        end
    end

    -- 
    -- Now creating the new admin commands...
    -- 
    if SERVER then
        -- I re-wrote this part from the way Nick did it, so everything is all dynamic
        -- from here this is actually mostly my own code, hooray!
        util.AddNetworkString("TTTPAPServerConsoleExecuteCommand")
        local commandFunctions = {}

        net.Receive("TTTPAPServerConsoleExecuteCommand", function(_, admin)
            local command = net.ReadString()
            local CommandFunction = commandFunctions[command]
            local target = player.GetBySteamID64(net.ReadUInt64())
            local time = 1
            local message = ""

            if IsTimedCommand(command) then
                time = net.ReadUInt(8)
            elseif HasMessage(command) then
                message = net.ReadString()
            end

            local cost = commandCvars[command]:GetInt() * time
            local power = admin:GetNWInt("TTTAdminPower")
            if power < cost then return end
            -- Check executing player is an admin, and the target is a player
            if not IsPlayer(admin) or not admin:IsActiveAdmin() or not IsPlayer(target) then return end

            -- Check the target is not dead
            if not target:IsActive() then
                admin:PrintMessage(HUD_PRINTTALK, target:Nick() .. " is dead. Your admin power was not used.")

                return
            end

            -- Check the command's condition function if it has one
            local ConditionFunction = commandFunctions[command .. "_condition"]

            if ConditionFunction then
                local errorMsg = ConditionFunction(admin, target, time, message)

                if isstring(errorMsg) then
                    admin:PrintMessage(HUD_PRINTTALK, errorMsg .. ". Your admin power was not used.")

                    return
                end
            end

            -- Otherwise, command away!
            local chatMessages = CommandFunction(admin, target, time, message)

            if chatMessages then
                admin:SetNWInt("TTTAdminPower", power - cost)
                net.Start("TTT_AdminMessage")

                if SilentChatMessage(command) then
                    table.insert(chatMessages, 1, {ADMIN_MESSAGE_TEXT, "(SILENT) "})
                elseif IsTimedCommand(command) then
                    table.insert(chatMessages, {ADMIN_MESSAGE_TEXT, " for "})

                    table.insert(chatMessages, {ADMIN_MESSAGE_VARIABLE, time})

                    table.insert(chatMessages, {ADMIN_MESSAGE_TEXT, " seconds"})
                end

                net.WriteUInt(#chatMessages, 4)

                -- Each admin command chat message is a pair of an enumerator telling what kind of message text it is, and the message itself as a string
                -- (defined in lua/customroles/admin.lua from the JJ 2023 Roles Pack)
                for _, messageTable in ipairs(chatMessages) do
                    net.WriteUInt(messageTable[1], 2)
                    net.WriteString(messageTable[2])
                end

                if SilentChatMessage(command) then
                    net.Send(admin)
                else
                    net.Broadcast()
                end
            end
        end)

        -- 
        -- mute
        -- 
        local replacementMessages = {
            "trap at door", "traitor trap get back", "bloxwich", "get behind a wall", "go back", "throwing bomb get back", "that didn't work oops", "gonna die and possess", "what did you do?", string.upper, string.reverse, function(text, sender)
                for _, ply in player.Iterator() do
                    if self:IsAlive(ply) and ply ~= sender then return ply:Nick() end
                end
            end
        }

        commandFunctions.mute = function(admin, target)
            target.PAPServerConsoleMute = true

            self:AddHook("PlayerSay", function(sender, text, teamChat)
                if sender.PAPServerConsoleMute then
                    local newMsg = replacementMessages[math.random(#replacementMessages)]

                    if isfunction(newMsg) then
                        newMsg = newMsg(text, sender)
                    end

                    return newMsg
                end
            end)

            -- You need to pass a player's ply:SteamID64() in order to display a player's name in chat properly,
            -- I guess a ply:Nick() will work too, just without fancy colouring
            return {
                {ADMIN_MESSAGE_PLAYER, admin:SteamID64()},
                {ADMIN_MESSAGE_TEXT, " muted "},
                {ADMIN_MESSAGE_PLAYER, target:SteamID64()}
            }
        end

        commandFunctions.mute_condition = function(admin, target)
            if target.PAPServerConsoleMute then return target:Nick() .. " is already muted!" end
        end

        -- 
        -- playsound
        -- 
        -- Just play a random sound from the entire library of Pack-a-Punch upgrade sounds lol (There's a lot of funny ones in there)
        local papSounds = {}
        local sounds, directories = file.Find("sound/ttt_pack_a_punch/*", "GAME")

        for _, snd in ipairs(sounds) do
            table.insert(papSounds, "ttt_pack_a_punch/" .. snd)
        end

        for _, dir in ipairs(directories) do
            local dirSounds = file.Find("sound/ttt_pack_a_punch/" .. dir .. "/*", "GAME")

            for _, snd in ipairs(dirSounds) do
                table.insert(papSounds, "ttt_pack_a_punch/" .. dir .. "/" .. snd)
            end
        end

        commandFunctions.playsound = function(admin, target)
            target:EmitSound(papSounds[math.random(#papSounds)], 100, math.random(75, 125))

            return {
                {ADMIN_MESSAGE_PLAYER, admin:SteamID64()},
                {ADMIN_MESSAGE_TEXT, " played a sound on "},
                {ADMIN_MESSAGE_PLAYER, target:SteamID64()}
            }
        end

        -- 
        -- psay
        -- 
        util.AddNetworkString("TTTPAPServerConsolePsay")

        commandFunctions.psay = function(admin, target, time, message)
            net.Start("TTTPAPServerConsolePsay")
            net.WriteString(message)
            net.Send(target)

            return {
                {ADMIN_MESSAGE_PLAYER, admin:SteamID64()},
                {ADMIN_MESSAGE_TEXT, " displayed \""},
                {ADMIN_MESSAGE_VARIABLE, message},
                {ADMIN_MESSAGE_TEXT, "\" to "},
                {ADMIN_MESSAGE_PLAYER, target:SteamID64()}
            }
        end

        commandFunctions.psay_condition = function(admin, target, time, message)
            if message == "" then return "Type a message first" end
        end

        -- 
        -- whip
        -- 
        local whipSounds = {"physics/body/body_medium_impact_hard1.wav", "physics/body/body_medium_impact_hard2.wav", "physics/body/body_medium_impact_hard3.wav", "physics/body/body_medium_impact_hard5.wav", "physics/body/body_medium_impact_hard6.wav", "physics/body/body_medium_impact_soft5.wav", "physics/body/body_medium_impact_soft6.wav", "physics/body/body_medium_impact_soft7.wav",}

        local power = 350

        commandFunctions.whip = function(admin, target, time, message)
            local timerName = "TTTPAPServerConsoleWhip" .. target:SteamID64()

            timer.Create(timerName, 0.5, time * 2, function()
                if not IsValid(target) or not self:IsAlive(target) or GetRoundState() ~= ROUND_ACTIVE then
                    timer.Remove(timerName)

                    return
                end

                if target:InVehicle() then
                    target:ExitVehicle()
                end

                target:EmitSound(whipSounds[math.random(#whipSounds)])
                local direction = Vector(math.random(-10, 10), math.random(-10, 10), 10)
                direction:Normalize()
                target:SetVelocity(direction * power)
                local angle_punch_pitch = math.random(-20, 20)
                local angle_punch_yaw = math.sqrt(400 - angle_punch_pitch * angle_punch_pitch)

                if math.random() < 0.5 then
                    angle_punch_yaw = angle_punch_yaw * -1
                end

                target:ViewPunch(Angle(angle_punch_pitch, angle_punch_yaw, 0))
            end)

            return {
                {ADMIN_MESSAGE_PLAYER, admin:SteamID64()},
                {ADMIN_MESSAGE_TEXT, " whipped "},
                {ADMIN_MESSAGE_PLAYER, target:SteamID64()}
            }
        end

        commandFunctions.whip_condition = function(admin, target, time, message)
            if timer.Exists("TTTPAPServerConsoleWhip" .. target:SteamID64()) then return target:Nick() .. " is already being whipped" end
        end

        -- 
        -- teleport
        -- 
        commandFunctions.teleport = function(admin, target, time, message)
            local hitPos = target:GetEyeTrace().HitPos
            target:SetPos(hitPos)
            self:UnstuckPlayer(target)

            return {
                {ADMIN_MESSAGE_PLAYER, admin:SteamID64()},
                {ADMIN_MESSAGE_TEXT, " teleported "},
                {ADMIN_MESSAGE_PLAYER, target:SteamID64()}
            }
        end

        -- 
        -- upgrade
        -- 
        commandFunctions.upgrade = function(admin, target, time, message)
            TTTPAP:OrderPAP(target)

            return {
                {ADMIN_MESSAGE_PLAYER, admin:SteamID64()},
                {ADMIN_MESSAGE_TEXT, " upgraded "},
                {ADMIN_MESSAGE_PLAYER, target:SteamID64()},
                {ADMIN_MESSAGE_TEXT, "'s weapon"}
            }
        end

        commandFunctions.upgrade_condition = function(admin, target, time, message)
            local canPaP, errorMsg = TTTPAP:CanOrderPAP(target)
            if not canPaP then return errorMsg end
        end

        -- 
        -- cloak
        -- 
        commandFunctions.cloak = function(admin, target, time, message)
            target:SetColor(Color(255, 255, 255, 0))
            target:DrawShadow(false)
            target:SetMaterial("models/effects/vol_light001")
            target:SetRenderMode(RENDERMODE_TRANSALPHA)
            target:EmitSound("ttt_pack_a_punch/server_console/cloak.mp3")

            timer.Simple(time, function()
                if self:IsAlivePlayer(target) and (GetRoundState() == ROUND_ACTIVE or GetRoundState() == ROUND_POST) then
                    target:SetColor(Color(255, 255, 255, 255))
                    target:DrawShadow(true)
                    target:SetMaterial("")
                    target:SetRenderMode(RENDERMODE_NORMAL)
                    target:EmitSound("ttt_pack_a_punch/server_console/uncloak.mp3")
                end
            end)

            return {
                {ADMIN_MESSAGE_PLAYER, admin:SteamID64()},
                {ADMIN_MESSAGE_TEXT, " cloaked "},
                {ADMIN_MESSAGE_PLAYER, target:SteamID64()}
            }
        end

        commandFunctions.cloak_condition = function(admin, target, time, message)
            if target:GetMaterial() == "models/effects/vol_light001" then return target:Nick() .. "is already cloaked" end
        end

        -- 
        -- god
        -- 
        commandFunctions.god = function(admin, target, time, message)
            -- Function from base custom roles, adds fancy effects, hover text info, and distinct hitmarker sounds, used for the good/evil twin roles
            target:SetInvulnerable(true, true)

            timer.Simple(time, function()
                if self:IsAlivePlayer(target) and (GetRoundState() == ROUND_ACTIVE or GetRoundState() == ROUND_POST) then
                    target:SetInvulnerable(false, true)
                end
            end)

            return {
                {ADMIN_MESSAGE_PLAYER, admin:SteamID64()},
                {ADMIN_MESSAGE_TEXT, " granted "},
                {ADMIN_MESSAGE_PLAYER, target:SteamID64()},
                {ADMIN_MESSAGE_TEXT, " god mode"}
            }
        end

        commandFunctions.god_condition = function(admin, target, time, message)
            if target:IsInvulnerable() then return target:Nick() .. "already has god mode" end
        end

        -- 
        -- noclip
        -- 
        commandFunctions.noclip = function(admin, target, time, message)
            target:SetMoveType(MOVETYPE_NOCLIP)

            timer.Simple(time, function()
                if self:IsAlivePlayer(target) and (GetRoundState() == ROUND_ACTIVE or GetRoundState() == ROUND_POST) then
                    target:SetMoveType(MOVETYPE_WALK)

                    -- Give players a moment to get unstuck if they are currently stuck
                    timer.Simple(4, function()
                        if self:IsAlivePlayer(target) and not target:IsInWorld() or not self:PlayerNotStuck(target) then
                            local oldHealth = target:Health()
                            target:Spawn()
                            target:SetHealth(oldHealth)
                            -- Yep this is the vine boom sound effect... Remember Vine? Anyone?
                            target:EmitSound("ttt_pack_a_punch/dramatic_death_note/vine_boom.mp3")
                            target:ChatPrint("You were stuck and respawned!")
                        end
                    end)
                end
            end)

            return {
                {ADMIN_MESSAGE_PLAYER, admin:SteamID64()},
                {ADMIN_MESSAGE_TEXT, " granted "},
                {ADMIN_MESSAGE_PLAYER, target:SteamID64()},
                {ADMIN_MESSAGE_TEXT, " noclip"}
            }
        end

        commandFunctions.noclip_condition = function(admin, target, time, message)
            if target:GetMoveType() == MOVETYPE_NOCLIP then return target:Nick() .. " already has noclip" end
        end

        -- 
        -- armor
        -- 
        commandFunctions.armor = function(admin, target, time, message)
            self:SetShield(target, 100, 10)

            return {
                {ADMIN_MESSAGE_PLAYER, admin:SteamID64()},
                {ADMIN_MESSAGE_TEXT, " granted "},
                {ADMIN_MESSAGE_PLAYER, target:SteamID64()},
                {ADMIN_MESSAGE_TEXT, " armor"}
            }
        end

        commandFunctions.armor_condition = function(admin, target, time, message)
            if target:GetNWInt("PAPHealthShield", 0) > 0 then return target:Nick() .. " already has armor" end
        end

        -- 
        -- credit
        -- 
        commandFunctions.credit = function(admin, target, time, message)
            target:AddCredits(1)

            return {
                {ADMIN_MESSAGE_PLAYER, admin:SteamID64()},
                {ADMIN_MESSAGE_TEXT, " gave "},
                {ADMIN_MESSAGE_PLAYER, target:SteamID64()},
                {ADMIN_MESSAGE_TEXT, " "},
                {ADMIN_MESSAGE_VARIABLE, 1},
                {ADMIN_MESSAGE_TEXT, " credit"}
            }
        end

        -- 
        -- maul
        -- 
        commandFunctions.maul = function(admin, target, time, message)
            local pos = target:GetPos()

            local spawns = {pos + Vector(50, 0, 0), pos + Vector(0, 50, 0), pos + Vector(-50, 0, 0), pos + Vector(0, -50, 0)}

            for _, spawn in ipairs(spawns) do
                local zombie = ents.Create("npc_fastzombie")
                zombie:SetPos(spawn)
                zombie.TTTPAPServerConsoleMaulZombie = true
                zombie:Spawn()
            end

            -- Increases the damage dealt by the spawned fast zombies
            self:AddHook("EntityTakeDamage", function(ent, dmg)
                local attacker = dmg:GetAttacker()

                if IsValid(attacker) and attacker.TTTPAPServerConsoleMaulZombie then
                    dmg:SetDamage(6)
                end
            end)

            return {
                {ADMIN_MESSAGE_PLAYER, admin:SteamID64()},
                {ADMIN_MESSAGE_TEXT, " mauled "},
                {ADMIN_MESSAGE_PLAYER, target:SteamID64()}
            }
        end

        -- 
        -- hp
        -- 
        commandFunctions.hp = function(admin, target, time, message)
            local hp = tonumber(message)
            target:SetHealth(hp)

            return {
                {ADMIN_MESSAGE_PLAYER, admin:SteamID64()},
                {ADMIN_MESSAGE_TEXT, " set the hp for "},
                {ADMIN_MESSAGE_PLAYER, target:SteamID64()},
                {ADMIN_MESSAGE_TEXT, " to "},
                {ADMIN_MESSAGE_VARIABLE, hp}
            }
        end

        commandFunctions.hp_condition = function(admin, target, time, message)
            local hp = tonumber(message)
            if not hp or hp < 1 or hp > 200 then return "Type a number between 1 and 200 in the box" end
        end

        -- 
        -- voteban
        -- 
        util.AddNetworkString("TTTPAPServerConsoleVoteBan")
        util.AddNetworkString("TTTPAPServerConsoleVoteVoted")
        util.AddNetworkString("TTTPAPServerConsoleVotePassed")

        commandFunctions.voteban = function(admin, target, time, reason)
            if reason == "" then
                reason = "No reason given"
            end

            local yesCount = 0
            local noCount = 0
            local playerCount = player.GetCount()
            -- 50% of players rounded up need to vote yes to "ban"
            local votesNeeded = math.ceil(playerCount / 2)
            net.Start("TTTPAPServerConsoleVoteBan")
            net.WritePlayer(admin)
            net.WritePlayer(target)
            net.WriteUInt(votesNeeded, 8)
            net.WriteString(reason)
            net.Broadcast()

            net.Receive("TTTPAPServerConsoleVoteVoted", function(_, ply)
                local yesVote = net.ReadBool()
                BroadcastLua("surface.PlaySound(\"ttt_pack_a_punch/server_console/vote.mp3\")")

                if yesVote then
                    yesCount = yesCount + 1
                    PrintMessage(HUD_PRINTTALK, ply:Nick() .. " voted to ban " .. target:Nick())
                else
                    noCount = noCount + 1
                    PrintMessage(HUD_PRINTTALK, ply:Nick() .. " voted *not* to ban " .. target:Nick())
                end

                -- If we have enough votes, end voting for everyone, and "ban" the player if voted out
                if votesNeeded >= yesCount + noCount then
                    local votePassed

                    if yesCount >= votesNeeded then
                        local msg = target:Nick() .. " has been banned from the server!"
                        PrintMessage(HUD_PRINTCENTER, msg)
                        PrintMessage(HUD_PRINTTALK, msg)
                        BroadcastLua("surface.PlaySound(\"ttt_pack_a_punch/dramatic_death_note/vine_boom.mp3\")")
                        votePassed = true

                        if self:IsAlivePlayer(target) then
                            -- On passing, kill the banned player, and keep them dead!
                            target:Kill()
                            target.TTTPAPServerConsoleVoteBanned = true

                            self:AddHook("PlayerSpawn", function(p)
                                timer.Simple(0.1, function()
                                    if p.TTTPAPServerConsoleVoteBanned then
                                        p:Kill()
                                        local message = "No respawning for you! You've been banned! (For this round)"
                                        p:PrintMessage(HUD_PRINTCENTER, message)
                                        p:PrintMessage(HUD_PRINTTALK, message)
                                    end
                                end)
                            end)
                        end
                    elseif noCount >= votesNeeded then
                        local msg = "The vote to ban " .. target:Nick() .. " has failed!"
                        PrintMessage(HUD_PRINTCENTER, msg)
                        PrintMessage(HUD_PRINTTALK, msg)
                        BroadcastLua("surface.PlaySound(\"ttt_pack_a_punch/dramatic_death_note/lego_yoda.mp3\")")
                        votePassed = false
                    end

                    net.Start("TTTPAPServerConsoleVotePassed")
                    net.WritePlayer(admin)
                    net.WritePlayer(target)
                    net.WriteBool(votePassed)
                    net.WriteString(reason)
                    net.Broadcast()
                end
            end)

            return {
                {ADMIN_MESSAGE_PLAYER, admin:SteamID64()},
                {ADMIN_MESSAGE_TEXT, " started a voteban for "},
                {ADMIN_MESSAGE_PLAYER, target:SteamID64()},
                {ADMIN_MESSAGE_TEXT, "\nReason: "},
                {ADMIN_MESSAGE_VARIABLE, reason}
            }
        end

        commandFunctions.voteban_condition = function(admin, target, time, message)
            if target.PAPServerConsoleVoteBan then return target:Nick() .. " has already had a vote cast on them" end
        end

        -- 
        -- forcenr
        -- 
        commandFunctions.forcenr = function(admin, target, time, message)
            if admin:GetForcedRole() then
                admin:ClearForcedRole()
            end

            local forcedRole = forcedRoles[admin:SteamID()]
            admin:ForceRoleNextRound(forcedRole.role)

            -- Ensuring the selected role is also set if the map changes before the next round
            hook.Add("ShutDown", "TTTPAPServerConsoleSaveForcedRoles", function()
                file.CreateDir("ttt_pack_a_punch")
                file.Write("ttt_pack_a_punch/server_console_saved_roles.json", util.TableToJSON(forcedRoles))
            end)

            return {
                {ADMIN_MESSAGE_PLAYER, admin:SteamID64()},
                {ADMIN_MESSAGE_TEXT, " marked "},
                {ADMIN_MESSAGE_PLAYER, target:SteamID64()},
                {ADMIN_MESSAGE_TEXT, " to be "},
                {ADMIN_MESSAGE_VARIABLE, forcedRole.name},
                {ADMIN_MESSAGE_TEXT, " next round"}
            }
        end

        commandFunctions.forcenr_condition = function(admin, target, time, message)
            if admin ~= target then return "You can only target yourself" end
            if #message < 3 then return "Type in a role" end

            for role = 0, ROLE_MAX do
                local name = string.lower(ROLE_STRINGS[role])

                if name:find(message) then
                    if role == ROLE_ADMIN then return "You cannot choose to become " .. ROLE_STRINGS_EXT[ROLE_ADMIN] end
                    name = ROLE_STRINGS_EXT[role]

                    forcedRoles[admin:SteamID()] = {
                        ["role"] = role,
                        ["name"] = name
                    }

                    return
                elseif role == ROLE_MAX then
                    return "Role not found"
                end
            end
        end
    end
end

function UPGRADE:Reset()
    for _, ply in player.Iterator() do
        ply.PAPServerConsoleMute = nil
        ply.PAPServerConsoleVoteBan = nil
        ply.TTTPAPServerConsoleVoteBanned = nil
    end
end

TTTPAP:Register(UPGRADE)