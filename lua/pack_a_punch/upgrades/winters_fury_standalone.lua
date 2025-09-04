local UPGRADE = {}
UPGRADE.id = "winters_fury_standalone"
UPGRADE.class = "freeze_swep"
UPGRADE.name = "Winter's Fury"
UPGRADE.desc = "Extra ammo + slows everyone else down\nand puts an icy overlay over their screen"
UPGRADE.ammoMult = 1.25

function UPGRADE:Apply(SWEP)
    local owner = SWEP:GetOwner()
    local screenColour = Color(0, 238, 255, 20)

    if SERVER then
        for _, ply in player.Iterator() do
            if self:IsAlive(ply) and ply ~= owner then
                ply:ScreenFade(SCREENFADE.OUT, screenColour, 1, 1)

                timer.Simple(1.5, function()
                    ply:ScreenFade(SCREENFADE.STAYOUT, screenColour, 1, 1)
                end)

                ply:SetLaggedMovementValue(0.75 * ply:GetLaggedMovementValue())
                ply:PrintMessage(HUD_PRINTCENTER, "Someone wields winter's fury...")
                ply:EmitSound("ttt_pack_a_punch/aoe_freeze_gun/freeze.mp3")
            end
        end
    end

    self:AddHook("PostPlayerDeath", function(ply)
        ply:ScreenFade(SCREENFADE.PURGE, screenColour, 1, 1)
        ply:SetLaggedMovementValue(1)
    end)
end

function UPGRADE:Reset()
    if SERVER then
        for _, ply in player.Iterator() do
            ply:ScreenFade(SCREENFADE.PURGE, screenColour, 1, 1)
            ply:SetLaggedMovementValue(1)
        end
    end
end

TTTPAP:Register(UPGRADE)