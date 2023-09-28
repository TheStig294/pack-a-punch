local UPGRADE = {}
UPGRADE.id = "noisy_doncombine"
UPGRADE.class = "weapon_doncombinesummoner"
UPGRADE.name = "Noisy Doncombine"
UPGRADE.desc = "x2 ammo, plays Duncan quotes"
UPGRADE.ammoMult = 2

function UPGRADE:Apply(SWEP)
    local PAPOldplace_doncom = place_doncom

    function place_doncom(tracedata, wep)
        PAPOldplace_doncom(tracedata, wep)
        local doncom = wep.doncom

        if IsValid(doncom) then
            doncom:SetMaterial(TTTPAP.camo)
            local timername = "TTTPAPNoisyDoncombine" .. doncom:EntIndex()

            timer.Create(timername, 10, 0, function()
                if not IsValid(doncom) then
                    timer.Remove(timername)

                    return
                end

                doncom:EmitSound("ttt_pack_a_punch/noisy_doncombine/quote" .. math.random(1, 10) .. ".mp3")
            end)
        end
    end
end

TTTPAP:Register(UPGRADE)