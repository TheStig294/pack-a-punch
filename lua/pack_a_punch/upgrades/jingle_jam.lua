local UPGRADE = {}
UPGRADE.id = "jingle_jam"
UPGRADE.class = "ttt_pap_jam"
UPGRADE.name = "Jingle Jam"
UPGRADE.desc = "Jingles as you move around"

function UPGRADE:Apply(SWEP)
    self:AddHook("PlayerFootstep", function(ply, pos, foot, sound, volume, filter)
        local wep = ply:GetActiveWeapon()

        if IsValid(wep) and self:IsUpgraded(wep) then
            ply:EmitSound("ttt_pack_a_punch/jingle_jam/jingle" .. math.random(1, 8) .. ".mp3")

            return true
        end
    end)
end

TTTPAP:Register(UPGRADE)