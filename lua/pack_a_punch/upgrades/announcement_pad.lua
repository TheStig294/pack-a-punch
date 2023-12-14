local UPGRADE = {}
UPGRADE.id = "announcement_pad"
UPGRADE.class = "wt_writingpad"
UPGRADE.name = "Announcement Pad"

local cooldownCvar = CreateConVar("pap_announcement_pad_cooldown", 10, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds cooldown on displaying messages", 0, 120)

local displayLengthCvar = CreateConVar("pap_announcement_pad_display_length", 3, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds message is displayed", 1, 10)

UPGRADE.desc = "Displays messages you write in the pad\nto everyone's screen! (" .. cooldownCvar:GetInt() .. " second cooldown)"

UPGRADE.convars = {
    {
        name = "pap_announcement_pad_cooldown",
        type = "int"
    },
    {
        name = "pap_announcement_pad_display_length",
        type = "int"
    }
}

if CLIENT then
    surface.CreateFont("TTTPAPAnnouncementPad", {
        font = "Trebuchet24",
        size = 48,
        weight = 1000
    })
end

function UPGRADE:Apply(SWEP)
    if CLIENT then
        SWEP.PAPOldSetWritingPadValue = SWEP.SetWritingPadValue
        SWEP.PAPMessageCooldown = false
        local allowMessages = false

        timer.Simple(1, function()
            allowMessages = true
        end)

        -- Send message from client to server
        function SWEP:SetWritingPadValue(intFont, tblColor, strText)
            self:PAPOldSetWritingPadValue(intFont, tblColor, strText)
            if self.PAPMessageCooldown or not allowMessages then return end
            local owner = self:GetOwner()

            if IsValid(owner) then
                self.PAPMessageCooldown = true

                timer.Create("TTTPAPAnnoucementPadCooldown" .. owner:SteamID64(), cooldownCvar:GetInt(), 1, function()
                    if IsValid(self) then
                        self.PAPMessageCooldown = false
                    end
                end)
            end

            if self.Pad_Message then
                net.Start("TTTPAPAnnoucementPad")
                net.WriteString(self.Pad_Message)
                net.SendToServer()
            end
        end

        -- Recieve message from server
        net.Receive("TTTPAPAnnouncementPadDrawText", function()
            local message = net.ReadString()
            local TextData = {}
            TextData.color = COLOR_WHITE
            TextData.font = "TTTPAPAnnouncementPad"

            TextData.pos = {ScrW() / 2, ScrH() / 4}

            TextData.text = message
            TextData.xalign = TEXT_ALIGN_CENTER
            TextData.yalign = TEXT_ALIGN_CENTER
            local shadowDist = 2

            hook.Add("DrawOverlay", "TTTPAPAnnouncementPadDrawText", function()
                draw.DrawText(TextData.text, TextData.font, TextData.pos[1] + shadowDist, TextData.pos[2] + shadowDist, COLOR_BLACK, TextData.xalign)
                draw.DrawText(TextData.text, TextData.font, TextData.pos[1], TextData.pos[2], TextData.color, TextData.xalign)
            end)

            timer.Create("TTTPAPAnnouncementPadDrawText", displayLengthCvar:GetInt(), 1, function()
                hook.Remove("DrawOverlay", "TTTPAPAnnouncementPadDrawText")
            end)
        end)
    end

    -- Send message from the 1 client with the pad to all clients
    if SERVER then
        util.AddNetworkString("TTTPAPAnnoucementPad")
        util.AddNetworkString("TTTPAPAnnouncementPadDrawText")

        net.Receive("TTTPAPAnnoucementPad", function()
            local message = net.ReadString()
            net.Start("TTTPAPAnnouncementPadDrawText")
            net.WriteString(message)
            net.Broadcast()
        end)
    end
end

TTTPAP:Register(UPGRADE)