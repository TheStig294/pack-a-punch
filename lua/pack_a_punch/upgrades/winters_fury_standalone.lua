local UPGRADE = {}
UPGRADE.id = "winters_fury_standalone"
UPGRADE.class = "freeze_swep"
UPGRADE.name = "Winter's Fury"
UPGRADE.desc = "Extra ammo + slows everyone else down\nand puts a icy overlay over their screen"
UPGRADE.ammoMult = 1.25

function UPGRADE:Apply(SWEP)
    local owner = SWEP:GetOwner()

    if SERVER then
        for _, ply in ipairs(player.GetAll()) do
            if self:IsAlive(ply) and ply ~= owner then
                ply:ConCommand("pp_mat_overlay hud/freeze_screen")
                ply:SetLaggedMovementValue(0.75 * ply:GetLaggedMovementValue())
                ply:PrintMessage(HUD_PRINTCENTER, "Someone wields winter's fury...")
                ply:EmitSound("weapons/wintershowl/projectile/freeze/freeze_0" .. math.random(0, 2) .. ".ogg")
            end
        end
    end

    self:AddHook("PostPlayerDeath", function(ply)
        ply:ConCommand("pp_mat_overlay \"\"")
        ply:SetLaggedMovementValue(1)
    end)
end

function UPGRADE:Reset()
    if SERVER then
        for _, ply in ipairs(player.GetAll()) do
            ply:ConCommand("pp_mat_overlay \"\"")
            ply:SetLaggedMovementValue(1)
        end
    end
end

TTTPAP:Register(UPGRADE)