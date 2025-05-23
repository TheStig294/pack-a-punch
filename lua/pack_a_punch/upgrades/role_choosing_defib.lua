local UPGRADE = {}
UPGRADE.id = "role_choosing_defib"
UPGRADE.class = "weapon_med_defib"
UPGRADE.name = "Role Choosing Defib"
UPGRADE.desc = "You can select the innocent role a player becomes!\n(Right-click)"

UPGRADE.convars = {
    {
        name = "pap_role_choosing_defib_can_become_paramedic",
        type = "bool"
    }
}

local canBecomeMedCvar = CreateConVar("pap_role_choosing_defib_can_become_paramedic", "1", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Allow revived players to become paramedics")

function UPGRADE:Apply(SWEP)
    -- Returns the list of all enabled roles
    local function GetEnabledRoles()
        local enabledRoles = {}
        local allowParamedic = canBecomeMedCvar:GetBool()

        for role, roleString in pairs(ROLE_STRINGS_RAW) do
            if INNOCENT_ROLES[role] and not DETECTIVE_ROLES[role] and TTTPAP:CanRoleSpawn(role) then
                -- Don't allow PaP hypnotist device to turn other players into hypnotists if the convar is disabled
                -- Also don't allow the default innocent role
                if role == ROLE_INNOCENT or (not allowParamedic and role == ROLE_PARAMEDIC) then continue end
                table.insert(enabledRoles, role)
            end
        end

        return enabledRoles
    end

    if SERVER then
        self:AddToHook(SWEP, "PrimaryAttack", function()
            local owner = SWEP:GetOwner()
            if not IsValid(owner) then return end

            if not SWEP.PAPSelectedRole then
                owner:PrintMessage(HUD_PRINTCENTER, "Choose a role with right-click!")
            end
        end)

        util.AddNetworkString("TTTPAPRoleChoosingDefib")

        net.Receive("TTTPAPRoleChoosingDefib", function(len, ply)
            local wep = ply:GetActiveWeapon()
            if not self:IsUpgraded(wep) then return end
            wep.PAPSelectedRole = net.ReadInt(8)
        end)

        self:AddHook("TTTPlayerRoleChangedByItem", function(ply, tgt, wep)
            -- Check it is the PaPed hypnotist device
            if WEPS.GetClass(wep) ~= self.class or not self:IsUpgraded(wep) then return end
            -- Vanilla innocents and detectives have their role changed, other roles do not
            if not tgt:IsInnocentTeam() then return end
            -- Find the selected role, or pick a random one if none is selected
            local role

            if wep.PAPSelectedRole then
                role = wep.PAPSelectedRole
            else
                local enabledRoles = GetEnabledRoles()
                -- If only the hypnotist is enabled out of all special innocent roles,
                -- and turning other players into hypnotists is disabled, then the enabled innocent roles table will be empty,
                -- so we return here to avoid errors
                if table.IsEmpty(enabledRoles) then return end
                role = enabledRoles[math.random(#enabledRoles)]
                ply:ChatPrint("No role selected! Reviving as a random innocent role.")
            end

            timer.Simple(0.1, function()
                tgt:SetRole(role)
                SendFullStateUpdate()
            end)
        end)
    end

    -- Modified from Custom Role's guessing device item, all credit for this UI goes to Noxx!
    if CLIENT then
        function SWEP:SecondaryAttack()
            if not IsFirstTimePredicted() then return end
            self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)
            local enabledRoles = GetEnabledRoles()
            local noOfEnabledRoles = #enabledRoles
            local columns = math.Clamp(noOfEnabledRoles, 4, 8)
            local innocentRows = math.ceil(noOfEnabledRoles / columns)
            local itemSize = 64
            local headingHeight = 22
            local searchHeight = 25
            local labelHeight = 16
            local m = 5
            -- list sizes
            local listWidth = (itemSize + 2) * columns
            local innocentsHeight = math.max((itemSize + 2) * innocentRows + 2, 0)
            -- I worked this out from looking at screenshots and measuring how the bottom margin changes based on the number of labels. I don't know why this is needed or where these numbers come from!
            local bottomMarginOffset = (2 * noOfEnabledRoles) - 7
            -- frame size
            local w = listWidth + (m * 2) + 2 -- For some reason the icons aren't centred horizontally so add 2px
            local labels = 1

            if noOfEnabledRoles == 0 then
                labels = 0
            end

            local h = innocentsHeight + (labelHeight * labels) + (m * 2) + headingHeight + searchHeight + bottomMarginOffset
            local dframe = vgui.Create("DFrame")
            dframe:SetSize(w, h)
            dframe:Center()
            dframe:SetTitle("Choose a role")
            dframe:SetVisible(true)
            dframe:ShowCloseButton(true)
            dframe:SetMouseInputEnabled(true)
            dframe:SetDeleteOnClose(true)
            local dsearch = vgui.Create("DTextEntry", dframe)
            dsearch:SetPos(m + 2, m + headingHeight + 2) -- For some reason this is 2px higher than it should be so shift it down, also undo the extra width added above
            dsearch:SetSize(listWidth - 2, searchHeight)
            dsearch:SetPlaceholderText("Search...")
            dsearch:SetUpdateOnType(true)

            dsearch.OnGetFocus = function()
                dframe:SetKeyboardInputEnabled(true)
            end

            dsearch.OnLoseFocus = function()
                dframe:SetKeyboardInputEnabled(false)
            end

            local panelList = {}

            if noOfEnabledRoles > 0 then
                local yOffset = m * 2 + headingHeight + searchHeight
                local dlabel = vgui.Create("DLabel", dframe)
                dlabel:SetFont("TabLarge")
                dlabel:SetText("Innocent Roles")
                dlabel:SetContentAlignment(7)
                dlabel:SetWidth(listWidth)
                dlabel:SetPos(m + 3, yOffset) -- For some reason the text isn't inline with the icons so we shift it 3px to the right
                local dlist = vgui.Create("EquipSelect", dframe)
                dlist:SetPos(m, yOffset + labelHeight)
                dlist:SetSize(listWidth, innocentsHeight)
                dlist:EnableHorizontal(true)

                for _, role in pairs(enabledRoles) do
                    local ic = vgui.Create("SimpleIcon", dlist)
                    local roleStringShort = ROLE_STRINGS_SHORT[role]
                    local material = util.GetRoleIconPath(roleStringShort, "icon", "vtf")
                    ic:SetIconSize(itemSize)
                    ic:SetIcon(material)
                    ic:SetBackgroundColor(ROLE_COLORS[role] or Color(0, 0, 0, 0))
                    ic:SetTooltip(ROLE_STRINGS[role])
                    ic.role = role
                    ic.enabled = true
                    table.insert(panelList, ic)
                    dlist:AddPanel(ic)
                end

                dlist.OnActivePanelChanged = function(_, _, new)
                    if new.enabled then
                        net.Start("TTTPAPRoleChoosingDefib")
                        net.WriteInt(new.role, 8)
                        net.SendToServer()
                        dframe:Close()
                    end
                end
            end

            dsearch.OnValueChange = function(_, value)
                local query = string.lower(value:gsub("[%p%c%s]", ""))

                for _, panel in pairs(panelList) do
                    if string.find(ROLE_STRINGS_RAW[panel.role], query, 1, true) or (value and #value == 0) then
                        panel:SetIconColor(COLOR_WHITE)
                        panel:SetBackgroundColor(ROLE_COLORS[panel.role])
                        panel.enabled = true
                    else
                        panel:SetIconColor(COLOR_LGRAY)
                        panel:SetBackgroundColor(ROLE_COLORS_DARK[panel.role])
                        panel.enabled = false
                    end
                end
            end

            dframe:MakePopup()
            dframe:SetKeyboardInputEnabled(false)
        end
    end
end

TTTPAP:Register(UPGRADE)