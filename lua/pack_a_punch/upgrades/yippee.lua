local UPGRADE = {}
UPGRADE.id = "yippee"
UPGRADE.class = "weapon_ttt_confetti"
UPGRADE.name = "Yippee!"
UPGRADE.desc = "You can play Fortnite... and drink cola!"

function UPGRADE:Apply(SWEP)
    self:SetClip(SWEP, 3)

    if SERVER then
        util.AddNetworkString("TTTPAPYippee")
    end

    self:AddToHook(SWEP, "PrimaryAttack", function()
        if CLIENT or not IsFirstTimePredicted() or SWEP.TTTPAPYippeeLastShot then return end

        if not SWEP:CanPrimaryAttack() then
            SWEP.TTTPAPYippeeLastShot = true

            -- Length of the animated image file
            timer.Simple(1.574, function()
                PrintMessage(HUD_PRINTTALK, "They've yipped their last ppee...")
                PrintMessage(HUD_PRINTCENTER, "They've yipped their last ppee...")
            end)
        end

        net.Start("TTTPAPYippee")
        net.Broadcast()
    end)

    if CLIENT then
        local mat = Material("ttt_pack_a_punch/yippee/yippee")
        local matSize = 512

        net.Receive("TTTPAPYippee", function()
            surface.PlaySound("ttt_pack_a_punch/yippee/yippee.mp3")
            local xPos = ScrW() / 2 - matSize / 2
            local yPos = ScrH() / 2 - matSize / 2

            self:AddHook("HUDPaintBackground", function()
                surface.SetAlphaMultiplier(0.1)
                surface.SetDrawColor(39, 39, 39, 39)
                surface.SetMaterial(mat)
                surface.DrawTexturedRect(xPos, yPos, matSize, matSize)
                surface.SetAlphaMultiplier(1)
            end)

            -- Length of the animated image file
            timer.Simple(1.574, function()
                self:RemoveHook("HUDPaintBackground")
            end)
        end)
    end
end

TTTPAP:Register(UPGRADE)