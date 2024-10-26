local UPGRADE = {}
UPGRADE.id = "mlg_awp"
UPGRADE.class = "ttt_no_scope_awp"
UPGRADE.name = "MLG AWP"
UPGRADE.desc = "Displays MLG popups + ammo and clip size"

function UPGRADE:Apply(SWEP)
    if SERVER then
        util.AddNetworkString("TTTPAPMlgAwpDeathEffects")
    end

    self:SetClip(SWEP, 4)

    -- Players hear a random MLG-themed sound on killing someone
    self:AddHook("DoPlayerDeath", function(ply, attacker, dmg)
        if not self:IsPlayer(attacker) then return end
        local activeWeapon = attacker:GetActiveWeapon()

        if IsValid(activeWeapon) and activeWeapon:GetClass() == "ttt_no_scope_awp" then
            local mlgSound = "ttt_pack_a_punch/mlg_awp/mlg" .. math.random(10) .. ".mp3"

            if not attacker.PAPMlgAwpTriple then
                attacker.PAPMlgAwpTriple = 1
            elseif attacker.PAPMlgAwpTriple == 3 then
                -- Always play the "Oh baby a triple!" sound on a player's third kill
                mlgSound = "ttt_pack_a_punch/mlg_awp/triple.mp3"
            end

            attacker.PAPMlgAwpTriple = attacker.PAPMlgAwpTriple + 1
            attacker:EmitSound(mlgSound)
            ply:EmitSound(mlgSound)

            local plys = {ply, attacker}

            net.Start("TTTPAPMlgAwpDeathEffects")
            net.Send(plys)
        end
    end)

    if CLIENT then
        net.Receive("TTTPAPMlgAwpDeathEffects", function()
            local frame = vgui.Create("DFrame")
            local xSize = ScrW() / 2
            local ySize = ScrH() / 2
            local pos1 = ScrW() / 4
            local pos2 = ScrH() / 4
            frame:SetPos(pos1, pos2)
            frame:SetSize(xSize, ySize)
            -- Make derma frame holding the image popup invisible
            frame:ShowCloseButton(false)
            frame:SetTitle("")
            frame.Paint = function() end
            -- Display the image
            local image = vgui.Create("DImage", frame)
            image:SetImage("ttt_pack_a_punch/mlg_awp/mlg" .. math.random(6) .. ".jpg")
            image:SetPos(0, 0)
            image:SetSize(xSize, ySize)
            -- ...and shake it around the screen a bit
            local shakeSize = 20

            timer.Create("TTTPAPMlgAwpPopupShake", 0.1, 30, function()
                if not IsValid(frame) then
                    timer.Remove("TTTPAPMlgAwpPopupShake")

                    return
                end

                frame:SetPos(pos1 + math.random(-shakeSize, shakeSize), pos2 + math.random(-shakeSize, shakeSize))
            end)

            timer.Simple(3, function()
                timer.Remove("TTTPAPMlgAwpPopupShake")

                if IsValid(frame) then
                    frame:Close()
                end
            end)
        end)
    end
end

function UPGRADE:Reset()
    for _, ply in ipairs(player.GetAll()) do
        ply.PAPMlgAwpTriple = nil
    end
end

TTTPAP:Register(UPGRADE)