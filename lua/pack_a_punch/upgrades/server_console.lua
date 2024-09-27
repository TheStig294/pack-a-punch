local UPGRADE = {}
UPGRADE.id = "server_console"
UPGRADE.class = "weapon_ttt_adm_menu"
UPGRADE.name = "Server Console"
UPGRADE.desc = "More powerful set of commands!"
UPGRADE.convars = {}

-- Fancy dynamic convar creation because I can't be bothered to do it manually
local defaultCommandCosts = {
    mute = 10,
    playsound = 10,
    csay = 15,
    whip = 4, -- 20 power for 5 seconds
    teleport = 30,
    upgrade = 40,
    noclip = 9, -- 45 power for 5 seconds
    cloak = 9,
    god = 9,
    armor = 50,
    credit = 60,
    hp = 70,
    maul = 80,
    voteban = 90, -- not real, don't panic
    force = 100
}

local commands = table.GetKeys(defaultCommandCosts)
local commandCvars = {}

local function IsTimedCommand(command)
    return command == "whip" or command == "noclip" or command == "cloak" or command == "god"
end

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

function UPGRADE:Apply(SWEP)
    -- All of this code is made by Nick, taken from the Admin role's device:
    -- https://github.com/Custom-Roles-for-TTT/TTT-Jingle-Jam-Roles-2023/blob/main/gamemodes/terrortown/entities/weapons/weapon_ttt_adm_menu.lua
    -- (Because I can't be bothered doing a PR to make this all modular and there's no avoiding copying all this otherwise...)
    local hook = hook
    local math = math
    local player = player
    local table = table
    local PlayerIterator = player.Iterator
    local TableInsert = table.insert

    local function ShouldCloseAfterSelfUse(command)
        return command == "whip" or command == "teleport" or command == "upgrade" or command == "force"
    end

    local function SilentChatMessage(command)
        return command == "mute"
    end

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
                    TableInsert(validCommands, {
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
                ["mute"] = "Forces the target to say silly things on trying to chat.",
                ["playsound"] = "Plays a sound for the target.",
                ["csay"] = "Sends a message to everyone in the middle of the screen.",
                ["whip"] = "Slaps the target multiple times in a row.",
                ["teleport"] = "Teleports the target to where they are looking.",
                ["upgrade"] = "Upgrades the target's currently held weapon.",
                ["noclip"] = "Temporarily lets the target fly through walls.",
                ["cloak"] = "Makes the target temporarily invisible.",
                ["god"] = "Makes the target temporarily invincible.",
                ["armor"] = "The target takes reduced damage until armor runs out.",
                ["credit"] = "Gives the target a credit.",
                ["hp"] = "Sets the health of the target.",
                ["maul"] = "Spawns 4 fast zombies around the target.",
                ["voteban"] = "Starts a vote to ban the target from the server.", -- Again, not real, don't panic
                ["force"] = "Change the target to a role other than your own."
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

                for _, p in PlayerIterator() do
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

                local reason = "No reason given"
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
                        elseif command == "voteban" then
                            net.WriteString(reason)
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
                elseif command == "voteban" then
                    local dreason = vgui.Create("DTextEntry", dparams)
                    dreason:SetWidth(listWidth)
                    dreason:SetPos(listWidth + m, buttonHeight + labelHeight + m)
                    dreason:SetPlaceholderText("Reason")

                    dreason.OnChange = function()
                        local text = dreason:GetValue()

                        if not text or #text == 0 then
                            reason = "No reason given"
                        else
                            reason = text
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

                for i = 1, count do
                    local type = net.ReadUInt(2)
                    local value = net.ReadString()

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
                end

                if #message > 0 then
                    chat.AddText(unpack(message))
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
            local reason

            if IsTimedCommand(command) then
                time = net.ReadUInt(8)
            elseif command == "voteban" then
                reason = net.ReadString()
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
                local errorMsg = ConditionFunction(admin, target, time, reason)

                if isstring(errorMsg) then
                    admin:PrintMessage(HUD_PRINTTALK, errorMsg .. ". Your admin power was not used.")

                    return
                end
            end

            -- Otherwise, command away!
            local chatMessages = CommandFunction(admin, target, time, reason)

            if chatMessages then
                admin:SetNWInt("TTTAdminPower", power - cost)
                net.Start("TTT_AdminMessage")

                if SilentChatMessage(command) then
                    table.insert(chatMessages, 1, {ADMIN_MESSAGE_TEXT, "(SILENT) "})
                end

                net.WriteUInt(#chatMessages, 4)

                -- Each admin command chat message is a pair of an enumerator telling what kind of message text it is, and the message itself as a string
                -- (defined in lua/customroles/admin.lua from the JJ 2023 Roles Pack)
                for _, message in ipairs(chatMessages) do
                    net.WriteUInt(message[1], 2)
                    net.WriteString(message[2])
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
                    if UPGRADE:IsAlive(ply) and ply ~= sender then return ply:Nick() end
                end
            end
        }

        commandFunctions.mute = function(admin, target)
            target.PAPServerConsoleMute = true

            UPGRADE:AddHook("PlayerSay", function(sender, text, teamChat)
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
        commandFunctions.playsound = function(admin, target)
            -- 
            -- ############### TODO: FIND SOME SOUNDS #################### (This is just a test)
            -- 
            target:EmitSound("ui/achievement_earned.wav", 0, math.random(75, 125))

            return {
                {ADMIN_MESSAGE_PLAYER, admin:SteamID64()},
                {ADMIN_MESSAGE_TEXT, " played a sound on "},
                {ADMIN_MESSAGE_PLAYER, target:SteamID64()}
            }
        end
    end
end

function UPGRADE:Reset()
    for _, ply in player.Iterator() do
        ply.PAPServerConsoleMute = nil
    end
end

TTTPAP:Register(UPGRADE)