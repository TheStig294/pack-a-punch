local UPGRADE = {}
UPGRADE.id = "server_console"
UPGRADE.class = "weapon_ttt_adm_menu"
UPGRADE.name = "Server Console"
UPGRADE.desc = "More powerful set of commands!"
UPGRADE.convars = {}

-- Fancy dynamic convar creation because I can't be bothered to do it manually
local defaultCommandCosts = {
    gimp = 10,
    playsound = 10,
    csay = 15,
    whip = 20,
    teleport = 30,
    upgrade = 40,
    armor = 50,
    credit = 60,
    hp = 70,
    maul = 80,
    noclip = 90,
    cloak = 90,
    god = 90,
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

    local function CantTargetSelf(command)
        return
    end

    local function ShouldCloseAfterSelfUse(command)
        return command == "whip" or command == "teleport" or command == "upgrade" or command == "force"
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
                ["gimp"] = "Forces the target to say silly things on trying to chat.",
                ["playsound"] = "Plays a sound for the target.",
                ["csay"] = "Sends a message to everyone in the middle of the screen.",
                ["whip"] = "Slaps the target multiple times in a row.",
                ["teleport"] = "Teleports the target to where they are looking.",
                ["upgrade"] = "Upgrades the target's currently held weapon.",
                ["armor"] = "The target takes reduced damage until armor runs out.",
                ["credit"] = "Gives the target a credit.",
                ["hp"] = "Sets the health of the target.",
                ["maul"] = "Spawns 4 fast zombies around the target.",
                ["noclip"] = "Temporarily lets the target fly through walls.",
                ["cloak"] = "Makes the target temporarily invisible.",
                ["god"] = "Makes the target temporarily invincible.",
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
                local ownerSid64 = self:GetOwner():SteamID64()

                for _, p in PlayerIterator() do
                    -- Skip players who are true spectators, not just dead players
                    if p:IsSpec() and p:GetRole() == ROLE_NONE then continue end
                    local sid64 = p:SteamID64()
                    if sid64 == ownerSid64 and CantTargetSelf(command) then continue end
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
                        net.Start("TTT_Admin" .. command:gsub("^%l", string.upper) .. "Command")
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
        end
    end
end

TTTPAP:Register(UPGRADE)