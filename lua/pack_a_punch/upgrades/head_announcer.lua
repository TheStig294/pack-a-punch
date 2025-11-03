local UPGRADE = {}
UPGRADE.id = "head_announcer"
UPGRADE.class = "weapon_ttt_head_message"
UPGRADE.name = "Head Announcer"

local cooldownCvar = CreateConVar("pap_head_announcer_cooldown", 10, {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds cooldown on displaying messages", 0, 120)

local displayLengthCvar = CreateConVar("pap_head_announcer_display_length", 3, {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds message is displayed", 1, 10)

UPGRADE.desc = "Displays messages you write\nto everyone's screen! (" .. cooldownCvar:GetInt() .. " second cooldown)"

UPGRADE.convars = {
    {
        name = "pap_head_announcer_cooldown",
        type = "int"
    },
    {
        name = "pap_head_announcer_display_length",
        type = "int"
    }
}

if CLIENT then
    surface.CreateFont("TTTPAPHeadAnnouncer", {
        font = "Trebuchet24",
        size = 48,
        weight = 1000
    })
end

function UPGRADE:Apply(SWEP)
    if CLIENT then
        local nextAllowedDisplayTime = CurTime()

        self:AddHook("HeadMessageUpdated", function(owner, message)
            if nextAllowedDisplayTime > CurTime() then return end
            nextAllowedDisplayTime = CurTime() + cooldownCvar:GetInt()
            local wep = owner:GetWeapon(self.class)
            if not self:IsValidUpgrade(wep) then return end
            local TextData = {}
            TextData.color = COLOR_WHITE
            TextData.font = "TTTPAPHeadAnnouncer"

            TextData.pos = {ScrW() / 2, ScrH() / 4}

            TextData.text = message
            TextData.xalign = TEXT_ALIGN_CENTER
            TextData.yalign = TEXT_ALIGN_CENTER
            local shadowDist = 2

            hook.Add("DrawOverlay", "TTTPAPHeadAnnouncerDrawText", function()
                draw.DrawText(TextData.text, TextData.font, TextData.pos[1] + shadowDist, TextData.pos[2] + shadowDist, COLOR_BLACK, TextData.xalign)
                draw.DrawText(TextData.text, TextData.font, TextData.pos[1], TextData.pos[2], TextData.color, TextData.xalign)
            end)

            timer.Create("TTTPAPHeadAnnouncerDrawText", displayLengthCvar:GetInt(), 1, function()
                hook.Remove("DrawOverlay", "TTTPAPHeadAnnouncerDrawText")
            end)
        end)
    end
end

TTTPAP:Register(UPGRADE)