local UPGRADE = {}
UPGRADE.id = "robcombine"
UPGRADE.class = "weapon_doncombinesummoner"
UPGRADE.name = "Robcombine Summoner"
UPGRADE.desc = "x2 ammo, plays Robin quotes"
UPGRADE.ammoMult = 2

function UPGRADE:Apply(SWEP)
    -- Only apply the function override once
    if self.applied then return end
    self.applied = true
    -- Override global function in the doncombine summoner SWEP
    local PAPOldplace_doncom = place_doncom

    function place_doncom(tracedata, wep)
        PAPOldplace_doncom(tracedata, wep)
        if not wep.PAPUpgrade or wep.PAPUpgrade.id ~= self.id then return end
        local doncom = wep.doncom

        if IsValid(doncom) then
            timer.Simple(0.1, function()
                doncom:SetMaterial(TTTPAP.camo)
            end)

            local timername = "TTTPAPRobcombine" .. doncom:EntIndex()

            timer.Create(timername, 10, 0, function()
                if not IsValid(doncom) then
                    timer.Remove(timername)

                    return
                end

                local randomnum = math.random(1, 9)
                doncom:EmitSound("ttt_pack_a_punch/robcombine/quote" .. randomnum .. ".mp3")
                doncom:EmitSound("ttt_pack_a_punch/robcombine/quote" .. randomnum .. ".mp3")
                doncom:EmitSound("ttt_pack_a_punch/robcombine/quote" .. randomnum .. ".mp3")
            end)
        end
    end
end

TTTPAP:Register(UPGRADE)